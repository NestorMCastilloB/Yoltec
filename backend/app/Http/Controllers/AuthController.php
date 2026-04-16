<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\TwoFactorCode;
use App\Models\TrustedDevice;
use App\Mail\TwoFactorCodeMail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Cache;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Str;
use Carbon\Carbon;

class AuthController extends Controller
{
    const CODE_DURATION = 10;
    const DEVICE_TRUST_DAYS = 30;

    public function login(Request $request)
    {
        $request->validate([
            'identificador' => 'required|string',
            'password'      => 'required|string',
            'tipo_usuario'  => 'required|in:alumno,doctor,admin',
            'device_token'  => 'nullable|string',
        ]);

        $tipoUsuario  = $request->tipo_usuario;
        $identificador = $request->identificador;
        $password      = $request->password;

        // Buscar usuario según tipo
        if ($tipoUsuario === 'alumno') {
            $user = User::where('numero_control', $identificador)->where('tipo', 'alumno')->first();
            if (!$user || $user->nip !== $password) {
                throw ValidationException::withMessages(['identificador' => ['Las credenciales son incorrectas.']]);
            }
        } elseif ($tipoUsuario === 'admin') {
            $user = User::where('username', $identificador)->where('tipo', 'admin')->first();
            if (!$user || !Hash::check($password, $user->password)) {
                throw ValidationException::withMessages(['identificador' => ['Las credenciales son incorrectas.']]);
            }
        } else {
            $user = User::where('username', $identificador)->where('tipo', 'doctor')->first();
            if (!$user || !Hash::check($password, $user->password)) {
                throw ValidationException::withMessages(['identificador' => ['Las credenciales son incorrectas.']]);
            }
        }

        // Alumnos y admins: nunca requieren 2FA
        if ($tipoUsuario === 'alumno' || $tipoUsuario === 'admin' || config('app.env') === 'local') {
            return $this->successResponse($user);
        }

        // Doctores en producción: verificar dispositivo de confianza
        $deviceToken = $request->device_token;
        if ($deviceToken) {
            $trusted = TrustedDevice::where('user_id', $user->id)
                ->where('device_token', $deviceToken)
                ->where('expires_at', '>', Carbon::now())
                ->first();

            if ($trusted) {
                // Renovar expiración y devolver token directamente
                $trusted->update(['expires_at' => Carbon::now()->addDays(self::DEVICE_TRUST_DAYS)]);
                return $this->successResponse($user);
            }
        }

        // Sin dispositivo de confianza: enviar código 2FA
        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        TwoFactorCode::create([
            'user_id'    => $user->id,
            'code'       => $code,
            'expires_at' => Carbon::now()->addMinutes(self::CODE_DURATION),
            'used'       => false,
        ]);

        try {
            Mail::to($user->email)->send(new TwoFactorCodeMail($code, $user->nombre));
            \Log::info('Email 2FA enviado a: ' . $user->email);
        } catch (\Exception $e) {
            \Log::error('SMTP ERROR 2FA: ' . $e->getMessage());
            error_log('SMTP ERROR 2FA: ' . $e->getMessage());
        }

        return response()->json([
            'message'      => 'Código de verificación enviado',
            'requires_2fa' => true,
            'user_id'      => $user->id,
            'email_masked' => $this->maskEmail($user->email),
        ], 200);
    }

    public function verifyTwoFactor(Request $request)
    {
        $request->validate([
            'user_id' => 'required|integer',
            'code'    => 'required|string|size:6',
        ]);

        $user = User::find($request->user_id);
        if (!$user) {
            return response()->json(['message' => 'Usuario no encontrado'], 404);
        }

        $twoFactorCode = TwoFactorCode::where('user_id', $user->id)
            ->where('code', $request->code)
            ->where('used', false)
            ->where('expires_at', '>', Carbon::now())
            ->first();

        if (!$twoFactorCode) {
            $this->logFailed2FA($user, $request->code);
            return response()->json(['message' => 'Código inválido o expirado', 'requires_2fa' => true], 401);
        }

        $twoFactorCode->update(['used' => true]);

        // Limpiar códigos viejos
        TwoFactorCode::where('user_id', $user->id)
            ->where('created_at', '<', Carbon::now()->subHour())
            ->delete();

        // Generar device_token de confianza (30 días)
        $deviceToken = Str::random(64);
        TrustedDevice::create([
            'user_id'      => $user->id,
            'device_token' => $deviceToken,
            'expires_at'   => Carbon::now()->addDays(self::DEVICE_TRUST_DAYS),
        ]);

        // Limpiar dispositivos viejos del usuario
        TrustedDevice::where('user_id', $user->id)
            ->where('expires_at', '<', Carbon::now())
            ->delete();

        $response = $this->successResponse($user);
        $data = $response->getData(true);
        $data['device_token'] = $deviceToken;

        return response()->json($data, 200);
    }

    public function resendTwoFactor(Request $request)
    {
        $request->validate(['user_id' => 'required|integer']);

        $user = User::find($request->user_id);
        if (!$user) {
            return response()->json(['message' => 'Usuario no encontrado'], 404);
        }

        $cacheKey = "2fa_resend_{$user->id}";
        $resendCount = Cache::get($cacheKey, 0);

        if ($resendCount >= 3) {
            return response()->json(['message' => 'Demasiados intentos. Espera 10 minutos.'], 429);
        }

        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        TwoFactorCode::create([
            'user_id'    => $user->id,
            'code'       => $code,
            'expires_at' => Carbon::now()->addMinutes(self::CODE_DURATION),
            'used'       => false,
        ]);

        Cache::put($cacheKey, $resendCount + 1, 600);

        try {
            Mail::to($user->email)->send(new TwoFactorCodeMail($code, $user->nombre));
        } catch (\Exception $e) {
            \Log::error('Error reenviando email 2FA: ' . $e->getMessage());
        }

        return response()->json([
            'message'      => 'Nuevo código enviado',
            'email_masked' => $this->maskEmail($user->email),
        ], 200);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Sesión cerrada exitosamente'], 200);
    }

    public function me(Request $request)
    {
        return response()->json(['user' => $request->user()], 200);
    }

    private function successResponse(User $user)
    {
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Inicio de sesión exitoso',
            'user'    => [
                'id'             => $user->id,
                'nombre'         => $user->nombre,
                'apellido'       => $user->apellido,
                'email'          => $user->email,
                'tipo'           => $user->tipo,
                'numero_control' => $user->numero_control,
                'username'       => $user->username,
            ],
            'token' => $token,
            'tipo'  => $user->tipo,
        ], 200);
    }

    private function maskEmail(string $email): string
    {
        $parts = explode('@', $email);
        $name  = $parts[0];
        $domain = $parts[1] ?? '';

        $maskedName = substr($name, 0, 2) . str_repeat('*', max(0, strlen($name) - 2));
        $domainParts = explode('.', $domain);
        $maskedDomain = substr($domainParts[0], 0, 1) . str_repeat('*', max(0, strlen($domainParts[0]) - 1));

        return $maskedName . '@' . $maskedDomain . '.' . ($domainParts[1] ?? 'com');
    }

    private function logFailed2FA(User $user, string $code): void
    {
        \Log::warning('2FA fallido', [
            'user_id'       => $user->id,
            'email'         => $user->email,
            'code_attempted' => $code,
            'ip'            => request()->ip(),
            'timestamp'     => now(),
        ]);
    }
}
