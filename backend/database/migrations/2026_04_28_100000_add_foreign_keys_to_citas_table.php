<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Limpiar citas huérfanas que referencian usuarios que ya no existen
        DB::statement("
            DELETE FROM citas
            WHERE alumno_id NOT IN (SELECT id FROM users)
        ");

        DB::statement("
            UPDATE citas SET doctor_id = NULL
            WHERE doctor_id IS NOT NULL
            AND doctor_id NOT IN (SELECT id FROM users)
        ");

        Schema::table('citas', function (Blueprint $table) {
            $table->foreign('alumno_id')
                  ->references('id')->on('users')
                  ->onDelete('cascade');

            $table->foreign('doctor_id')
                  ->references('id')->on('users')
                  ->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::table('citas', function (Blueprint $table) {
            $table->dropForeign(['alumno_id']);
            $table->dropForeign(['doctor_id']);
        });
    }
};
