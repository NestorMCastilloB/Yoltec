<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\User>
 */
class UserFactory extends Factory
{
    /**
     * La contraseña se hashea una sola vez para todas las instancias.
     */
    protected static ?string $password = null;

    /**
     * Alumno por defecto: entra con número de control y NIP de 6 dígitos.
     */
    public function definition(): array
    {
        return [
            'nombre'         => fake()->firstName(),
            'apellido'       => fake()->lastName(),
            'email'          => fake()->unique()->safeEmail(),
            'password'       => static::$password ??= Hash::make('password'),
            'tipo'           => 'alumno',
            'numero_control' => fake()->unique()->numerify('22######'),
            'nip'            => Hash::make('123456'),
        ];
    }

    /** Doctor: entra con usuario y contraseña, sin número de control ni NIP. */
    public function doctor(): static
    {
        return $this->state(fn (array $attributes) => [
            'tipo'           => 'doctor',
            'username'       => fake()->unique()->userName(),
            'numero_control' => null,
            'nip'            => null,
        ]);
    }

    /** Administrador: el rol lo determina únicamente `tipo` (M-3 resuelto). */
    public function admin(): static
    {
        return $this->state(fn (array $attributes) => [
            'tipo'           => 'admin',
            'username'       => fake()->unique()->userName(),
            'numero_control' => null,
            'nip'            => null,
        ]);
    }
}
