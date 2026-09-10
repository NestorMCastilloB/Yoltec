<?php

namespace App\IA\Services;

use App\IA\Data\MedicalDataset;
use App\IA\Models\PriorityClassifier;
use App\Models\Cita;
use App\Models\Bitacora;
use App\Models\Receta;
use App\Models\PreEvaluacionIA;
use Illuminate\Support\Collection;

/**
 * Clasificador de prioridad de atención (IA 1).
 *
 * La pre-evaluación de síntomas la atiende el microservicio Python
 * (App\Services\PreEvaluacionService), no este servicio.
 */
class IAService
{
    private PriorityClassifier $priorityClassifier;

    /** Historiales ya calculados, indexados por alumno_id (ver precargar()). */
    private array $historialCache = [];

    /** Síntomas de pre-evaluación ya cargados, indexados por cita_id. */
    private array $preEvalCache = [];

    public function __construct()
    {
        // El clasificador usa pesos y umbrales fijos basados en conocimiento
        // médico. A propósito NO se llama a entrenar() aquí: entrenaba sobre un
        // dataset generado con rand() en cada petición, lo que (a) montaba 500
        // muestras sintéticas por request —CPU desperdiciada en el plan gratuito—
        // y (b) movía el umbral de prioridad 'alta' según el % de "altas" de ese
        // sorteo aleatorio, de modo que una misma cita podía clasificarse distinto
        // de una llamada a otra. Con los umbrales fijos la clasificación es
        // reproducible, que es lo que se espera de una herramienta de apoyo médico.
        $this->priorityClassifier = new PriorityClassifier();
    }

    /**
     * IA 1: Clasifica la prioridad de atención de un alumno
     * Solo visible para doctores
     */
    public function clasificarPrioridad(int $citaId): array
    {
        $cita = Cita::with(['alumno', 'bitacora'])->findOrFail($citaId);
        return $this->clasificarPrioridadDeCita($cita);
    }

    /**
     * Igual que clasificarPrioridad() pero partiendo de una Cita ya cargada.
     * Lo usa el listado por prioridad, que precarga las citas y sus datos en
     * bloque (ver precargar()) para no repetir consultas por cada cita.
     */
    public function clasificarPrioridadDeCita(Cita $cita): array
    {
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
            'cita_id' => $cita->id,
            'alumno_id' => $alumno->id,
            'alumno_nombre' => trim(($alumno->nombre ?? '') . ' ' . ($alumno->apellido ?? '')) ?: 'Sin nombre',
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
     * Precarga en pocas consultas agrupadas el historial y las pre-evaluaciones
     * de todas las citas de un listado. Sin esto, clasificar N citas disparaba
     * ~7 consultas por cada una (N+1); con esto son un puñado en total.
     */
    public function precargar(Collection $citas): void
    {
        $alumnoIds = $citas->pluck('alumno_id')->filter()->unique()->values()->all();
        $citaIds   = $citas->pluck('id')->filter()->unique()->values()->all();

        if (!empty($alumnoIds)) {
            $mesAtras       = now()->subMonth();
            $tresMesesAtras = now()->subMonths(3);

            $visitas = Cita::whereIn('alumno_id', $alumnoIds)
                ->where('created_at', '>=', $mesAtras)
                ->groupBy('alumno_id')->selectRaw('alumno_id, count(*) as total')
                ->pluck('total', 'alumno_id');

            $inasistencias = Cita::whereIn('alumno_id', $alumnoIds)
                ->where('estatus', 'no_asistio')->where('updated_at', '>=', $tresMesesAtras)
                ->groupBy('alumno_id')->selectRaw('alumno_id, count(*) as total')
                ->pluck('total', 'alumno_id');

            $cancelaciones = Cita::whereIn('alumno_id', $alumnoIds)
                ->where('estatus', 'cancelada')->where('updated_at', '>=', $tresMesesAtras)
                ->groupBy('alumno_id')->selectRaw('alumno_id, count(*) as total')
                ->pluck('total', 'alumno_id');

            // Todas las bitácoras de estos alumnos en una consulta; se agrupan y
            // se recortan a las 5 recientes por alumno en memoria.
            $bitacorasPorAlumno = Bitacora::whereIn('alumno_id', $alumnoIds)
                ->orderBy('created_at', 'desc')->get()->groupBy('alumno_id');

            $totalBitacoras = Bitacora::whereIn('alumno_id', $alumnoIds)
                ->groupBy('alumno_id')->selectRaw('alumno_id, count(*) as total')
                ->pluck('total', 'alumno_id');

            $recetasPorAlumno = Receta::whereIn('alumno_id', $alumnoIds)
                ->where('created_at', '>=', $mesAtras)->get()->groupBy('alumno_id');

            foreach ($alumnoIds as $id) {
                $this->historialCache[$id] = $this->armarHistorial(
                    (int) ($visitas[$id] ?? 0),
                    ($bitacorasPorAlumno[$id] ?? collect())->take(5),
                    $recetasPorAlumno[$id] ?? collect(),
                    (int) ($totalBitacoras[$id] ?? 0),
                    (int) ($inasistencias[$id] ?? 0),
                    (int) ($cancelaciones[$id] ?? 0),
                );
            }
        }

        if (!empty($citaIds)) {
            foreach (PreEvaluacionIA::whereIn('cita_id', $citaIds)->get() as $pe) {
                $this->preEvalCache[$pe->cita_id] = $pe->sintomas_detectados ?: [];
            }
        }
    }

    /**
     * Historial médico de un alumno. Si se precargó en bloque, sale de la caché;
     * si no, se calcula con sus consultas (camino de una sola cita).
     */
    private function obtenerHistorialAlumno(int $alumnoId): array
    {
        if (isset($this->historialCache[$alumnoId])) {
            return $this->historialCache[$alumnoId];
        }

        $mesAtras       = now()->subMonth();
        $tresMesesAtras = now()->subMonths(3);

        return $this->historialCache[$alumnoId] = $this->armarHistorial(
            Cita::where('alumno_id', $alumnoId)->where('created_at', '>=', $mesAtras)->count(),
            Bitacora::where('alumno_id', $alumnoId)->orderBy('created_at', 'desc')->limit(5)->get(),
            Receta::where('alumno_id', $alumnoId)->where('created_at', '>=', $mesAtras)->get(),
            Bitacora::where('alumno_id', $alumnoId)->count(),
            Cita::where('alumno_id', $alumnoId)->where('estatus', 'no_asistio')->where('updated_at', '>=', $tresMesesAtras)->count(),
            Cita::where('alumno_id', $alumnoId)->where('estatus', 'cancelada')->where('updated_at', '>=', $tresMesesAtras)->count(),
        );
    }

    /**
     * Arma el arreglo de historial a partir de datos ya cargados. Lo comparten
     * el camino de una sola cita y el precargado en bloque, para que el cálculo
     * sea idéntico en ambos.
     */
    private function armarHistorial(
        int $visitasMes,
        Collection $bitacorasRecientes,
        Collection $recetasRecientes,
        int $totalBitacoras,
        int $inasistencias,
        int $cancelaciones
    ): array {
        $condicionesCronicas = [];
        $ultimoDiagnostico   = null;

        foreach ($bitacorasRecientes as $bitacora) {
            $diagnosticoLower = strtolower((string) $bitacora->diagnostico);
            foreach (['diabetes', 'hipertension', 'asma', 'alergias', 'depresion', 'ansiedad'] as $condicion) {
                if (strpos($diagnosticoLower, $condicion) !== false) {
                    $condicionesCronicas[] = $condicion;
                }
            }
            if (!$ultimoDiagnostico) {
                $ultimoDiagnostico = $bitacora->diagnostico;
            }
        }

        $medicamentosActivos = [];
        foreach ($recetasRecientes as $receta) {
            foreach (explode(',', (string) $receta->medicamentos) as $med) {
                $medicamentosActivos[] = trim($med);
            }
        }

        return [
            'visitas_ultimo_mes'      => $visitasMes,
            'condiciones_cronicas'    => array_unique($condicionesCronicas),
            'medicamentos_activos'    => array_unique($medicamentosActivos),
            'ultimo_diagnostico'      => $ultimoDiagnostico,
            'total_historial'         => $totalBitacoras,
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

        // Síntomas de la pre-evaluación previa (de la caché si se precargó en
        // bloque; si no, se consulta la de esta cita).
        $detectados = array_key_exists($cita->id, $this->preEvalCache)
            ? $this->preEvalCache[$cita->id]
            : (PreEvaluacionIA::where('cita_id', $cita->id)->first()?->sintomas_detectados ?? []);

        if (!empty($detectados)) {
            $sintomas = array_merge($sintomas, $detectados);
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
