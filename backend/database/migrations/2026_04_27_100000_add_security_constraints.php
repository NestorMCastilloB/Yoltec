<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Limpiar emails duplicados antes de agregar UNIQUE (dejar el mas reciente)
        DB::statement("
            DELETE FROM users a USING users b
            WHERE a.id < b.id
            AND a.email = b.email
            AND a.email IS NOT NULL
            AND a.email != ''
        ");

        // UNIQUE en email (users)
        Schema::table('users', function (Blueprint $table) {
            $table->unique('email');
        });

        // Limpiar claves duplicadas antes de agregar UNIQUE
        DB::statement("
            DELETE FROM citas a USING citas b
            WHERE a.id < b.id
            AND a.clave_cita = b.clave_cita
        ");

        Schema::table('citas', function (Blueprint $table) {
            // UNIQUE en clave_cita
            $table->unique('clave_cita');

            // Indices para queries frecuentes
            $table->index('alumno_id');
            $table->index('doctor_id');
            $table->index('fecha_cita');
            $table->index(['fecha_cita', 'hora_cita']);
        });
    }

    public function down(): void
    {
        Schema::table('citas', function (Blueprint $table) {
            $table->dropIndex(['fecha_cita', 'hora_cita']);
            $table->dropIndex(['fecha_cita']);
            $table->dropIndex(['doctor_id']);
            $table->dropIndex(['alumno_id']);
            $table->dropUnique(['clave_cita']);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['email']);
        });
    }
};
