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

        // Resend (free tier) rechaza aliases +tag@gmail.com, solo acepta el email exacto.
        // Solo admin recibe el email verificado; doctores quedan con alias (no podrán hacer 2FA
        // en prod hasta verificar dominio en Resend, pero no es bloqueante para la demo).
        [$local, $domain] = explode('@', $target, 2);

        // 1) Liberar el target si lo tiene otro user (alias previo del propio admin o ex-admin).
        User::where('email', $target)
            ->update(['email' => "{$local}+freed-" . now()->timestamp . "@{$domain}"]);

        // 2) Asignar el target al admin.
        $admin = User::where('tipo', 'admin')->first();
        if ($admin && $admin->email !== $target) {
            $admin->update(['email' => $target]);
            Log::info("EnsureAdminEmailForResendSeeder: admin {$admin->id} actualizado a {$target}");
        } else {
            Log::info("EnsureAdminEmailForResendSeeder: admin ya tiene {$target}");
        }

        // 3) Doctores: asignar aliases únicos solo si todavía no los tienen.
        $doctores = User::where('tipo', 'doctor')->get();
        foreach ($doctores as $doc) {
            $slug = $doc->username ?: ('doctor' . $doc->id);
            $aliasEmail = "{$local}+{$slug}@{$domain}";
            if ($doc->email !== $aliasEmail) {
                $doc->update(['email' => $aliasEmail]);
            }
        }
    }
}
