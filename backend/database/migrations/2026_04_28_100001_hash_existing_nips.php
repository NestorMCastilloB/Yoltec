<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

return new class extends Migration
{
    public function up(): void
    {
        // Hash all existing plain-text NIPs in the users table.
        // Plain-text NIPs are 6 chars; bcrypt hashes start with $2y$ and are 60 chars.
        $users = DB::table('users')
            ->whereNotNull('nip')
            ->where('nip', '!=', '')
            ->get(['id', 'nip']);

        foreach ($users as $user) {
            // Skip if already hashed (bcrypt hashes are 60 chars starting with $2y$)
            if (str_starts_with($user->nip, '$2y$') || str_starts_with($user->nip, '$2a$')) {
                continue;
            }

            DB::table('users')
                ->where('id', $user->id)
                ->update(['nip' => Hash::make($user->nip)]);
        }
    }

    public function down(): void
    {
        // Irreversible — hashed NIPs cannot be reverted to plain text
    }
};
