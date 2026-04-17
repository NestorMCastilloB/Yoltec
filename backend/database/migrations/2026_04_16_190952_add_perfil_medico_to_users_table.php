<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('tipo_sangre', 5)->nullable()->after('fcm_token');
            $table->text('alergias')->nullable()->after('tipo_sangre');
            $table->text('enfermedades_cronicas')->nullable()->after('alergias');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['tipo_sangre', 'alergias', 'enfermedades_cronicas']);
        });
    }
};
