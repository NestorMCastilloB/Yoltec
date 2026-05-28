<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Laravel\Sanctum\PersonalAccessToken;

class PurgeStaleTokens extends Command
{
    protected $signature = 'tokens:purge';
    protected $description = 'Elimina tokens Sanctum vencidos (older than sanctum.expiration)';

    public function handle(): void
    {
        $cutoff = now()->subMinutes((int) config('sanctum.expiration', 1440));

        $affected = PersonalAccessToken::where('created_at', '<', $cutoff)->delete();

        $this->info("Tokens eliminados: {$affected}");
    }
}
