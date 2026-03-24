<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->validateCsrfTokens(except: [
            '*',
        ]);
        
        $middleware->trustProxies(at: '*');
        
        $middleware->web(\Illuminate\Http\Middleware\HandleCors::class);
        
        $middleware->api(\Illuminate\Http\Middleware\HandleCors::class);
        
        // Middleware CORS personalizado para ngrok
        $middleware->api(\App\Http\Middleware\CorsMiddleware::class);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Para rutas API, retornar siempre JSON en lugar de páginas HTML
        $exceptions->shouldRenderJsonWhen(function (\Illuminate\Http\Request $request) {
            return $request->is('api/*') || $request->expectsJson();
        });

        // Fix hallazgo #3 y #5: retornar 401 limpio en lugar de 500 o "Route not defined"
        $exceptions->render(function (\Illuminate\Auth\AuthenticationException $e, \Illuminate\Http\Request $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return response()->json(['message' => 'No autenticado.'], 401);
            }
        });

        $exceptions->render(function (\InvalidArgumentException $e, \Illuminate\Http\Request $request) {
            if (($request->is('api/*') || $request->expectsJson()) && str_contains($e->getMessage(), 'Route')) {
                return response()->json(['message' => 'No autenticado.'], 401);
            }
        });
    })->create();
