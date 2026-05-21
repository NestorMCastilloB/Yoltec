<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Artisan;

// Endpoint de un solo uso para sembrar demo en prod sin shell — gated por env + token + throttle
class SeedDemoController extends Controller
{
    public function run(Request $request): JsonResponse
    {
        $expected = env('SEED_DEMO_TOKEN');
        $enabled = filter_var(env('SEED_DEMO_ENABLED', false), FILTER_VALIDATE_BOOLEAN);

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
