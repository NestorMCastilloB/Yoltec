<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    // Hora de cierre para días tipo 'reduced' — citas posteriores se bloquean
    public function up(): void
    {
        Schema::table('dias_especiales', function (Blueprint $table) {
            $table->time('hora_cierre')->nullable()->after('etiqueta');
        });
    }

    public function down(): void
    {
        Schema::table('dias_especiales', function (Blueprint $table) {
            $table->dropColumn('hora_cierre');
        });
    }
};
