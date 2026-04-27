<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\IA\Services\IAService;
use App\Models\Cita;
use App\Models\PreEvaluacionIA;
use Illuminate\Http\Request;

/**
 * Controlador para la IA 1: Clasificador de Prioridad
 * Solo accesible por doctores
 */
class IAPriorityController extends Controller
{
    private IAService $iaService;

    public function __construct()
    {
        $this->iaService = new IAService();
    }

    /**
     * Clasifica la prioridad de una cita específica
     * POST /api/ia/priority/clasificar/{citaId}
     */
    public function clasificar(Request $request, int $citaId)
    {
        $user = $request->user();

        // Solo doctores pueden ver prioridades
        if (!$user->esDoctor()) {
            return response()->json([
                'message' => 'No autorizado. Solo doctores pueden ver clasificaciones de prioridad.'
            ], 403);
        }

        $cita = Cita::findOrFail($citaId);

        // Ejecutar clasificación
        $resultado = $this->iaService->clasificarPrioridad($citaId);

        // Guardar resultado en bitácora o log para auditoría (opcional)
        // \App\Models\IALog::create([...]);

        return response()->json([
            'message' => 'Clasificación de prioridad completada',
            'cita' => [
                'id' => $cita->id,
                'clave_cita' => $cita->clave_cita,
                'motivo' => $cita->motivo,
            ],
            'clasificacion_ia' => [
                'nivel_prioridad' => $resultado['prioridad'],
                'puntuacion' => $resultado['puntuacion'],
                'justificacion' => $resultado['justificacion'],
                'factores_considerados' => $resultado['factores'],
            ],
            'recomendacion' => $resultado['recomendacion_atencion'],
            'historial_alumno' => $resultado['historial_resumen'],
            'advertencia' => 'Esta clasificación es una herramienta de apoyo. La decisión final es del doctor.',
        ], 200);
    }

    /**
     * Lista todas las citas pendientes clasificadas por prioridad
     * GET /api/ia/priority/pendientes
     */
    public function listarPendientesPorPrioridad(Request $request)
    {
        $user = $request->user();

        if (!$user->esDoctor()) {
            return response()->json([
                'message' => 'No autorizado'
            ], 403);
        }

        // Obtener citas programadas
        $citas = Cita::where('estatus', 'programada')
            ->with('alumno')
            ->orderBy('fecha_cita')
            ->orderBy('hora_cita')
            ->get();

        // Clasificar cada una
        $clasificadas = [];
        foreach ($citas as $cita) {
            try {
                $resultado = $this->iaService->clasificarPrioridad($cita->id);
                $clasificadas[] = [
                    'cita' => [
                        'id' => $cita->id,
                        'clave_cita' => $cita->clave_cita,
                        'fecha_cita' => $cita->fecha_cita,
                        'hora_cita' => $cita->hora_cita,
                        'motivo' => $cita->motivo,
                        'alumno' => [
                            'id' => $cita->alumno->id,
                            'nombre' => trim(($cita->alumno->nombre ?? '') . ' ' . ($cita->alumno->apellido ?? '')) ?: ($cita->alumno->name ?? 'Sin nombre'),
                            'numero_control' => $cita->alumno->numero_control,
                        ],
                    ],
                    'prioridad' => $resultado['prioridad'],
                    'puntuacion' => $resultado['puntuacion'],
                    'justificacion_resumida' => substr($resultado['justificacion'], 0, 100) . '...',
                    'justificacion' => $resultado['justificacion'],
                    'factores' => $resultado['factores'] ?? [],
                ];
            } catch (\Exception $e) {
                // Si falla la clasificación de una, continuar con las demás
                continue;
            }
        }

        // Ordenar por prioridad y puntuación
        usort($clasificadas, function ($a, $b) {
            $orden = ['alta' => 3, 'media' => 2, 'baja' => 1];
            if ($orden[$a['prioridad']] !== $orden[$b['prioridad']]) {
                return $orden[$b['prioridad']] <=> $orden[$a['prioridad']];
            }
            return $b['puntuacion'] <=> $a['puntuacion'];
        });

        // Agrupar por prioridad
        $agrupadas = [
            'alta' => array_filter($clasificadas, fn($c) => $c['prioridad'] === 'alta'),
            'media' => array_filter($clasificadas, fn($c) => $c['prioridad'] === 'media'),
            'baja' => array_filter($clasificadas, fn($c) => $c['prioridad'] === 'baja'),
        ];

        return response()->json([
            'message' => 'Citas clasificadas por prioridad',
            'total_citas' => count($clasificadas),
            'resumen' => [
                'alta' => count($agrupadas['alta']),
                'media' => count($agrupadas['media']),
                'baja' => count($agrupadas['baja']),
            ],
            'citas' => $clasificadas,
            'agrupadas_por_prioridad' => $agrupadas,
        ], 200);
    }

    /**
     * Obtiene información de los modelos de IA
     * GET /api/ia/priority/info
     */
    public function infoModelos(Request $request)
    {
        $user = $request->user();

        if (!$user->esDoctor()) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $info = $this->iaService->getInfoModelos();

        return response()->json([
            'message' => 'Información de los modelos de IA',
            'modelos' => $info,
        ], 200);
    }
}
