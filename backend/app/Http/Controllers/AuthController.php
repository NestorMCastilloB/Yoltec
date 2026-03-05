<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\TwoFactorCode;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Cache;
use Illuminate\Validation\ValidationException;
use Carbon\Carbon;

class AuthController extends Controller
{
    // Duración del código 2FA en minutos
    const CODE_DURATION = 10;

    /**
     * Paso 1: Login inicial - Verifica credenciales y envía código 2FA
     */
    public function login(Request $request)
    {
        $request->validate([
            'identificador' => 'required|string',
            'password' => 'required|string',
        ]);

        // Buscar usuario
        $user = User::where('numero_control', $request->identificador)
                    ->orWhere('username', $request->identificador)
                    ->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'identificador' => ['Las credenciales son incorrectas.'],
            ]);
        }

        // Generar código 2FA de 6 dígitos
        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        // Guardar código en base de datos
        TwoFactorCode::create([
            'user_id' => $user->id,
            'code' => $code,
            'expires_at' => Carbon::now()->addMinutes(self::CODE_DURATION),
            'used' => false,
        ]);

        // En producción: Enviar email con el código
        // Mail::to($user->email)->send(new TwoFactorCodeMail($code, $user));
        
        // Para desarrollo/demo: Devolver código en respuesta (NO hacer esto en producción)
        return response()->json([
            'message' => 'Código de verificación enviado',
            'requires_2fa' => true,
            'user_id' => $user->id,
            'email_masked' => $this->maskEmail($user->email),
            // Solo para desarrollo:
            'dev_code' => $code,
        ], 200);
    }

    /**
     * Paso 2: Verificar código 2FA y completar login
     */
    public function verifyTwoFactor(Request $request)
    {
        $request->validate([
            'user_id' => 'required|integer',
            'code' => 'required|string|size:6',
        ]);

        $user = User::find($request->user_id);
        if (!$user) {
            return response()->json(['message' => 'Usuario no encontrado'], 404);
        }

        // Buscar código válido
        $twoFactorCode = TwoFactorCode::where('user_id', $user->id)
            ->where('code', $request->code)
            ->where('used', false)
            ->where('expires_at', '>', Carbon::now())
            ->first();

        if (!$twoFactorCode) {
            // Registrar intento fallido (para auditoría)
            $this->logFailed2FA($user, $request->code);
            
            return response()->json([
                'message' => 'Código inválido o expirado',
                'requires_2fa' => true,
            ], 401);
        }

        // Marcar código como usado
        $twoFactorCode->update(['used' => true]);

        // Crear token de autenticación
        $token = $user->createToken('auth_token')->plainTextToken;

        // Limpiar códigos antiguos del usuario
        TwoFactorCode::where('user_id', $user->id)
            ->where('created_at', '<', Carbon::now()->subHour())
            ->delete();

        return response()->json([
            'message' => 'Inicio de sesión exitoso',
            'user' => [
                'id' => $user->id,
                'nombre' => $user->nombre,
                'apellido' => $user->apellido,
                'email' => $user->email,
                'tipo' => $user->tipo,
                'numero_control' => $user->numero_control,
                'username' => $user->username,
            ],
            'token' => $token,
            'tipo' => $user->tipo,
        ], 200);
    }

    /**
     * Reenviar código 2FA
     */
    public function resendTwoFactor(Request $request)
    {
        $request->validate(['user_id' => 'required|integer']);

        $user = User::find($request->user_id);
        if (!$user) {
            return response()->json(['message' => 'Usuario no encontrado'], 404);
        }

        // Verificar rate limiting (máximo 3 reenvíos por 10 minutos)
        $cacheKey = "2fa_resend_{$user->id}";
        $resendCount = Cache::get($cacheKey, 0);
        
        if ($resendCount >= 3) {
            return response()->json([
                'message' => 'Demasiados intentos. Espera 10 minutos.',
            ], 429);
        }

        // Generar nuevo código
        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        TwoFactorCode::create([
            'user_id' => $user->id,
            'code' => $code,
            'expires_at' => Carbon::now()->addMinutes(self::CODE_DURATION),
            'used' => false,
        ]);

        Cache::put($cacheKey, $resendCount + 1, 600); // 10 minutos

        return response()->json([
            'message' => 'Nuevo código enviado',
            'email_masked' => $this->maskEmail($user->email),
            'dev_code' => $code, // Solo desarrollo
        ], 200);
    }

    /**
     * Enmascarar email para mostrar
     */
    private function maskEmail(string $email): string
    {
        $parts = explode('@', $email);
        $name = $parts[0];
        $domain = $parts[1] ?? '';
        
        $maskedName = substr($name, 0, 2) . str_repeat('*', max(0, strlen($name) - 2));
        $domainParts = explode('.', $domain);
        $maskedDomain = substr($domainParts[0], 0, 1) . str_repeat('*', max(0, strlen($domainParts[0]) - 1));
        
        return $maskedName . '@' . $maskedDomain . '.' . ($domainParts[1] ?? 'com');
    }

    /**
     * Registrar intento fallido de 2FA
     */
    private function logFailed2FA(User $user, string $code): void
    {
        // Aquí se integrará con el sistema de auditoría
        \Log::warning('2FA fallido', [
            'user_id' => $user->id,
            'email' => $user->email,
            'code_attempted' => $code,
            'ip' => request()->ip(),
            'timestamp' => now(),
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Sesión cerrada exitosamente'
        ], 200);
    }

    public function me(Request $request)
    {
        return response()->json([
            'user' => $request->user()
        ], 200);
    }
}
