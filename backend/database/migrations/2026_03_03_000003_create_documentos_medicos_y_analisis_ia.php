<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Tabla para documentos médicos
        Schema::create('documentos_medicos', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('paciente_id');
            $table->unsignedBigInteger('subido_por');
            $table->enum('tipo_documento', [
                'laboratorio',
                'rayos_x',
                'receta_externa',
                'historial',
                'notas_clinicas',
                'otro'
            ])->default('otro');
            $table->string('nombre_archivo');
            $table->string('ruta_archivo');
            $table->string('mime_type');
            $table->unsignedBigInteger('tamano_bytes');
            $table->longText('texto_extraido')->nullable();
            $table->enum('estatus_procesamiento', [
                'pendiente',
                'procesando',
                'completado',
                'error'
            ])->default('pendiente');
            $table->json('datos_extraidos')->nullable();
            $table->timestamps();
        });

        // Tabla para análisis de IA
        Schema::create('analisis_documentos_ia', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('documento_id');
            $table->enum('estatus', ['pendiente', 'completado', 'error'])->default('pendiente');
            $table->json('datos_detectados')->nullable();
            $table->string('diagnostico_sugerido')->nullable();
            $table->text('descripcion_analisis')->nullable();
            $table->decimal('nivel_confianza', 3, 2)->nullable();
            $table->json('palabras_clave_detectadas')->nullable();
            $table->unsignedBigInteger('validado_por')->nullable();
            $table->enum('estatus_validacion', [
                'pendiente',
                'aprobado',
                'rechazado',
                'corregido'
            ])->default('pendiente');
            $table->text('comentario_doctor')->nullable();
            $table->string('diagnostico_final')->nullable();
            $table->timestamp('fecha_validacion')->nullable();
            $table->timestamps();
        });

        // Agregar columna de rol admin a users si no existe
        if (!Schema::hasColumn('users', 'es_admin')) {
            Schema::table('users', function (Blueprint $table) {
                $table->boolean('es_admin')->default(false)->after('tipo');
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('analisis_documentos_ia');
        Schema::dropIfExists('documentos_medicos');
        
        if (Schema::hasColumn('users', 'es_admin')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('es_admin');
            });
        }
    }
};
