<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Impide la doble reserva del mismo horario a nivel de base de datos.
 *
 * reservarSlot() comprobaba la ocupación con lockForUpdate()->exists() dentro
 * de una transacción. La intención era correcta, pero en PostgreSQL FOR UPDATE
 * solo bloquea filas que existen: cuando el horario está libre no hay ninguna
 * fila que bloquear, así que dos transacciones simultáneas lo veían libre a la
 * vez y ambas insertaban.
 *
 * La invariante pasa a estar garantizada por la base y no por la aplicación.
 */
return new class extends Migration
{
    public function up(): void
    {
        // Un horario solo lo ocupa una cita programada. Las canceladas y las
        // borradas lógicamente lo liberan, por eso el índice es parcial.
        DB::statement("
            UPDATE citas AS duplicada
            SET estatus = 'cancelada', updated_at = NOW()
            FROM citas AS original
            WHERE duplicada.id > original.id
              AND duplicada.fecha_cita = original.fecha_cita
              AND duplicada.hora_cita  = original.hora_cita
              AND duplicada.estatus = 'programada'
              AND original.estatus  = 'programada'
              AND duplicada.deleted_at IS NULL
              AND original.deleted_at IS NULL
        ");

        DB::statement("
            CREATE UNIQUE INDEX IF NOT EXISTS citas_slot_programado_unico
            ON citas (fecha_cita, hora_cita)
            WHERE estatus = 'programada' AND deleted_at IS NULL
        ");
    }

    public function down(): void
    {
        // Las citas canceladas por el up() no se restauran: reprogramarlas es
        // una decisión del consultorio, no de una migración.
        DB::statement('DROP INDEX IF EXISTS citas_slot_programado_unico');
    }
};
