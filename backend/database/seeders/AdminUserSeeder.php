<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        User::updateOrCreate(
            ['username' => 'admin'],
            [
                'nombre'   => 'Administrador',
                'apellido' => 'Sistema',
                'email'    => 'admin@consultorio.com',
                'password' => Hash::make('admin123'),
                'tipo'     => 'admin',
                'es_admin' => true,
            ]
        );
    }
}
