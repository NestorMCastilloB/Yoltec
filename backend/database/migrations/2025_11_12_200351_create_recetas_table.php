<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('recetas', function (Blueprint $table) {
            $table->id();
            // IDs relacionados sin constraints de FK para evitar problemas en Neon; se validan en la app
            $table->foreignId('cita_id');
            $table->foreignId('alumno_id');
            $table->foreignId('doctor_id');
            $table->text('medicamentos'); // Puede ser JSON o texto simple
            $table->text('indicaciones')->nullable();
            $table->date('fecha_emision');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('recetas');
    }
};
