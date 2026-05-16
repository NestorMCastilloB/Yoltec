<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    // La columna 'code' era varchar(6) pero el service guarda Hash::make($code)
    // (bcrypt ~60 chars). Se amplía a varchar(255).
    public function up(): void
    {
        Schema::table('two_factor_codes', function (Blueprint $table) {
            $table->string('code', 255)->change();
        });
    }

    public function down(): void
    {
        Schema::table('two_factor_codes', function (Blueprint $table) {
            $table->string('code', 6)->change();
        });
    }
};
