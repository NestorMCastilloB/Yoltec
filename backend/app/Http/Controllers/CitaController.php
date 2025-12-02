<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Cita;
use App\Models\User;
use Illuminate\Http\Request;


class CitaController extends Controller
{
    // Listar citas
    public function index(Request $request)
    {
        $user = $request->user();

        if ($user->esAlumno()) {
            $citas = Cita::where('alumno_id', $user->id)
                        ->with(['doctor'])
                        ->orderBy('fecha_cita', 'desc')
                        ->orderBy('hora_cita', 'desc')
                        ->get();
        } else {
            $citas = Cita::with(['alumno'])
                        ->orderBy('fecha_cita', 'desc')
                        ->orderBy('hora_cita', 'desc')
                        ->get();
        }

        return response()->json($citas, 200);
    }

    // Crear cita
    public function store(Request $request)
    {
        $validated = $request->validate([
            'fecha_cita' => 'required|date|after_or_equal:today',
            'hora_cita' => 'required|date_format:H:i',
            'motivo' => 'nullable|string|max:500',
            'numero_control' => 'nullable|string|exists:users,numero_control',
        ]);

        $user = $request->user();

        // Generar clave única
        $validated['clave_cita'] = Cita::generarClaveCita();
        if ($user->esAlumno()) {
            $validated['alumno_id'] = $user->id;
        } elseif ($request->filled('numero_control')) {
            $alumno = User::where('numero_control', $request->numero_control)->firstOrFail();
            $validated['alumno_id'] = $alumno->id;
        } else {
            $validated['alumno_id'] = $request->alumno_id;
        }
        $validated['estatus'] = 'programada';

        $cita = Cita::create($validated);

        return response()->json([
            'message' => 'Cita agendada exitosamente',
            'cita' => $cita->load(['alumno', 'doctor'])
        ], 201);
    }

    // Ver una cita
    public function show(Request $request, $id)
    {
        $user = $request->user();
        $cita = Cita::with(['alumno', 'doctor', 'bitacora', 'receta'])->findOrFail($id);

        // Verificar permisos
        if ($user->esAlumno() && $cita->alumno_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        return response()->json($cita, 200);
    }

    // Cancelar cita
    public function cancelar(Request $request, $id)
    {
        $user = $request->user();
        $cita = Cita::findOrFail($id);

        // Verificar permisos
        if ($user->esAlumno() && $cita->alumno_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        if ($cita->estatus === 'atendida') {
            return response()->json([
                'message' => 'No se puede cancelar una cita ya atendida'
            ], 400);
        }

        $cita->update(['estatus' => 'cancelada']);

        return response()->json([
            'message' => 'Cita cancelada exitosamente',
            'cita' => $cita
        ], 200);
    }

    // Marcar como atendida (solo doctor)
    public function atender(Request $request, $id)
    {
        $user = $request->user();

        if (!$user->esDoctor()) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $cita = Cita::findOrFail($id);

        $cita->update([
            'estatus' => 'atendida',
            'doctor_id' => $user->id,
            'fecha_hora_atencion' => now(),
        ]);

        return response()->json([
            'message' => 'Cita marcada como atendida',
            'cita' => $cita
        ], 200);
    }
}

