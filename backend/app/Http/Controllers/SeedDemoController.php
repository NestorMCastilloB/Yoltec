<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Artisan;

/**
 * Endpoint de un solo uso para correr DemoCompletoSeeder en produccion
 * cuando no hay shell disponible (Render free tier).
 * Triple guard: SEED_DEMO_ENABLED + token + throttle.
 */
class SeedDemoController extends Controller
{
    public function run(Request $request): JsonResponse
    {
        [$expected, $enabledRaw] = $this->leerEnv();
        $enabled = filter_var($enabledRaw, FILTER_VALIDATE_BOOLEAN);

        // Debug temporal: ?debug=DEBUG_TOKEN_TEMPORAL retorna visibilidad de env sin filtrar secretos
        if ($request->query('debug') === 'verify-env-2026') {
            return response()->json([
                'enabled' => $enabled,
                'enabled_raw' => $enabledRaw,
                'token_present' => $expected !== null && $expected !== '',
                'token_length' => $expected ? strlen($expected) : 0,
                'sources' => [
                    'getenv_token'  => getenv('SEED_DEMO_TOKEN') !== false,
                    'env_token'     => isset($_ENV['SEED_DEMO_TOKEN']),
                    'server_token'  => isset($_SERVER['SEED_DEMO_TOKEN']),
                    'env_helper'    => env('SEED_DEMO_TOKEN') !== null,
                ],
            ], 200);
        }

        if (! $enabled || ! $expected) {
            abort(404);
        }
        if ($request->header('X-Seed-Token') !== $expected) {
            abort(403, 'Token invalido');
        }

        Artisan::call('db:seed', [
            '--class' => 'DemoCompletoSeeder',
            '--force' => true,
        ]);

        return response()->json([
            'status' => 'ok',
            'output' => Artisan::output(),
        ]);
    }

    private function leerEnv(): array
    {
        $token = getenv('SEED_DEMO_TOKEN');
        if ($token === false) $token = $_ENV['SEED_DEMO_TOKEN'] ?? null;
        if (! $token)         $token = $_SERVER['SEED_DEMO_TOKEN'] ?? null;
        if (! $token)         $token = env('SEED_DEMO_TOKEN');

        $enabled = getenv('SEED_DEMO_ENABLED');
        if ($enabled === false) $enabled = $_ENV['SEED_DEMO_ENABLED'] ?? null;
        if ($enabled === null)  $enabled = $_SERVER['SEED_DEMO_ENABLED'] ?? null;
        if ($enabled === null)  $enabled = env('SEED_DEMO_ENABLED', false);

        return [$token ?: null, $enabled];
    }
}
