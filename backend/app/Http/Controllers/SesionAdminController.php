<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Laravel\Sanctum\PersonalAccessToken;

class SesionAdminController extends Controller
{
    // GET /api/admin/sesiones — solo sesiones activas globales con info de usuario
    // Query params: search (nombre/email/numero_control), only_used (1 = excluir tokens nunca usados)
    public function index(Request $request)
    {
        $this->purgarVencidosLazy();

        $cutoff   = now()->subMinutes((int) config('sanctum.expiration', 1440));
        $search   = trim((string) $request->input('search', ''));
        $onlyUsed = $request->boolean('only_used', false);

        $query = PersonalAccessToken::where('created_at', '>=', $cutoff)
            ->with('tokenable:id,nombre,apellido,email,numero_control,tipo');

        if ($onlyUsed) {
            $query->whereNotNull('last_used_at');
        }

        if ($search !== '') {
            $query->whereHasMorph('tokenable', ['App\\Models\\User'], function ($q) use ($search) {
                $q->where('nombre', 'ILIKE', "%{$search}%")
                  ->orWhere('apellido', 'ILIKE', "%{$search}%")
                  ->orWhere('email', 'ILIKE', "%{$search}%")
                  ->orWhere('numero_control', 'ILIKE', "%{$search}%");
            });
        }

        $sesiones = $query->orderByDesc('last_used_at')->orderByDesc('created_at')->limit(200)->get()
            ->map(function ($token) {
                $u = $token->tokenable;
                return [
                    'id'          => $token->id,
                    'nombre'      => $token->name,
                    'creada_en'   => $token->created_at,
                    'ultimo_uso'  => $token->last_used_at,
                    'usuario'     => $u ? [
                        'id'             => $u->id,
                        'nombre'         => $u->nombre,
                        'apellido'       => $u->apellido,
                        'email'          => $u->email,
                        'numero_control' => $u->numero_control,
                        'tipo'           => $u->tipo,
                    ] : null,
                ];
            });

        return response()->json([
            'total'    => $sesiones->count(),
            'sesiones' => $sesiones,
        ]);
    }

    // DELETE /api/admin/sesiones/{id} — revocar sesion especifica
    public function destroy($id)
    {
        $token = PersonalAccessToken::find($id);

        if (!$token) {
            return response()->json(['message' => 'Sesion no encontrada'], 404);
        }

        $token->delete();
        return response()->json(['message' => 'Sesion revocada.']);
    }

    // POST /api/admin/sesiones/purgar — forzar limpieza inmediata de vencidos
    public function purgar()
    {
        $cutoff   = now()->subMinutes((int) config('sanctum.expiration', 1440));
        $affected = PersonalAccessToken::where('created_at', '<', $cutoff)->delete();
        Cache::put('tokens_purged_lock', true, 3600);

        return response()->json(['eliminados' => $affected]);
    }

    // Render free tier no corre scheduler — fallback throttled cada hora
    private function purgarVencidosLazy(): void
    {
        if (Cache::has('tokens_purged_lock')) {
            return;
        }
        Cache::put('tokens_purged_lock', true, 3600);

        $cutoff = now()->subMinutes((int) config('sanctum.expiration', 1440));
        PersonalAccessToken::where('created_at', '<', $cutoff)->delete();
    }
}
