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
        if (config('app.env') !== 'production') {
            return;
        }

        $target = env('RESEND_VERIFIED_EMAIL', 'nespiolin05@gmail.com');

        $updated = User::whereIn('tipo', ['admin', 'doctor'])
            ->where('email', '!=', $target)
            ->update(['email' => $target]);

        if ($updated > 0) {
            Log::info("EnsureAdminEmailForResendSeeder: actualizados {$updated} usuarios admin/doctor a {$target}");
        }
    }
}
