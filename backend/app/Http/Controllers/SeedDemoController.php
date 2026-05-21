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

        // Debug temporal
        if ($request->query('debug') === 'verify-env-2026') {
            $probes = ['APP_NAME', 'DB_HOST', 'NEON_URL', 'RESEND_API_KEY', 'SEED_DEMO_ENABLED', 'SEED_DEMO_TOKEN'];
            $visibility = [];
            foreach ($probes as $k) {
                $visibility[$k] = [
                    'getenv' => getenv($k) !== false,
                    'env_arr' => isset($_ENV[$k]),
                    'srv_arr' => isset($_SERVER[$k]),
                    'env_fn' => env($k) !== null,
                ];
            }
            return response()->json([
                'enabled' => $enabled,
                'env_count_getenv' => count(array_filter(array_keys($_SERVER), fn($k) => getenv($k) !== false)),
                'env_count_arr'    => count($_ENV),
                'probes' => $visibility,
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
