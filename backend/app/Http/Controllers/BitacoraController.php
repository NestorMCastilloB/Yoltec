<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Bitacora;
use App\Models\Cita;
use Illuminate\Http\Request;
class BitacoraController extends Controller
{
    // Listar bitácoras
    public function index(Request $request)
    {
        $user = $request->user();

        if ($user->esAlumno()) {
            $bitacoras = Bitacora::where('alumno_id', $user->id)
                                ->with(['cita', 'doctor'])
                                ->orderBy('created_at', 'desc')
                                ->get();
        } else {
            $bitacoras = Bitacora::with(['cita', 'alumno'])
                                ->orderBy('created_at', 'desc')
                                ->get();
        }

        return response()->json($bitacoras, 200);
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
