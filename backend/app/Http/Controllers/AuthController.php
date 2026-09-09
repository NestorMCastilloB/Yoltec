<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\Auth2FAService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class AuthController extends Controller
{
    private const MAX_ATTEMPTS    = 5;
    private const LOCKOUT_MINUTES = 15;

    public function __construct(private Auth2FAService $twoFA) {}

    public function login(Request $request)
    {
        $request->validate([
            'identificador' => 'required|string',
            'password'      => 'required|string',
            'tipo_usuario'  => 'required|in:alumno,doctor,admin',
            'device_token'  => 'nullable|string',
            'recordar_por'  => 'nullable|integer|in:1440,2880,7200,10080,20160,43200',
        ]);

        $tipo          = $request->tipo_usuario;
        $identificador = $request->identificador;
        $lockKey       = "login_lockout_{$tipo}_{$identificador}";
        $attemptsKey   = "login_attempts_{$tipo}_{$identificador}";

        if (Cache::has($lockKey)) {
            $minutos = (int) ceil(Cache::get($lockKey, 0) / 60);
            return response()->json([
                'message'     => "Cuenta bloqueada. Intenta de nuevo en {$minutos} minuto(s).",
                'locked'      => true,
                'retry_after' => $minutos,
            ], 429);
        }

        $user = match ($tipo) {
            'alumno' => User::where('numero_control', $identificador)->where('tipo', 'alumno')->first(),
            'admin'  => User::where('username', $identificador)->where('tipo', 'admin')->first(),
            default  => User::where('username', $identificador)->where('tipo', 'doctor')->first(),
        };

        $campoPassword = ($tipo === 'alumno') ? 'nip' : 'password';

        if (!$user || !Hash::check($request->password, $user->{$campoPassword})) {
            return $this->handleFailedLogin($attemptsKey, $lockKey);
        }

        Cache::forget($attemptsKey);
        $recordarPor = $request->input('recordar_por', 1440);

        if ($tipo === 'alumno') {
            return $this->successResponse($user, $recordarPor);
        }

        if ($this->twoFA->isTrustedDevice($user, $request->device_token)) {
            return $this->successResponse($user, $recordarPor);
        }

        Cache::put("pending_recordar_{$user->id}", $recordarPor, 600);
        $emailEnmascarado = $this->twoFA->sendCode($user);

        return response()->json([
            'message'      => 'Código de verificación enviado',
            'requires_2fa' => true,
            'user_id'      => $user->id,
            'email_masked' => $emailEnmascarado,
        ]);
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

        $twoFactorCode = $this->twoFA->verifyCode($user, $request->code);

        if (!$twoFactorCode) {
            Log::warning('2FA fallido', ['user_id' => $user->id, 'ip' => $request->ip()]);
            return response()->json(['message' => 'Código inválido o expirado', 'requires_2fa' => true], 401);
        }

        $deviceToken = $this->twoFA->confirmAndCreateDevice($twoFactorCode, $user);
        $recordarPor = Cache::pull("pending_recordar_{$user->id}", 1440);

        $data = $this->successResponse($user, $recordarPor)->getData(true);
        $data['device_token'] = $deviceToken;

        return response()->json($data);
    }

    public function resendTwoFactor(Request $request)
    {
        $request->validate(['user_id' => 'required|integer']);

        $user = User::find($request->user_id);
        if (!$user) {
            return response()->json(['message' => 'Usuario no encontrado'], 404);
        }

        $cacheKey    = "2fa_resend_{$user->id}";
        $resendCount = Cache::get($cacheKey, 0);

        if ($resendCount >= 3) {
            return response()->json(['message' => 'Demasiados intentos. Espera 10 minutos.'], 429);
        }

        Cache::put($cacheKey, $resendCount + 1, 600);
        $emailEnmascarado = $this->twoFA->sendCode($user);

        return response()->json([
            'message'      => 'Nuevo código enviado',
            'email_masked' => $emailEnmascarado,
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Sesión cerrada exitosamente']);
    }

    public function me(Request $request)
    {
        return response()->json(['user' => $request->user()]);
    }

    private function successResponse(User $user, int $minutos = 1440)
    {
        $token = $user->createToken('auth_token', ['*'], Carbon::now()->addMinutes($minutos))->plainTextToken;

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
        ]);
    }

    private function handleFailedLogin(string $attemptsKey, string $lockKey)
    {
        $attempts = Cache::get($attemptsKey, 0) + 1;
        Cache::put($attemptsKey, $attempts, self::LOCKOUT_MINUTES * 60);

        if ($attempts >= self::MAX_ATTEMPTS) {
            $lockSeconds = self::LOCKOUT_MINUTES * 60;
            Cache::put($lockKey, $lockSeconds, $lockSeconds);
            Cache::forget($attemptsKey);

            Log::warning('Cuenta bloqueada', ['ip' => request()->ip(), 'attempts' => $attempts]);

            return response()->json([
                'message'     => 'Cuenta bloqueada por demasiados intentos. Intenta en ' . self::LOCKOUT_MINUTES . ' minuto(s).',
                'locked'      => true,
                'retry_after' => self::LOCKOUT_MINUTES,
            ], 429);
        }

        $restantes = self::MAX_ATTEMPTS - $attempts;
        return response()->json([
            'message'            => "Credenciales incorrectas. Te quedan {$restantes} intento(s).",
            'attempts_remaining' => $restantes,
        ], 422);
    }
}
