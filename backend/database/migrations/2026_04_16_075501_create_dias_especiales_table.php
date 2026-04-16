<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('dias_especiales', function (Blueprint $table) {
            $table->id();
            $table->date('fecha')->unique();
            $table->string('tipo', 30)->default('holiday'); // holiday, vacation, reduced
            $table->string('etiqueta', 200)->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('dias_especiales');
    }
};
