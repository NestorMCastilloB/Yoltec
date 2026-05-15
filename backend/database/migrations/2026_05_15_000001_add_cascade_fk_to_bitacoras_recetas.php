<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Limpiar registros huérfanos antes de agregar constraints
        DB::statement("DELETE FROM bitacoras WHERE cita_id NOT IN (SELECT id FROM citas)");
        DB::statement("DELETE FROM recetas WHERE cita_id NOT IN (SELECT id FROM citas)");

        Schema::table('bitacoras', function (Blueprint $table) {
            $table->foreign('cita_id')->references('id')->on('citas')->onDelete('cascade');
        });

        Schema::table('recetas', function (Blueprint $table) {
            $table->foreign('cita_id')->references('id')->on('citas')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::table('bitacoras', function (Blueprint $table) {
            $table->dropForeign(['cita_id']);
        });

        Schema::table('recetas', function (Blueprint $table) {
            $table->dropForeign(['cita_id']);
        });
    }
};
