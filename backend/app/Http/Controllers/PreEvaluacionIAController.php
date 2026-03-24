<?php

namespace App\Http\Controllers;

use App\Models\PreEvaluacionIA;
use App\Models\Cita;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Http;

class PreEvaluacionIAController extends Controller
{
    /**
     * Obtener preguntas para la pre-evaluación
     */
    public function getPreguntas()
    {
        $configPath = base_path('../IA/enfermedades_config.json');
        
        if (!file_exists($configPath)) {
            return response()->json([
                'message' => 'Configuración no encontrada'
            ], 500);
        }
        
        $config = json_decode(file_get_contents($configPath), true);
        
        return response()->json([
            'preguntas' => $config['preguntas'] ?? []
        ]);
    }

    /**
     * Crear una nueva pre-evaluación IA (alumno)
     */
    public function store(Request $request)
    {
        $user = $request->user();
        
        // Solo alumnos pueden crear pre-evaluaciones
        if (!$user->esAlumno()) {
            return response()->json(['message' => 'Solo alumnos pueden crear pre-evaluaciones'], 403);
        }
        
        $validator = Validator::make($request->all(), [
            'cita_id' => 'required|exists:citas,id',
            'respuestas' => 'required|array',
        ]);
        
        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }
        
        // Verificar que la cita pertenece al alumno
        $cita = Cita::where('id', $request->cita_id)
                    ->where('alumno_id', $user->id)
                    ->first();
        
        if (!$cita) {
            return response()->json(['message' => 'Cita no encontrada o no pertenece al alumno'], 404);
        }
        
        // Verificar que no existe pre-evaluación previa para esta cita
        $existe = PreEvaluacionIA::where('cita_id', $request->cita_id)->exists();
        if ($existe) {
            return response()->json(['message' => 'Ya existe una pre-evaluación para esta cita'], 400);
        }
        
        // Procesar con IA
        $resultadoIA = $this->procesarConIA($request->respuestas);
        
        if (!$resultadoIA['success']) {
            return response()->json([
                'message' => 'Error al procesar la evaluación con IA',
                'error' => $resultadoIA['error'] ?? 'Error desconocido'
            ], 500);
        }
        
        // Crear registro
        $preEvaluacion = PreEvaluacionIA::create([
            'cita_id' => $request->cita_id,
            'alumno_id' => $user->id,
            'respuestas' => $request->respuestas,
            'diagnostico_sugerido' => $resultadoIA['diagnostico_principal'],
            'confianza' => $resultadoIA['confianza'],
            'sintomas_detectados' => $resultadoIA['sintomas_detectados'],
            'estatus_validacion' => 'pendiente',
        ]);
        
        return response()->json([
            'message' => 'Pre-evaluación creada exitosamente',
            'pre_evaluacion' => $preEvaluacion,
            'resultado_ia' => $resultadoIA
        ], 201);
    }

    /**
     * Ver pre-evaluaciones del alumno
     */
    public function index(Request $request)
    {
        $user = $request->user();
        
        if ($user->esAlumno()) {
            $preEvaluaciones = PreEvaluacionIA::with(['cita', 'doctorValidador'])
                ->where('alumno_id', $user->id)
                ->orderBy('created_at', 'desc')
                ->get();
        } else {
            // Doctores ven todas las pendientes y las de sus citas
            $preEvaluaciones = PreEvaluacionIA::with(['cita.alumno', 'alumno'])
                ->orderBy('created_at', 'desc')
                ->get();
        }
        
        return response()->json([
            'pre_evaluaciones' => $preEvaluaciones
        ]);
    }

    /**
     * Ver una pre-evaluación específica
     */
    public function show(Request $request, $id)
    {
        $user = $request->user();
        
        $preEvaluacion = PreEvaluacionIA::with(['cita', 'alumno', 'doctorValidador'])->findOrFail($id);
        
        // Verificar permisos
        if ($user->esAlumno() && $preEvaluacion->alumno_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }
        
        return response()->json([
            'pre_evaluacion' => $preEvaluacion
        ]);
    }

    /**
     * Validar o descartar diagnóstico IA (solo doctores)
     */
    public function validar(Request $request, $id)
    {
        $user = $request->user();
        
        // Solo doctores pueden validar
        if (!$user->esDoctor() && !$user->esAdmin()) {
            return response()->json(['message' => 'Solo doctores pueden validar diagnósticos'], 403);
        }
        
        $validator = Validator::make($request->all(), [
            'accion' => 'required|in:validar,descartar',
            'comentario' => 'nullable|string|max:1000',
        ]);
        
        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }
        
        $preEvaluacion = PreEvaluacionIA::findOrFail($id);
        
        $estatus = $request->accion === 'validar' ? 'validado' : 'descartado';
        
        $preEvaluacion->update([
            'estatus_validacion' => $estatus,
            'validado_por' => $user->id,
            'comentario_doctor' => $request->comentario,
            'fecha_validacion' => now(),
        ]);
        
        $mensaje = $request->accion === 'validar' 
            ? 'Diagnóstico validado exitosamente' 
            : 'Diagnóstico descartado exitosamente';
        
        return response()->json([
            'message' => $mensaje,
            'pre_evaluacion' => $preEvaluacion->fresh(['doctorValidador'])
        ]);
    }

    /**
     * Obtener pre-evaluaciones pendientes (para doctores)
     */
    public function pendientes(Request $request)
    {
        $user = $request->user();
        
        if (!$user->esDoctor() && !$user->esAdmin()) {
            return response()->json(['message' => 'No autorizado'], 403);
        }
        
        $pendientes = PreEvaluacionIA::with(['cita.alumno', 'alumno'])
            ->where('estatus_validacion', 'pendiente')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'pendientes' => $pendientes,
            'total' => $pendientes->count(),
        ]);
    }

    /**
     * Procesar respuestas con IA via microservicio HTTP
     */
    private function procesarConIA(array $respuestas): array
    {
        try {
            $iaUrl = env('IA_SERVICE_URL', 'http://ia:5000');

            $response = Http::timeout(15)->post("{$iaUrl}/predict", [
                'respuestas' => $respuestas,
            ]);

            if ($response->successful()) {
                return $response->json();
            }

            \Log::error('IA service error: ' . $response->body());
            return $this->simularRespuestaIA($respuestas);

        } catch (\Exception $e) {
            \Log::warning('IA service no disponible, usando fallback: ' . $e->getMessage());
            return $this->simularRespuestaIA($respuestas);
        }
    }

    /**
     * Simular respuesta IA cuando el script no está disponible
     */
    private function simularRespuestaIA(array $respuestas): array
    {
        // Lógica simple de fallback
        $tieneFiebre = isset($respuestas['fiebre']) && !str_contains($respuestas['fiebre'], 'No');
        $tieneTos = isset($respuestas['tos']) && !str_contains($respuestas['tos'], 'No');
        $tieneDolorCabeza = isset($respuestas['dolor_cabeza']) && !str_contains($respuestas['dolor_cabeza'], 'No');
        $tieneCongestion = isset($respuestas['congestion_nasal']) && !str_contains($respuestas['congestion_nasal'], 'No');
        $tieneNauseas = isset($respuestas['nauseas']) && !str_contains($respuestas['nauseas'], 'No');
        
        if ($tieneFiebre && $tieneTos && $tieneDolorCabeza) {
            return [
                'success' => true,
                'diagnostico_principal' => 'Gripe',
                'confianza' => 0.75,
                'sintomas_detectados' => ['Fiebre', 'Tos', 'Dolor de cabeza'],
                'posibles_enfermedades' => [
                    ['enfermedad' => 'Gripe', 'confianza' => 0.75],
                    ['enfermedad' => 'Resfriado Común', 'confianza' => 0.45],
                ],
                'recomendacion' => 'Probabilidad moderada de Gripe. Se recomienda consulta médica.'
            ];
        } elseif ($tieneCongestion && $tieneTos) {
            return [
                'success' => true,
                'diagnostico_principal' => 'Resfriado Común',
                'confianza' => 0.65,
                'sintomas_detectados' => ['Congestión nasal', 'Tos'],
                'posibles_enfermedades' => [
                    ['enfermedad' => 'Resfriado Común', 'confianza' => 0.65],
                    ['enfermedad' => 'Alergias', 'confianza' => 0.40],
                ],
                'recomendacion' => 'Posible Resfriado Común. Monitorear síntomas.'
            ];
        } elseif ($tieneNauseas) {
            return [
                'success' => true,
                'diagnostico_principal' => 'Infección Gastrointestinal',
                'confianza' => 0.55,
                'sintomas_detectados' => ['Náuseas'],
                'posibles_enfermedades' => [
                    ['enfermedad' => 'Infección Gastrointestinal', 'confianza' => 0.55],
                ],
                'recomendacion' => 'Síntomas no concluyentes. Se recomienda consulta médica.'
            ];
        }
        
        return [
            'success' => true,
            'diagnostico_principal' => 'Sin diagnóstico claro',
            'confianza' => 0.20,
            'sintomas_detectados' => [],
            'posibles_enfermedades' => [],
            'recomendacion' => 'Los síntomas no son concluyentes. Se recomienda consulta médica.'
        ];
    }
}
