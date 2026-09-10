<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use RuntimeException;

class LocalDevelopmentSeeder extends Seeder
{
    // Crea tres cuentas ficticias solo en local; conserva las cuentas existentes.
    public function run(): void
    {
        if (! app()->environment('local')) {
            throw new RuntimeException('Las cuentas de desarrollo solo se pueden crear en APP_ENV=local.');
        }

        DB::transaction(function () {
            foreach (['admin', 'doctor', 'alumno'] as $tipo) {
                User::firstOrCreate(['email' => "$tipo@yoltec.test"], [
                    'nombre' => ucfirst($tipo),
                    'apellido' => 'Prueba Local',
                    'username' => $tipo === 'alumno' ? null : "$tipo-local",
                    'numero_control' => $tipo === 'alumno' ? '99000001' : null,
                    'password' => Hash::make('SoloLocal123!'),
                    'nip' => $tipo === 'alumno' ? Hash::make('123456') : null,
                    'tipo' => $tipo,
                ]);
            }
        });

        $this->command?->info('Cuentas locales listas. Consulta docs/desarrollo-local.md para entrar.');
    }
}
