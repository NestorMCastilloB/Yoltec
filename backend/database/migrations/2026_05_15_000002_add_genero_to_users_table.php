<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    // Agrega columna genero — usado para personalización de saludos (Bienvenido/Bienvenida)
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('genero', 20)->nullable()->after('fecha_nacimiento');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('genero');
        });
    }
};
