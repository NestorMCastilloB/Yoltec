<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\IA\Services\IAService;
use App\Models\Cita;
use App\Models\PreEvaluacionIA;
use Illuminate\Http\Request;

/**
 * Controlador para la IA 2: Pre-evaluación de Síntomas
 * Interactivo con el alumno después de agendar cita
 */
class IASymptomController extends Controller
{
    private IAService $iaService;

    public function __construct()
    {
        $this->iaService = new IAService();
    }

    /**
     * Inicia el cuestionario de pre-evaluación
     * POST /api/ia/symptoms/iniciar/{citaId}
     */
    public function iniciar(Request $request, int $citaId)
    {
        $user = $request->user();
        $cita = Cita::findOrFail($citaId);

        // Verificar que el alumno es dueño de la cita o es doctor
        if ($user->esAlumno() && $cita->alumno_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        // Verificar que la cita está programada
        if ($cita->estatus !== 'programada') {
            return response()->json([
                'message' => 'No se puede hacer pre-evaluación. La cita no está programada.'
            ], 400);
        }

        // Iniciar pre-evaluación
        $resultado = $this->iaService->iniciarPreEvaluacion($citaId);

        return response()->json($resultado, 200);
    }

    /**
     * Envía respuestas y obtiene diagnóstico preliminar
     * POST /api/ia/symptoms/evaluar/{citaId}
     */
    public function evaluar(Request $request, int $citaId)
    {
        $user = $request->user();
        $cita = Cita::findOrFail($citaId);

        // Verificar permisos
        if ($user->esAlumno() && $cita->alumno_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        // Validar respuestas
        $validated = $request->validate([
            'respuestas' => 'required|array',
            'respuestas.*.pregunta_id' => 'nullable|integer',
            'respuestas.*.sintoma_relacionado' => 'nullable|string',
            'respuestas.*.respuesta' => 'required|string',
        ]);

        // Procesar respuestas
        $resultado = $this->iaService->procesarRespuestasPreEvaluacion(
            $citaId, 
            $validated['respuestas']
        );

        // Si necesita más preguntas
        if ($resultado['fase'] === 'preguntas_adicionales') {
            return response()->json($resultado, 200);
        }

        // Evaluación completada
        return response()->json($resultado, 200);
    }

    /**
     * Obtiene los resultados de una pre-evaluación guardada
     * GET /api/ia/symptoms/resultado/{citaId}
     */
    public function obtenerResultado(Request $request, int $citaId)
    {
        $user = $request->user();
        $cita = Cita::findOrFail($citaId);

        // Verificar permisos
        if ($user->esAlumno() && $cita->alumno_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $preEvaluacion = PreEvaluacionIA::where('cita_id', $citaId)->first();

        if (!$preEvaluacion) {
            return response()->json([
                'message' => 'No hay pre-evaluación registrada para esta cita'
            ], 404);
        }

        // Si es doctor, mostrar análisis completo
        if ($user->esDoctor()) {
            return response()->json([
                'cita_id' => $citaId,
                'alumno' => [
                    'id' => $cita->alumno->id,
                    'nombre' => $cita->alumno->name,
                ],
                'pre_evaluacion' => $preEvaluacion,
                'sintomas_detectados' => $preEvaluacion->sintomas_detectados,
                'posibles_diagnosticos' => $preEvaluacion->posibles_enfermedades,
                'confianza_ia' => $preEvaluacion->confianza,
                'respuestas_brutas' => $preEvaluacion->respuestas,
                'validado_por_doctor' => $preEvaluacion->doctorValidador ? [
                    'id' => $preEvaluacion->doctorValidador->id,
                    'nombre' => $preEvaluacion->doctorValidador->name,
                ] : null,
            ], 200);
        }

        // Si es alumno, mostrar versión simplificada
        return response()->json([
            'cita_id' => $citaId,
            'sintomas_reportados' => $preEvaluacion->sintomas_detectados,
            'posibles_causas' => array_slice($preEvaluacion->posibles_enfermedades ?? [], 0, 3),
            'mensaje' => '⚠️ Recuerda: solo el doctor puede dar un diagnóstico oficial.',
        ], 200);
    }

    /**
     * El doctor valida/ajusta la pre-evaluación
     * POST /api/ia/symptoms/validar/{preEvaluacionId}
     */
    public function validar(Request $request, int $preEvaluacionId)
    {
        $user = $request->user();

        if (!$user->esDoctor()) {
            return response()->json([
                'message' => 'Solo doctores pueden validar pre-evaluaciones'
            ], 403);
        }

        $validated = $request->validate([
            'diagnostico_correcto' => 'nullable|string',
            'es_acertado' => 'required|boolean',
            'observaciones' => 'nullable|string',
        ]);

        $preEvaluacion = PreEvaluacionIA::findOrFail($preEvaluacionId);

        $preEvaluacion->update([
            'es_acertado' => $validated['es_acertado'],
            'diagnostico_correcto' => $validated['diagnostico_correcto'],
            'observaciones_doctor' => $validated['observaciones'],
            'validado_por' => $user->id,
            'fecha_validacion' => now(),
        ]);

        return response()->json([
            'message' => 'Pre-evaluación validada correctamente',
            'pre_evaluacion' => $preEvaluacion,
        ], 200);
    }

    /**
     * Lista todas las pre-evaluaciones (solo doctores)
     * GET /api/ia/symptoms/listado
     */
    public function listado(Request $request)
    {
        $user = $request->user();

        if (!$user->esDoctor()) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $preEvaluaciones = PreEvaluacionIA::with(['cita', 'alumno', 'doctorValidador'])
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json([
            'message' => 'Listado de pre-evaluaciones',
            'data' => $preEvaluaciones,
        ], 200);
    }

    /**
     * Reinicia/cancela una pre-evaluación
     * DELETE /api/ia/symptoms/{citaId}
     */
    public function cancelar(Request $request, int $citaId)
    {
        $user = $request->user();
        $cita = Cita::findOrFail($citaId);

        if ($user->esAlumno() && $cita->alumno_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        PreEvaluacionIA::where('cita_id', $citaId)->delete();

        return response()->json([
            'message' => 'Pre-evaluación cancelada. Puedes iniciar una nueva cuando lo desees.',
        ], 200);
    }
}
