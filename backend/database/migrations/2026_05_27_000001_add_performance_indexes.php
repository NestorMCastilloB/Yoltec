<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Solo agregar índices que no existan (idempotente)
        $existingCitasIndexes = collect(DB::select("SELECT indexname FROM pg_indexes WHERE tablename = 'citas'"))
            ->pluck('indexname')->toArray();

        Schema::table('citas', function (Blueprint $table) use ($existingCitasIndexes) {
            if (!in_array('citas_fecha_cita_index', $existingCitasIndexes)) {
                $table->index('fecha_cita');
            }
            if (!in_array('citas_alumno_id_index', $existingCitasIndexes)) {
                $table->index('alumno_id');
            }
        });

        Schema::table('pre_evaluaciones_ia', function (Blueprint $table) {
            $table->index('estatus_validacion');
        });
    }

    public function down(): void
    {
        Schema::table('pre_evaluaciones_ia', function (Blueprint $table) {
            $table->dropIndex(['estatus_validacion']);
        });
    }
};
