<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Log;

// Resend (free tier) solo permite enviar al email del owner. En producción
// forzamos que admin y doctores tengan ese email para que el 2FA funcione.
// Idempotente: solo actualiza si el email es distinto.
class EnsureAdminEmailForResendSeeder extends Seeder
{
    public function run(): void
    {
        $mailer = config('mail.default');
        $target = env('RESEND_VERIFIED_EMAIL', 'nespiolin05@gmail.com');

        Log::info("EnsureAdminEmailForResendSeeder: mailer={$mailer}, target={$target}");

        if ($mailer !== 'resend') {
            Log::info('EnsureAdminEmailForResendSeeder: skip (mailer no es resend)');
            return;
        }

        // Gmail acepta +alias: nespiolin05+admin@gmail.com llega al mismo inbox.
        // Esto evita violar el UNIQUE de users.email cuando hay >1 usuario admin/doctor.
        [$local, $domain] = explode('@', $target, 2);

        $usuarios = User::whereIn('tipo', ['admin', 'doctor'])->get();
        $updated = 0;
        foreach ($usuarios as $u) {
            $slug = $u->username ?: ($u->tipo . $u->id);
            $nuevoEmail = "{$local}+{$slug}@{$domain}";
            if ($u->email !== $nuevoEmail) {
                $u->update(['email' => $nuevoEmail]);
                $updated++;
            }
        }

        Log::info("EnsureAdminEmailForResendSeeder: actualizados {$updated} usuarios admin/doctor (alias de {$target})");
    }
}
