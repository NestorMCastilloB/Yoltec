<?php

namespace App\Http\Controllers;

use App\Models\PreEvaluacionIA;
use App\Models\Cita;
use App\Services\PreEvaluacionService;
use Illuminate\Http\Request;

class PreEvaluacionIAController extends Controller
{
    public function __construct(private PreEvaluacionService $service) {}

    public function getPreguntas()
    {
        $preguntas = $this->service->getPreguntas();
        if (empty($preguntas)) {
            return response()->json(['message' => 'Configuración no encontrada'], 500);
        }
        return response()->json(['preguntas' => $preguntas]);
    }

    public function store(Request $request)
    {
        $user = $request->user();

        if (!$user->esAlumno()) {
            return response()->json(['message' => 'Solo alumnos pueden crear pre-evaluaciones'], 403);
        }

        $request->validate([
            'cita_id'   => 'required|exists:citas,id',
            'respuestas' => 'required|array',
        ]);

        $cita = Cita::where('id', $request->cita_id)->where('alumno_id', $user->id)->first();
        if (!$cita) {
            return response()->json(['message' => 'Cita no encontrada o no pertenece al alumno'], 404);
        }

        if (PreEvaluacionIA::where('cita_id', $request->cita_id)->exists()) {
            return response()->json(['message' => 'Ya existe una pre-evaluación para esta cita'], 400);
        }

        $resultadoIA = $this->service->callIAPredict($request->respuestas);

        if (!($resultadoIA['success'] ?? false)) {
            return response()->json(['message' => 'Error al procesar la evaluación con IA'], 500);
        }

        $preEvaluacion = PreEvaluacionIA::create([
            'cita_id'              => $request->cita_id,
            'alumno_id'            => $user->id,
            'respuestas'           => $request->respuestas,
            'diagnostico_sugerido' => $resultadoIA['diagnostico_principal'],
            'confianza'            => $resultadoIA['confianza'],
            'sintomas_detectados'  => $resultadoIA['sintomas_detectados'],
            'estatus_validacion'   => 'pendiente',
        ]);

        return response()->json([
            'message'        => 'Pre-evaluación creada exitosamente',
            'pre_evaluacion' => $preEvaluacion,
            'resultado_ia'   => $resultadoIA,
        ], 201);
    }

    public function index(Request $request)
    {
        $user = $request->user();

        $preEvaluaciones = $user->esAlumno()
            ? PreEvaluacionIA::with(['cita', 'doctorValidador'])->where('alumno_id', $user->id)->orderBy('created_at', 'desc')->get()
            : PreEvaluacionIA::with(['cita.alumno', 'alumno'])->orderBy('created_at', 'desc')->get();

        return response()->json(['pre_evaluaciones' => $preEvaluaciones]);
    }

    public function show(Request $request, int $id)
    {
        $user          = $request->user();
        $preEvaluacion = PreEvaluacionIA::with(['cita', 'alumno', 'doctorValidador'])->findOrFail($id);

        if ($user->esAlumno() && $preEvaluacion->alumno_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        return response()->json(['pre_evaluacion' => $preEvaluacion]);
    }

    // Solo doctor — ruta protegida por role:doctor middleware
    public function validar(Request $request, int $id)
    {
        $request->validate([
            'accion'     => 'required|in:validar,descartar',
            'comentario' => 'nullable|string|max:1000',
        ]);

        $preEvaluacion = PreEvaluacionIA::findOrFail($id);
        $estatus = $request->accion === 'validar' ? 'validado' : 'descartado';

        $preEvaluacion->update([
            'estatus_validacion' => $estatus,
            'validado_por'       => $request->user()->id,
            'comentario_doctor'  => $request->comentario,
            'fecha_validacion'   => now(),
        ]);

        $mensaje = $request->accion === 'validar' ? 'Diagnóstico validado exitosamente' : 'Diagnóstico descartado exitosamente';

        return response()->json([
            'message'        => $mensaje,
            'pre_evaluacion' => $preEvaluacion->fresh(['doctorValidador']),
        ]);
    }

    // Solo doctor — ruta protegida por role:doctor middleware
    public function pendientes()
    {
        $pendientes = PreEvaluacionIA::with(['cita.alumno', 'alumno'])
            ->where('estatus_validacion', 'pendiente')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['pendientes' => $pendientes, 'total' => $pendientes->count()]);
    }

    public function chat(Request $request)
    {
        $user = $request->user();

        if (!$user->esAlumno()) {
            return response()->json(['message' => 'Solo alumnos pueden usar la pre-evaluación'], 403);
        }

        $request->validate([
            'cita_id'              => 'required|exists:citas,id',
            'messages'             => 'required|array|min:1',
            'messages.*.role'      => 'required|in:user,assistant',
            'messages.*.content'   => 'required|string|max:2000',
        ]);

        $cita = Cita::where('id', $request->cita_id)->where('alumno_id', $user->id)->first();
        if (!$cita) {
            return response()->json(['message' => 'Cita no encontrada o no pertenece al alumno'], 404);
        }

        try {
            $data = $this->service->callIAChat($request->messages);

            if (!empty($data['finished']) && !empty($data['diagnostico'])) {
                $existe = PreEvaluacionIA::where('cita_id', $request->cita_id)->first();
                $data['pre_evaluacion'] = $existe ?? $this->service->saveFromChat(
                    $request->cita_id,
                    $user->id,
                    $request->messages,
                    $data['diagnostico']
                );
            }

            return response()->json($data);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Servicio IA no disponible: ' . $e->getMessage()], 503);
        }
    }
}
