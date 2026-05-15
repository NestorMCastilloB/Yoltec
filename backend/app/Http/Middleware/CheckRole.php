<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class CheckRole
{
    // Verifica que el usuario autenticado tenga el rol requerido
    public function handle(Request $request, Closure $next, string $rol): mixed
    {
        if (!$request->user() || $request->user()->tipo !== $rol) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        return $next($request);
    }
}
