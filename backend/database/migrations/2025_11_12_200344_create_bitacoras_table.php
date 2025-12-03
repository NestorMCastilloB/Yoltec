<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bitacoras', function (Blueprint $table) {
            $table->id();
            // IDs relacionados sin constraints de FK para evitar problemas en Neon; se validan en la app
            $table->foreignId('cita_id');
            $table->foreignId('alumno_id');
            $table->foreignId('doctor_id');
            $table->text('diagnostico')->nullable();
            $table->text('tratamiento')->nullable();
            $table->text('observaciones')->nullable();
            $table->string('peso')->nullable();
            $table->string('altura')->nullable();
            $table->string('temperatura')->nullable();
            $table->string('presion_arterial')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bitacoras');
    }
};
