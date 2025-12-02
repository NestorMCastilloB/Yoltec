<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Receta;
use App\Models\Cita;
use Illuminate\Http\Request;
class RecetaController extends Controller
{
    // Listar recetas
    public function index(Request $request)
    {
        $user = $request->user();

        if ($user->esAlumno()) {
            $recetas = Receta::where('alumno_id', $user->id)
                            ->with(['cita', 'doctor'])
                            ->orderBy('fecha_emision', 'desc')
                            ->get();
        } else {
            $recetas = Receta::with(['cita', 'alumno'])
                            ->orderBy('fecha_emision', 'desc')
                            ->get();
        }

        return response()->json($recetas, 200);
    }

    // Crear receta (solo doctor)
    public function store(Request $request)
    {
        $user = $request->user();

        if (!$user->esDoctor()) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $validated = $request->validate([
            'cita_id' => 'required|exists:citas,id',
            'medicamentos' => 'required|string',
            'indicaciones' => 'required|string',
            'fecha_emision' => 'required|date',
        ]);

        // Evitar múltiples recetas para la misma cita
        if (Receta::where('cita_id', $validated['cita_id'])->exists()) {
            return response()->json([
                'message' => 'Ya existe una receta registrada para esta cita. Puedes editar la existente en lugar de crear otra.',
            ], 422);
        }

        $cita = Cita::findOrFail($validated['cita_id']);
        $validated['alumno_id'] = $cita->alumno_id;
        $validated['doctor_id'] = $user->id;

        $receta = Receta::create($validated);

        return response()->json([
            'message' => 'Receta creada exitosamente',
            'receta' => $receta->load(['cita', 'alumno', 'doctor'])
        ], 201);
    }

    // Ver receta
    public function show(Request $request, $id)
    {
        $user = $request->user();
        $receta = Receta::with(['cita', 'alumno', 'doctor'])->findOrFail($id);

        // Verificar permisos
        if ($user->esAlumno() && $receta->alumno_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        return response()->json($receta, 200);
    }

    // Actualizar receta (solo doctor)
    public function update(Request $request, $id)
    {
        $user = $request->user();

        if (!$user->esDoctor()) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $receta = Receta::findOrFail($id);

        $validated = $request->validate([
            'medicamentos' => 'required|string',
            'indicaciones' => 'required|string',
            'fecha_emision' => 'required|date',
        ]);

        $receta->update($validated);

        return response()->json([
            'message' => 'Receta actualizada exitosamente',
            'receta' => $receta->load(['cita', 'alumno', 'doctor'])
        ], 200);
    }
}
