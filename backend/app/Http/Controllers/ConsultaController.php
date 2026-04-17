<?php

namespace App\Http\Controllers;

use App\Models\Cita;
use App\Models\Consulta;
use Illuminate\Http\Request;

class ConsultaController extends Controller
{
    // Guardar o actualizar consulta (solo doctor)
    public function store(Request $request, int $citaId)
    {
        $user = $request->user();

        if (!$user->esDoctor()) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $cita = Cita::findOrFail($citaId);

        $data = $request->validate([
            'diagnostico'   => 'required|string|max:2000',
            'tratamiento'   => 'required|string|max:2000',
            'observaciones' => 'nullable|string|max:2000',
        ]);

        $consulta = Consulta::updateOrCreate(
            ['cita_id' => $cita->id],
            [
                'doctor_id'    => $user->id,
                'alumno_id'    => $cita->alumno_id,
                'diagnostico'  => $data['diagnostico'],
                'tratamiento'  => $data['tratamiento'],
                'observaciones' => $data['observaciones'] ?? null,
            ]
        );

        // Marcar cita como atendida si no lo está
        if ($cita->estatus === 'programada') {
            $cita->update([
                'estatus' => 'atendida',
                'doctor_id' => $user->id,
                'fecha_hora_atencion' => now(),
            ]);
        }

        return response()->json([
            'message'  => 'Consulta guardada.',
            'consulta' => $consulta,
        ], 201);
    }

    // Ver consulta de una cita
    public function show(Request $request, int $citaId)
    {
        $user = $request->user();
        $cita = Cita::with('consulta.doctor')->findOrFail($citaId);

        // Alumno solo puede ver su propia consulta
        if ($user->esAlumno() && $cita->alumno_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        if (!$cita->consulta) {
            return response()->json(['message' => 'Esta cita no tiene consulta registrada.'], 404);
        }

        return response()->json(['consulta' => $cita->consulta]);
    }
}
