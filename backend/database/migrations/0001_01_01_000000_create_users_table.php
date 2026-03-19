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
            $table->string('numero_control')->nullable()->unique(); // Para alumnos
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
            $table->string('nip', 6)->nullable(); // NIP de 6 dígitos para alumnos
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
