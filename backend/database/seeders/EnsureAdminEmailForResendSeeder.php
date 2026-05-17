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

        // Resend free tier sin dominio verificado solo entrega al email del owner.
        // UNIQUE(email) eliminado para permitir que admin y doctores compartan email.
        $admin = User::where('tipo', 'admin')->first();
        if ($admin && $admin->email !== $target) {
            $admin->update(['email' => $target]);
            Log::info("EnsureAdminEmailForResendSeeder: admin {$admin->id} actualizado a {$target}");
        } else {
            Log::info("EnsureAdminEmailForResendSeeder: admin ya tiene {$target}");
        }

        // Doctores también reciben el email verificado para que 2FA funcione
        $doctores = User::where('tipo', 'doctor')->get();
        foreach ($doctores as $doc) {
            if ($doc->email !== $target) {
                $doc->update(['email' => $target]);
                Log::info("EnsureAdminEmailForResendSeeder: doctor {$doc->id} actualizado a {$target}");
            }
        }
    }
}
