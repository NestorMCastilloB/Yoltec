<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    // Preludio a cifrar fcm_token con cast `encrypted` en User: los valores plain text
    // existentes lanzarian DecryptException al leerse. Limpiamos a NULL; los dispositivos
    // re-registran el token en el siguiente login y queda cifrado de origen.
    public function up(): void
    {
        DB::table('users')
            ->whereNotNull('fcm_token')
            ->update(['fcm_token' => null]);
    }

    public function down(): void
    {
        // Irreversible — el token original ya no existe
    }
};
