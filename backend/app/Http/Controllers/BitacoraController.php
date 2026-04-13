<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Bitacora;
use App\Models\Cita;
use Illuminate\Http\Request;
class BitacoraController extends Controller
{
    // Listar bitácoras (soporta filtros: fecha_desde, fecha_hasta, alumno)
    public function index(Request $request)
    {
        $user = $request->user();

        $query = $user->esAlumno()
            ? Bitacora::where('alumno_id', $user->id)->with(['cita', 'doctor'])
            : Bitacora::with(['cita', 'alumno']);

        if ($request->filled('fecha_desde')) {
            $query->whereDate('created_at', '>=', $request->fecha_desde);
        }
        if ($request->filled('fecha_hasta')) {
            $query->whereDate('created_at', '<=', $request->fecha_hasta);
        }
        // Solo para doctor: filtrar por número de control del alumno
        if (!$user->esAlumno() && $request->filled('alumno')) {
            $query->whereHas('alumno', function ($q) use ($request) {
                $q->where('numero_control', 'like', '%' . $request->alumno . '%')
                  ->orWhere('nombre', 'like', '%' . $request->alumno . '%')
                  ->orWhere('apellido', 'like', '%' . $request->alumno . '%');
            });
        }

        $bitacoras = $query->orderBy('created_at', 'desc')->get();

        return response()->json(['bitacoras' => $bitacoras], 200);
    }

    // Crear bitácora (solo doctor)
    public function store(Request $request)
    {
        $user = $request->user();

        if (!$user->esDoctor()) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $validated = $request->validate([
            'cita_id' => 'required|exists:citas,id',
            'diagnostico' => 'required|string',
            'tratamiento' => 'required|string',
            'observaciones' => 'required|string',
            'peso' => 'required|string',
            'altura' => 'required|string',
            'temperatura' => 'required|string',
            'presion_arterial' => 'required|string',
        ]);

        $cita = Cita::findOrFail($validated['cita_id']);
        $validated['alumno_id'] = $cita->alumno_id;
        $validated['doctor_id'] = $user->id;

        $bitacora = Bitacora::create($validated);

        return response()->json([
            'message' => 'Bitácora registrada exitosamente',
            'bitacora' => $bitacora->load(['cita', 'alumno', 'doctor'])
        ], 201);
    }

    // Ver bitácora
    public function show(Request $request, $id)
    {
        $user = $request->user();
        $bitacora = Bitacora::with(['cita', 'alumno', 'doctor'])->findOrFail($id);

        // Verificar permisos
        if ($user->esAlumno() && $bitacora->alumno_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        return response()->json($bitacora, 200);
    }

    // Actualizar bitácora (solo doctor)
    public function update(Request $request, $id)
    {
        $user = $request->user();

        if (!$user->esDoctor()) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $bitacora = Bitacora::findOrFail($id);

        $validated = $request->validate([
            'diagnostico' => 'required|string',
            'tratamiento' => 'required|string',
            'observaciones' => 'required|string',
            'peso' => 'required|string',
            'altura' => 'required|string',
            'temperatura' => 'required|string',
            'presion_arterial' => 'required|string',
        ]);

        $bitacora->update($validated);

        return response()->json([
            'message' => 'Bitácora actualizada exitosamente',
            'bitacora' => $bitacora
        ], 200);
    }
}
