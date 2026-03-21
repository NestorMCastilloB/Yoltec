<?php

namespace App\IA\Services;

use App\IA\Data\MedicalDataset;
use App\IA\Models\NaiveBayesClassifier;
use App\IA\Models\PriorityClassifier;
use App\Models\Cita;
use App\Models\User;
use App\Models\Bitacora;
use Illuminate\Support\Facades\Storage;

/**
 * Servicio principal que gestiona ambas IA del sistema
 */
class IAService
{
    private NaiveBayesClassifier $symptomClassifier;
    private PriorityClassifier $priorityClassifier;
    private string $modelPath;

    public function __construct()
    {
        $this->symptomClassifier = new NaiveBayesClassifier();
        $this->priorityClassifier = new PriorityClassifier();
        $this->modelPath = storage_path('app/ia_models');
        
        // Crear directorio si no existe
        if (!is_dir($this->modelPath)) {
            mkdir($this->modelPath, 0755, true);
        }

        // Intentar cargar modelo existente o entrenar nuevo
        $this->cargarOEntrenarModelos();
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
                'visitas_ultimo_mes' => $historial['visitas_ultimo_mes'],
                'condiciones_cronicas' => $historial['condiciones_cronicas'],
                'ultimo_diagnostico' => $historial['ultimo_diagnostico'],
            ],
        ];
    }

    /**
     * IA 2: Realiza pre-evaluación de síntomas después de agendar cita
     * Interactivo con el alumno
     */
    public function iniciarPreEvaluacion(int $citaId): array
    {
        $cita = Cita::with('alumno')->findOrFail($citaId);
        $enfermedades = MedicalDataset::getEnfermedades();

        // Seleccionar preguntas iniciales basadas en el motivo de la cita
        $preguntasIniciales = $this->seleccionarPreguntasIniciales($cita->motivo, $enfermedades);

        return [
            'cita_id' => $citaId,
            'fase' => 'inicio',
            'mensaje_bienvenida' => 'Vamos a hacer algunas preguntas para entender mejor tu situación antes de tu cita.',
            'preguntas' => $preguntasIniciales,
            'total_preguntas_estimadas' => 4,
            'instrucciones' => 'Responde "si", "no" o describe tus síntomas brevemente.',
        ];
    }

    /**
     * Procesa las respuestas del alumno y genera diagnóstico preliminar
     */
    public function procesarRespuestasPreEvaluacion(int $citaId, array $respuestas): array
    {
        // Extraer síntomas confirmados de las respuestas
        $sintomasConfirmados = $this->extraerSintomasDeRespuestas($respuestas);

        // Si hay muy pocos síntomas, pedir más información
        if (count($sintomasConfirmados) < 2) {
            $preguntasAdicionales = $this->generarPreguntasAdicionales($sintomasConfirmados);
            
            return [
                'cita_id' => $citaId,
                'fase' => 'preguntas_adicionales',
                'preguntas' => $preguntasAdicionales,
                'mensaje' => 'Necesitamos un poco más de información para ayudarte mejor.',
            ];
        }

        // Clasificar síntomas
        $predicciones = $this->symptomClassifier->predecir($sintomasConfirmados, 5);
        $enfermedades = MedicalDataset::getEnfermedades();

        // Formatear resultados
        $posiblesEnfermedades = [];
        foreach ($predicciones as $enfermedadKey => $probabilidad) {
            if (isset($enfermedades[$enfermedadKey])) {
                $enfermedad = $enfermedades[$enfermedadKey];
                $posiblesEnfermedades[] = [
                    'enfermedad_key' => $enfermedadKey,
                    'nombre' => $enfermedad['nombre'],
                    'categoria' => $enfermedad['categoria'],
                    'probabilidad' => round($probabilidad * 100, 2),
                    'frecuencia' => $enfermedad['frecuencia'],
                    'sintomas_coincidentes' => array_intersect(
                        array_keys($enfermedad['sintomas']), 
                        $sintomasConfirmados
                    ),
                ];
            }
        }

        // Ordenar por probabilidad y priorizar las más comunes
        usort($posiblesEnfermedades, function($a, $b) {
            $pesoA = $this->calcularPesoPrioridad($a);
            $pesoB = $this->calcularPesoPrioridad($b);
            return $pesoB <=> $pesoA;
        });

        // Guardar en base de datos (PreEvaluacionIA ya existe)
        $this->guardarPreEvaluacion($citaId, $respuestas, $posiblesEnfermedades, $sintomasConfirmados);

        return [
            'cita_id' => $citaId,
            'fase' => 'completado',
            'sintomas_reportados' => $sintomasConfirmados,
            'posibles_causas' => array_slice($posiblesEnfermedades, 0, 3),
            'todas_las_opciones' => $posiblesEnfermedades,
            'mensaje_alerta' => '⚠️ Este es solo un análisis preliminar. El doctor te dará el diagnóstico final.',
            'recomendaciones_mientras_tanto' => $this->generarRecomendacionesTemporales(
                $posiblesEnfermedades[0]['enfermedad_key'] ?? null
            ),
        ];
    }

    /**
     * Genera preguntas dinámicas basadas en síntomas ya reportados
     */
    private function generarPreguntasAdicionales(array $sintomasActuales): array
    {
        $enfermedades = MedicalDataset::getEnfermedades();
        $preguntas = [];

        // Encontrar enfermedades que podrían coincidir parcialmente
        foreach ($enfermedades as $key => $enf) {
            $sintomasEnfermedad = array_keys($enf['sintomas']);
            $coincidencias = array_intersect($sintomasActuales, $sintomasEnfermedad);
            
            // Si hay alguna coincidencia parcial, sugerir preguntas de esa enfermedad
            if (count($coincidencias) > 0 && count($coincidencias) < count($sintomasEnfermedad)) {
                $sintomasFaltantes = array_diff($sintomasEnfermedad, $sintomasActuales);
                $preguntaIndex = 0;
                foreach ($sintomasFaltantes as $sintoma) {
                    if (isset($enf['preguntas'][$preguntaIndex])) {
                        $preguntas[] = [
                            'sintoma_relacionado' => $sintoma,
                            'pregunta' => $enf['preguntas'][$preguntaIndex],
                        ];
                        break; // Solo una pregunta adicional por enfermedad candidata
                    }
                    $preguntaIndex++;
                }
                if (count($preguntas) >= 3) break;
            }
        }

        // Preguntas genéricas si no hay suficientes específicas
        $preguntasGenericas = [
            ['sintoma_relacionado' => 'fiebre', 'pregunta' => '¿Tienes fiebre o has sentido escalofríos?'],
            ['sintoma_relacionado' => 'dolor', 'pregunta' => '¿Tienes algún dolor? ¿Dónde?'],
            ['sintoma_relacionado' => 'malestar_general', 'pregunta' => '¿Te sientes con malestar general?'],
            ['sintoma_relacionado' => 'cansancio', 'pregunta' => '¿Te sientes más cansado de lo normal?'],
        ];

        while (count($preguntas) < 3) {
            $preguntaGenerica = array_shift($preguntasGenericas);
            if (!in_array($preguntaGenerica['sintoma_relacionado'], $sintomasActuales)) {
                $preguntas[] = $preguntaGenerica;
            }
        }

        return array_slice($preguntas, 0, 3);
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

        return [
            'visitas_ultimo_mes' => $visitasMes,
            'condiciones_cronicas' => array_unique($condicionesCronicas),
            'medicamentos_activos' => array_unique($medicamentosActivos),
            'ultimo_diagnostico' => $ultimoDiagnostico,
            'total_historial' => Bitacora::where('alumno_id', $alumnoId)->count(),
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
     * Selecciona preguntas iniciales basadas en el motivo de consulta
     */
    private function seleccionarPreguntasIniciales(?string $motivo, array $enfermedades): array
    {
        if (!$motivo) {
            // Preguntas genéricas si no hay motivo
            return [
                ['sintoma_relacionado' => 'fiebre', 'pregunta' => '¿Tienes fiebre o escalofríos?'],
                ['sintoma_relacionado' => 'dolor', 'pregunta' => '¿Sientes algún dolor? ¿En qué parte?'],
                ['sintoma_relacionado' => 'malestar_general', 'pregunta' => '¿Desde cuándo te sientes mal?'],
            ];
        }

        $motivoLower = strtolower($motivo);
        $preguntas = [];

        // Mapeo de palabras clave a categorías
        $mapeoCategorias = [
            'Respiratoria' => ['gripe', 'resfriado', 'tos', 'nariz', 'garganta', 'respirar'],
            'Digestiva' => ['estómago', 'vomitar', 'vómito', 'diarrea', 'barriga', 'comer'],
            'Neurológica' => ['cabeza', 'migrana', 'migraña', 'mareo', 'vertigo'],
            'Mental' => ['estres', 'estrés', 'ansiedad', 'dormir', 'insomnio', 'nervios'],
            'General' => ['dolor', 'fiebre', 'cansancio', 'malestar'],
        ];

        // Detectar categoría probable
        $categoriaDetectada = null;
        foreach ($mapeoCategorias as $categoria => $palabras) {
            foreach ($palabras as $palabra) {
                if (strpos($motivoLower, $palabra) !== false) {
                    $categoriaDetectada = $categoria;
                    break 2;
                }
            }
        }

        // Buscar enfermedades de esa categoría y extraer sus preguntas
        if ($categoriaDetectada) {
            foreach ($enfermedades as $enf) {
                if ($enf['categoria'] === $categoriaDetectada) {
                    foreach ($enf['preguntas'] as $pregunta) {
                        $preguntas[] = [
                            'sintoma_relacionado' => array_keys($enf['sintomas'])[0],
                            'pregunta' => $pregunta,
                        ];
                        if (count($preguntas) >= 4) break 2;
                    }
                }
            }
        }

        // Si no hay suficientes preguntas específicas, completar con genéricas
        $preguntasGenericas = [
            ['sintoma_relacionado' => 'fiebre', 'pregunta' => '¿Tienes fiebre?'],
            ['sintoma_relacionado' => 'evolucion', 'pregunta' => '¿Desde cuándo te sientes así?'],
            ['sintoma_relacionado' => 'intensidad', 'pregunta' => '¿El malestar es leve, moderado o severo?'],
        ];

        while (count($preguntas) < 4 && !empty($preguntasGenericas)) {
            $preguntas[] = array_shift($preguntasGenericas);
        }

        return array_slice($preguntas, 0, 4);
    }

    /**
     * Extrae síntomas confirmados de las respuestas del usuario
     */
    private function extraerSintomasDeRespuestas(array $respuestas): array
    {
        $sintomas = [];
        
        foreach ($respuestas as $respuesta) {
            $texto = strtolower($respuesta['respuesta'] ?? '');
            $sintomaRelacionado = $respuesta['sintoma_relacionado'] ?? null;

            // Si respondió afirmativamente
            if ($this->esRespuestaAfirmativa($texto)) {
                if ($sintomaRelacionado) {
                    $sintomas[] = $sintomaRelacionado;
                }
                // También buscar síntomas adicionales en el texto
                $sintomas = array_merge($sintomas, $this->parsearSintomasDeTexto($texto));
            }
        }

        return array_unique($sintomas);
    }

    /**
     * Determina si una respuesta es afirmativa
     */
    private function esRespuestaAfirmativa(string $texto): bool
    {
        $afirmativas = ['si', 'sí', 'si ', 'yes', 'afirmativo', 'correcto', 'cierto', 'tengo', 'siento', 'yes'];
        $negativas = ['no', 'nop', 'no tengo', 'no siento', 'negativo', 'tampoco'];

        foreach ($negativas as $neg) {
            if (strpos($texto, $neg) !== false) {
                return false;
            }
        }

        foreach ($afirmativas as $afirm) {
            if (strpos($texto, $afirm) !== false) {
                return true;
            }
        }

        return false;
    }

    /**
     * Guarda la pre-evaluación en base de datos
     */
    private function guardarPreEvaluacion(int $citaId, array $respuestas, array $posiblesEnfermedades, array $sintomas): void
    {
        $cita = Cita::findOrFail($citaId);
        
        \App\Models\PreEvaluacionIA::updateOrCreate(
            ['cita_id' => $citaId],
            [
                'alumno_id' => $cita->alumno_id,
                'respuestas' => $respuestas,
                'sintomas_detectados' => $sintomas,
                'posibles_enfermedades' => array_slice($posiblesEnfermedades, 0, 3),
                'confianza' => $posiblesEnfermedades[0]['probabilidad'] ?? 0,
            ]
        );
    }

    /**
     * Genera recomendaciones temporales mientras espera la cita
     */
    private function generarRecomendacionesTemporales(?string $enfermedadKey): array
    {
        $recomendaciones = [
            'general' => [
                'Descansa lo suficiente',
                'Mantente hidratado bebiendo agua',
                'Evita automedicarte sin consultar al doctor',
            ],
        ];

        $especificas = [
            'gripe' => ['Toma líquidos calientes', 'Descansa en cama', 'Usa ropa abrigadora'],
            'resfriado_comun' => ['Lávate las manos frecuentemente', 'Usa pañuelos desechables'],
            'faringitis' => ['Haz gárgaras con agua tibia y sal', 'Evita alimentos irritantes'],
            'gastroenteritis' => ['Dieta blanda (arroz, plátano, manzana)', 'Evita lácteos y grasas'],
            'migrana' => ['Descansa en lugar oscuro y silencioso', 'Aplica compresas frías'],
            'ansiedad' => ['Practica respiración profunda', 'Evita cafeína'],
            'conjuntivitis' => ['No te toques los ojos', 'Lávate las manos constantemente'],
        ];

        $resultado = $recomendaciones['general'];
        if ($enfermedadKey && isset($especificas[$enfermedadKey])) {
            $resultado = array_merge($resultado, $especificas[$enfermedadKey]);
        }

        return $resultado;
    }

    /**
     * Calcula peso de prioridad para ordenar resultados
     */
    private function calcularPesoPrioridad(array $enfermedad): float
    {
        $pesoProbabilidad = $enfermedad['probabilidad'] / 100;
        
        // Priorizar enfermedades muy comunes
        $pesoFrecuencia = match($enfermedad['frecuencia']) {
            'muy_alta' => 1.3,
            'alta' => 1.2,
            'media' => 1.0,
            'baja' => 0.8,
            default => 1.0,
        };

        // Bonus por número de síntomas coincidentes
        $pesoCoincidencias = count($enfermedad['sintomas_coincidentes']) * 0.05;

        return ($pesoProbabilidad * $pesoFrecuencia) + $pesoCoincidencias;
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
    private function cargarOEntrenarModelos(): void
    {
        $modeloSymptomPath = $this->modelPath . '/naive_bayes_model.json';

        if (file_exists($modeloSymptomPath)) {
            $this->symptomClassifier->cargar($modeloSymptomPath);
        } else {
            // Entrenar con datos dummy
            $dataset = MedicalDataset::generarDatasetEntrenamiento(500);
            $this->symptomClassifier->entrenar($dataset);
            $this->symptomClassifier->guardar($modeloSymptomPath);
            
            // Entrenar clasificador de prioridad
            $this->priorityClassifier->entrenar($dataset);
        }
    }

    /**
     * Re-entrena los modelos con nuevos datos
     */
    public function reentrenarModelos(): array
    {
        $dataset = MedicalDataset::generarDatasetEntrenamiento(1000);
        
        // Dividir en entrenamiento y prueba
        shuffle($dataset);
        $mitad = count($dataset) / 2;
        $entrenamiento = array_slice($dataset, 0, $mitad);
        $prueba = array_slice($dataset, $mitad);

        // Entrenar y evaluar
        $this->symptomClassifier->entrenar($entrenamiento);
        $evalSymptom = $this->symptomClassifier->evaluar($prueba);

        $this->priorityClassifier->entrenar($entrenamiento);
        $evalPriority = $this->priorityClassifier->evaluar($prueba);

        // Guardar modelos
        $this->symptomClassifier->guardar($this->modelPath . '/naive_bayes_model.json');

        return [
            'symptom_classifier' => $evalSymptom,
            'priority_classifier' => $evalPriority,
            'timestamp' => now()->toDateTimeString(),
        ];
    }

    /**
     * Obtiene información de los modelos
     */
    public function getInfoModelos(): array
    {
        return [
            'symptom_classifier' => $this->symptomClassifier->getInfo(),
            'priority_classifier' => $this->priorityClassifier->getConfig(),
            'dataset_enfermedades' => count(MedicalDataset::getEnfermedades()),
        ];
    }
}
