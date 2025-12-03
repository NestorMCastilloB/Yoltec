<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Crear doctores (idempotente: si ya existen, no los duplica)
        User::firstOrCreate(
            ['username' => 'doctorOmar'],
            [
                'nombre' => 'Omar',
                'apellido' => 'González',
                'email' => 'omar.gonzalez@yoltec.com',
                'password' => Hash::make('doctor123'),
                'tipo' => 'doctor',
                'telefono' => '4441234567',
            ]
        );

        User::firstOrCreate(
            ['username' => 'doctorCarlos'],
            [
                'nombre' => 'Carlos',
                'apellido' => 'Ramírez',
                'email' => 'carlos.ramirez@yoltec.com',
                'password' => Hash::make('doctor123'),
                'tipo' => 'doctor',
                'telefono' => '4449876543',
            ]
        );

        // Crear alumnos de ejemplo (idempotente)
        User::firstOrCreate(
            ['numero_control' => '22690495'],
            [
                'nombre' => 'Nestor Moises',
                'apellido' => 'Castillo Bautista',
                'email' => 'nestor.castillo@alumno.com',
                'password' => Hash::make('22690495_740270'),
                'tipo' => 'alumno',
                'telefono' => '4441111111',
                'fecha_nacimiento' => '2004-03-02',
            ]
        );

        User::firstOrCreate(
            ['numero_control' => '22690496'],
            [
                'nombre' => 'Ana',
                'apellido' => 'López',
                'email' => 'ana.lopez@alumno.com',
                'password' => Hash::make('22690496_123456'),
                'tipo' => 'alumno',
                'telefono' => '4442222222',
                'fecha_nacimiento' => '2004-08-20',
            ]
        );

        User::firstOrCreate(
            ['numero_control' => '22690497'],
            [
                'nombre' => 'Pedro',
                'apellido' => 'Martínez',
                'email' => 'pedro.martinez@alumno.com',
                'password' => Hash::make('22690497_789012'),
                'tipo' => 'alumno',
                'telefono' => '4443333333',
                'fecha_nacimiento' => '2004-03-10',
            ]
        );
    }
}
