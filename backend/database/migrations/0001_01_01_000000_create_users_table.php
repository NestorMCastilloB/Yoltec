<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('numero_control')->nullable(); // Para alumnos (no forzamos unique en DB por ahora)
            $table->string('username')->nullable(); // Para doctores (unique se controla a nivel de aplicación)
            $table->string('nombre');
            $table->string('apellido');
            // Quitamos unique a nivel de BD para evitar errores en Neon; se puede validar en la app
            $table->string('email');
            $table->string('password');
            // Usamos string en lugar de enum para evitar problemas con tipos en PostgreSQL/Neon
            $table->string('tipo')->default('alumno');
            $table->string('telefono')->nullable();
            $table->date('fecha_nacimiento')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
