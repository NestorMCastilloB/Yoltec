<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('citas', function (Blueprint $table) {
            $table->id();
            // Clave de la cita (única a nivel de aplicación, no en la BD para evitar errores de constraint en Neon)
            $table->string('clave_cita');
            // Por simplicidad en Neon, dejamos las llaves foráneas sin constraint y controlamos en la app
            $table->foreignId('alumno_id');
            $table->foreignId('doctor_id')->nullable();
            $table->date('fecha_cita');
            $table->time('hora_cita');
            $table->string('motivo')->nullable();
            // Usamos string en lugar de enum para evitar problemas con tipos en PostgreSQL/Neon
            $table->string('estatus')->default('programada');
            $table->dateTime('fecha_hora_atencion')->nullable(); // Cuando se atendió
            $table->text('notas')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('citas');
    }
};
