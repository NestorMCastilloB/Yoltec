<?php

namespace App\Services;

use App\Mail\TwoFactorCodeMail;
use App\Models\TrustedDevice;
use App\Models\TwoFactorCode;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class Auth2FAService
{
    private const CODE_MINUTES   = 10;
    private const TRUST_DAYS     = 30;

    // Genera código 2FA, lo guarda y envía por email. Retorna email enmascarado.
    public function sendCode(User $user): string
    {
        $code = $this->crearCodigo($user);

        try {
            Mail::to($user->email)->send(new TwoFactorCodeMail($code, $user->nombre));
        } catch (\Exception $e) {
            \Log::error('SMTP ERROR 2FA: ' . $e->getMessage());
        }

        return $this->maskEmail($user->email);
    }

    // Indica si la cuenta es de demostración · el plan gratuito de Resend no
    // entrega a un visitante, así que estas cuentas reciben el código en la
    // respuesta · retorna true solo con DEMO_MODE activo y el username listado.
    public function esCuentaDemo(User $user): bool
    {
        return config('yoltec.demo_mode')
            && $user->username !== null
            && in_array($user->username, config('yoltec.demo_usuarios'), true);
    }

    // Genera el código de 2FA sin enviarlo por correo · solo para cuentas de
    // demostración, donde viaja en la respuesta porque no hay buzón que consultar
    // · retorna el código en claro, así que quien lo llama lo está exponiendo.
    public function generarCodigoDemo(User $user): string
    {
        return $this->crearCodigo($user);
    }

    // Genera el código y lo guarda cifrado con su caducidad · centraliza lo que
    // comparten el envío por correo y el de demostración · retorna el código en
    // claro para que quien lo pidió decida cómo entregarlo.
    private function crearCodigo(User $user): string
    {
        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        TwoFactorCode::create([
            'user_id'    => $user->id,
            'code'       => Hash::make($code),
            'expires_at' => Carbon::now()->addMinutes(self::CODE_MINUTES),
            'used'       => false,
        ]);

        return $code;
    }

    // Busca código válido y no usado. Retorna el registro si coincide, null si no.
    public function verifyCode(User $user, string $code): ?TwoFactorCode
    {
        $pending = TwoFactorCode::where('user_id', $user->id)
            ->where('used', false)
            ->where('expires_at', '>', Carbon::now())
            ->get();

        foreach ($pending as $record) {
            if (Hash::check($code, $record->code)) {
                return $record;
            }
        }

        return null;
    }

    // Marca código usado, limpia viejos y registra dispositivo de confianza. Retorna device_token.
    public function confirmAndCreateDevice(TwoFactorCode $twoFactorCode, User $user): string
    {
        $twoFactorCode->update(['used' => true]);

        TwoFactorCode::where('user_id', $user->id)
            ->where('created_at', '<', Carbon::now()->subHour())
            ->delete();

        $deviceToken = Str::random(64);
        TrustedDevice::create([
            'user_id'      => $user->id,
            'device_token' => $deviceToken,
            'expires_at'   => Carbon::now()->addDays(self::TRUST_DAYS),
        ]);

        TrustedDevice::where('user_id', $user->id)
            ->where('expires_at', '<', Carbon::now())
            ->delete();

        return $deviceToken;
    }

    // Verifica si el device_token es de confianza y lo renueva.
    public function isTrustedDevice(User $user, ?string $deviceToken): bool
    {
        if (!$deviceToken) {
            return false;
        }

        $trusted = TrustedDevice::where('user_id', $user->id)
            ->where('device_token', $deviceToken)
            ->where('expires_at', '>', Carbon::now())
            ->first();

        if ($trusted) {
            $trusted->update(['expires_at' => Carbon::now()->addDays(self::TRUST_DAYS)]);
            return true;
        }

        return false;
    }

    public function maskEmail(string $email): string
    {
        [$name, $domain] = array_pad(explode('@', $email, 2), 2, '');
        $maskedName   = substr($name, 0, 2) . str_repeat('*', max(0, strlen($name) - 2));
        $domainParts  = explode('.', $domain);
        $maskedDomain = substr($domainParts[0], 0, 1) . str_repeat('*', max(0, strlen($domainParts[0]) - 1));

        return $maskedName . '@' . $maskedDomain . '.' . ($domainParts[1] ?? 'com');
    }
}
