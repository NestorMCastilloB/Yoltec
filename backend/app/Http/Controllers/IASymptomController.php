<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\IA\Services\IAService;
use App\Models\Cita;
use App\Models\PreEvaluacionIA;
use Illuminate\Http\Request;

class IASymptomController extends Controller
{
    private IAService $iaService;

    public function __construct()
    {
        $this->iaService = new IAService();
    }

    // POST /api/ia/symptoms/iniciar/{citaId}
    public function iniciar(Request $request, int $citaId)
    {
        $user = $request->user();
        $cita = Cita::findOrFail($citaId);

        if ($user->esAlumno() && $cita->alumno_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        if ($cita->estatus !== 'programada') {
            return response()->json(['message' => 'No se puede hacer pre-evaluación. La cita no está programada.'], 400);
        }

        return response()->json($this->iaService->iniciarPreEvaluacion($citaId));
    }

    // POST /api/ia/symptoms/evaluar/{citaId}
    public function evaluar(Request $request, int $citaId)
    {
        $user = $request->user();
        $cita = Cita::findOrFail($citaId);

        if ($user->esAlumno() && $cita->alumno_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $validated = $request->validate([
            'respuestas'                       => 'required|array',
            'respuestas.*.pregunta_id'         => 'nullable|integer',
            'respuestas.*.sintoma_relacionado' => 'nullable|string',
            'respuestas.*.respuesta'           => 'required|string',
        ]);

        return response()->json(
            $this->iaService->procesarRespuestasPreEvaluacion($citaId, $validated['respuestas'])
        );
    }

    // GET /api/ia/symptoms/resultado/{citaId}
    public function obtenerResultado(Request $request, int $citaId)
    {
        $user = $request->user();
        $cita = Cita::findOrFail($citaId);

        if ($user->esAlumno() && $cita->alumno_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $pre = PreEvaluacionIA::where('cita_id', $citaId)->first();
        if (!$pre) {
            return response()->json(['message' => 'No hay pre-evaluación registrada para esta cita'], 404);
        }

        if ($user->esDoctor()) {
            return response()->json([
                'cita_id'               => $citaId,
                'alumno'                => ['id' => $cita->alumno->id, 'nombre' => $cita->alumno->nombre],
                'pre_evaluacion'        => $pre,
                'sintomas_detectados'   => $pre->sintomas_detectados,
                'posibles_diagnosticos' => $pre->posibles_enfermedades,
                'confianza_ia'          => $pre->confianza,
                'respuestas_brutas'     => $pre->respuestas,
                'validado_por_doctor'   => $pre->doctorValidador
                    ? ['id' => $pre->doctorValidador->id, 'nombre' => $pre->doctorValidador->nombre]
                    : null,
            ]);
        }

        return response()->json([
            'cita_id'           => $citaId,
            'sintomas_reportados' => $pre->sintomas_detectados,
            'posibles_causas'   => array_slice($pre->posibles_enfermedades ?? [], 0, 3),
            'mensaje'           => 'Recuerda: solo el doctor puede dar un diagnóstico oficial.',
        ]);
    }

    // POST /api/ia/symptoms/validar/{preEvaluacionId} — solo doctor (role:doctor middleware)
    public function validar(Request $request, int $preEvaluacionId)
    {
        $validated = $request->validate([
            'diagnostico_correcto' => 'nullable|string',
            'es_acertado'          => 'required|boolean',
            'observaciones'        => 'nullable|string',
        ]);

        $pre = PreEvaluacionIA::findOrFail($preEvaluacionId);
        $pre->update([
            'es_acertado'           => $validated['es_acertado'],
            'diagnostico_correcto'  => $validated['diagnostico_correcto'],
            'observaciones_doctor'  => $validated['observaciones'],
            'validado_por'          => $request->user()->id,
            'fecha_validacion'      => now(),
        ]);

        return response()->json(['message' => 'Pre-evaluación validada correctamente', 'pre_evaluacion' => $pre]);
    }

    // GET /api/ia/symptoms/listado — solo doctor (role:doctor middleware)
    public function listado()
    {
        $preEvaluaciones = PreEvaluacionIA::with(['cita', 'alumno', 'doctorValidador'])
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json(['message' => 'Listado de pre-evaluaciones', 'data' => $preEvaluaciones]);
    }

    // DELETE /api/ia/symptoms/{citaId}
    public function cancelar(Request $request, int $citaId)
    {
        $user = $request->user();
        $cita = Cita::findOrFail($citaId);

        if ($user->esAlumno() && $cita->alumno_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        PreEvaluacionIA::where('cita_id', $citaId)->delete();
        return response()->json(['message' => 'Pre-evaluación cancelada. Puedes iniciar una nueva cuando lo desees.']);
    }
}
