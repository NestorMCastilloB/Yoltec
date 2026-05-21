<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Artisan;

/**
 * Endpoint de un solo uso para correr DemoCompletoSeeder en produccion
 * cuando no hay shell disponible (Render free tier).
 *
 * Triple guard: SEED_DEMO_ENABLED debe ser true + token en header X-Seed-Token + throttle:1,5.
 * Apagar despues con SEED_DEMO_ENABLED=false.
 */
class SeedDemoController extends Controller
{
    public function run(Request $request): JsonResponse
    {
        $expected = env('SEED_DEMO_TOKEN');
        $enabled  = filter_var(env('SEED_DEMO_ENABLED', false), FILTER_VALIDATE_BOOLEAN);

        // 404 cuando esta deshabilitado para no revelar la existencia del endpoint
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
}
