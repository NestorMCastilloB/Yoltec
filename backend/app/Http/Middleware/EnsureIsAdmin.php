<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureIsAdmin
{
    public function handle(Request $request, Closure $next)
    {
        if (!$request->user() || $request->user()->tipo !== 'admin') {
            abort(403, 'No autorizado');
        }

        return $next($request);
    }
}
