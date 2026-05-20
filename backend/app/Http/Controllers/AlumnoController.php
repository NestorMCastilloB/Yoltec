<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;

class AlumnoController extends Controller
{
    // GET /api/alumnos/buscar?q=… — busca por número de control, nombre o apellido (máx 20)
    public function buscar(Request $request)
    {
        $q = trim((string) $request->input('q', ''));
        if (strlen($q) < 2) {
            return response()->json(['alumnos' => []]);
        }
        $alumnos = User::where('tipo', 'alumno')
            ->where(function ($query) use ($q) {
                $query->where('numero_control', 'ILIKE', "%{$q}%")
                    ->orWhere('nombre', 'ILIKE', "%{$q}%")
                    ->orWhere('apellido', 'ILIKE', "%{$q}%");
            })
            ->select('id', 'numero_control', 'nombre', 'apellido')
            ->limit(20)
            ->get()
            ->map(fn($a) => [
                'id' => $a->id,
                'numero_control' => $a->numero_control,
                'nombre' => "{$a->nombre} {$a->apellido}",
            ]);
        return response()->json(['alumnos' => $alumnos]);
    }
}
