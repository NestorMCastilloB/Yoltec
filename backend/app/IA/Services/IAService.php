<?php

namespace App\IA\Services;

use App\IA\Data\MedicalDataset;
use App\IA\Models\PriorityClassifier;
use App\Models\Cita;
use App\Models\Bitacora;

/**
 * Clasificador de prioridad de atención (IA 1).
 *
 * La pre-evaluación de síntomas la atiende el microservicio Python
 * (App\Services\PreEvaluacionService), no este servicio.
 */
class IAService
{
    private PriorityClassifier $priorityClassifier;

    public function __construct()
    {
        $this->priorityClassifier = new PriorityClassifier();
        $this->priorityClassifier->entrenar(MedicalDataset::generarDatasetEntrenamiento(500));
    }

    /**
     * IA 1: Clasifica la prioridad de atención de un alumno
     * Solo visible para doctores
     */
    public function clasificarPrioridad(int $citaId): array
    {
        $cita = Cita::with(['alumno', 'bitacora'])->findOrFail($citaId);
        $alumno = $cita->alumno;

        // Obtener historial del alumno
        $historial = $this->obtenerHistorialAlumno($alumno->id);
        
        // Extraer síntomas de la cita actual (si hay motivo o pre-evaluación)
        $sintomasActuales = $this->extraerSintomasDeCita($cita);

        // Datos demográficos
        $datosDemo = [
            'edad' => $alumno->edad ?? $this->calcularEdad($alumno->fecha_nacimiento),
            'sexo' => $alumno->sexo ?? 'N/A',
        ];

        // Clasificar
        $resultado = $this->priorityClassifier->calcularPrioridad(
            $sintomasActuales,
            $historial,
            $datosDemo
        );

        return [
            'cita_id' => $citaId,
            'alumno_id' => $alumno->id,
            'alumno_nombre' => $alumno->name,
            'prioridad' => $resultado['prioridad'],
            'puntuacion' => $resultado['puntuacion'],
            'justificacion' => $resultado['justificacion'],
            'factores' => $resultado['factores'],
            'recomendacion_atencion' => $this->getRecomendacionAtencion($resultado['prioridad']),
            'historial_resumen' => [
                'visitas_ultimo_mes'      => $historial['visitas_ultimo_mes'],
                'condiciones_cronicas'    => $historial['condiciones_cronicas'],
                'ultimo_diagnostico'      => $historial['ultimo_diagnostico'],
                'inasistencias_recientes' => $historial['inasistencias_recientes'],
                'cancelaciones_recientes' => $historial['cancelaciones_recientes'],
            ],
        ];
    }

    /**
     * Obtiene el historial médico completo de un alumno
     */
    private function obtenerHistorialAlumno(int $alumnoId): array
    {
        $mesAtras = now()->subMonth();
        
        // Contar visitas del último mes
        $visitasMes = Cita::where('alumno_id', $alumnoId)
            ->where('created_at', '>=', $mesAtras)
            ->count();

        // Obtener bitácoras recientes
        $bitacorasRecientes = Bitacora::where('alumno_id', $alumnoId)
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get();

        $condicionesCronicas = [];
        $medicamentosActivos = [];
        $ultimoDiagnostico = null;

        foreach ($bitacorasRecientes as $bitacora) {
            // Extraer condiciones del diagnóstico (simulado)
            $diagnosticoLower = strtolower($bitacora->diagnostico);
            
            $condiciones = ['diabetes', 'hipertension', 'asma', 'alergias', 'depresion', 'ansiedad'];
            foreach ($condiciones as $condicion) {
                if (strpos($diagnosticoLower, $condicion) !== false) {
                    $condicionesCronicas[] = $condicion;
                }
            }

            if (!$ultimoDiagnostico) {
                $ultimoDiagnostico = $bitacora->diagnostico;
            }
        }

        // Obtener recetas activas (últimas 30 días)
        $recetasRecientes = \App\Models\Receta::where('alumno_id', $alumnoId)
            ->where('created_at', '>=', $mesAtras)
            ->get();

        foreach ($recetasRecientes as $receta) {
            $medicamentos = explode(',', $receta->medicamentos);
            foreach ($medicamentos as $med) {
                $medicamentosActivos[] = trim($med);
            }
        }

        // Inasistencias y cancelaciones (últimos 3 meses)
        $tresMesesAtras = now()->subMonths(3);
        $inasistencias = Cita::where('alumno_id', $alumnoId)
            ->where('estatus', 'no_asistio')
            ->where('updated_at', '>=', $tresMesesAtras)
            ->count();

        $cancelaciones = Cita::where('alumno_id', $alumnoId)
            ->where('estatus', 'cancelada')
            ->where('updated_at', '>=', $tresMesesAtras)
            ->count();

        return [
            'visitas_ultimo_mes'      => $visitasMes,
            'condiciones_cronicas'    => array_unique($condicionesCronicas),
            'medicamentos_activos'    => array_unique($medicamentosActivos),
            'ultimo_diagnostico'      => $ultimoDiagnostico,
            'total_historial'         => Bitacora::where('alumno_id', $alumnoId)->count(),
            'inasistencias_recientes' => $inasistencias,
            'cancelaciones_recientes' => $cancelaciones,
        ];
    }

    /**
     * Extrae síntomas del motivo de la cita y pre-evaluación previa
     */
    private function extraerSintomasDeCita(Cita $cita): array
    {
        $sintomas = [];
        
        if ($cita->motivo) {
            $sintomas = array_merge($sintomas, $this->parsearSintomasDeTexto($cita->motivo));
        }

        // Buscar pre-evaluación previa
        $preEvaluacion = \App\Models\PreEvaluacionIA::where('cita_id', $cita->id)->first();
        if ($preEvaluacion && $preEvaluacion->sintomas_detectados) {
            $sintomas = array_merge($sintomas, $preEvaluacion->sintomas_detectados);
        }

        return array_unique($sintomas);
    }

    /**
     * Parsea síntomas de texto libre usando el dataset
     */
    private function parsearSintomasDeTexto(string $texto): array
    {
        $sintomasEncontrados = [];
        $textoLower = strtolower($texto);
        
        $enfermedades = MedicalDataset::getEnfermedades();
        $todosSintomas = [];
        
        // Recopilar todos los síntomas del dataset
        foreach ($enfermedades as $enf) {
            $todosSintomas = array_merge($todosSintomas, array_keys($enf['sintomas']));
        }
        $todosSintomas = array_unique($todosSintomas);

        // Buscar coincidencias
        foreach ($todosSintomas as $sintoma) {
            $sintomaLegible = str_replace('_', ' ', $sintoma);
            if (strpos($textoLower, $sintomaLegible) !== false || 
                strpos($textoLower, $sintoma) !== false) {
                $sintomasEncontrados[] = $sintoma;
            }
        }

        // Palabras clave adicionales comunes
        $palabrasClave = [
            'fiebre' => 'fiebre',
            'tos' => 'tos',
            'dolor de cabeza' => 'dolor_cabeza',
            'dolor de estómago' => 'dolor_abdominal',
            'gripe' => 'fiebre',
            'resfriado' => 'congestion_nasal',
            'mareo' => 'mareo',
            'nausea' => 'nauseas',
            'vomito' => 'vomito',
        ];

        foreach ($palabrasClave as $palabra => $sintoma) {
            if (strpos($textoLower, $palabra) !== false && !in_array($sintoma, $sintomasEncontrados)) {
                $sintomasEncontrados[] = $sintoma;
            }
        }

        return $sintomasEncontrados;
    }

    /**
     * Obtiene recomendación de atención según prioridad
     */
    private function getRecomendacionAtencion(string $prioridad): array
    {
        return match($prioridad) {
            'alta' => [
                'mensaje' => 'Atención inmediata recomendada',
                'tiempo_maximo' => '15 minutos',
                'accion' => 'Atender lo antes posible',
                'color' => 'red',
            ],
            'media' => [
                'mensaje' => 'Atención en el día',
                'tiempo_maximo' => '2 horas',
                'accion' => 'Programar para hoy',
                'color' => 'yellow',
            ],
            'baja' => [
                'mensaje' => 'Atención rutinaria',
                'tiempo_maximo' => 'Horario normal',
                'accion' => 'Turno regular',
                'color' => 'green',
            ],
        };
    }

    /**
     * Calcula edad a partir de fecha de nacimiento
     */
    private function calcularEdad(?string $fechaNacimiento): ?int
    {
        if (!$fechaNacimiento) return null;
        return now()->diffInYears($fechaNacimiento);
    }

    /**
     * Carga modelos existentes o entrena nuevos
     */
    /**
     * Re-entrena el clasificador sobre un dataset nuevo y lo evalúa.
     * Los pesos viven en memoria: no se persisten entre peticiones.
     */
    public function reentrenarModelos(): array
    {
        $dataset = MedicalDataset::generarDatasetEntrenamiento(1000);

        // Dividir en entrenamiento y prueba
        shuffle($dataset);
        $mitad = count($dataset) / 2;
        $entrenamiento = array_slice($dataset, 0, $mitad);
        $prueba = array_slice($dataset, $mitad);

        $this->priorityClassifier->entrenar($entrenamiento);

        return [
            'priority_classifier' => $this->priorityClassifier->evaluar($prueba),
            'timestamp' => now()->toDateTimeString(),
        ];
    }

    /**
     * Obtiene información del modelo
     */
    public function getInfoModelos(): array
    {
        return [
            'priority_classifier' => $this->priorityClassifier->getConfig(),
            'dataset_enfermedades' => count(MedicalDataset::getEnfermedades()),
        ];
    }
}
