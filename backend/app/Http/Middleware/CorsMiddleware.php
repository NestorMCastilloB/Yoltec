<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class CorsMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure(\Illuminate\Http\Request): (\Illuminate\Http\Response|\Illuminate\Http\RedirectResponse)  $next
     * @return \Illuminate\Http\Response|\Illuminate\Http\RedirectResponse
     */
    public function handle(Request $request, Closure $next)
    {
        // Orígenes permitidos para desarrollo con ngrok
        $allowedOrigins = [
            'http://localhost:4200',
            'http://127.0.0.1:4200',
            'https://shara-isospondylous-capitally.ngrok-free.dev',
            'http://shara-isospondylous-capitally.ngrok-free.dev',
        ];

        $origin = $request->header('Origin');

        // Configurar CORS headers
        header('Access-Control-Allow-Origin: ' . ($origin && in_array($origin, $allowedOrigins) ? $origin : 'http://localhost:4200'));
        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
        header('Access-Control-Allow-Credentials: true');
        header('Access-Control-Max-Age: 3600');

        // Manejar preflight requests
        if ($request->isMethod('OPTIONS')) {
            return response('', 200);
        }

        // Fix hallazgo #4: ocultar versión PHP en headers
        header_remove('X-Powered-By');

        $response = $next($request);
        $response->headers->remove('X-Powered-By');

        return $response;
    }
}
