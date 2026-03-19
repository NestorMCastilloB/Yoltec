<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pre_evaluaciones_ia', function (Blueprint $table) {
            $table->id();
            $table->foreignId('cita_id')->constrained('citas')->onDelete('cascade');
            $table->foreignId('alumno_id')->constrained('users')->onDelete('cascade');
            
            // Respuestas a las preguntas (almacenadas como JSON)
            $table->json('respuestas');
            
            // Resultado del diagnóstico IA
            $table->string('diagnostico_sugerido');
            $table->decimal('confianza', 3, 2); // 0.00 - 1.00
            $table->json('sintomas_detectados');
            
            // Estado de validación por el doctor
            $table->enum('estatus_validacion', ['pendiente', 'validado', 'descartado'])->default('pendiente');
            $table->foreignId('validado_por')->nullable()->constrained('users')->onDelete('set null');
            $table->text('comentario_doctor')->nullable();
            $table->timestamp('fecha_validacion')->nullable();
            
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pre_evaluaciones_ia');
    }
};
