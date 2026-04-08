<?php

namespace App\IA\Models;

use App\IA\Data\MedicalDataset;

/**
 * Clasificador de Prioridad de Atención
 * Usa un sistema de puntuación ponderada basado en:
 * - Síntomas actuales
 * - Historial médico del alumno
 * - Visitas previas
 * - Condiciones crónicas
 */
class PriorityClassifier
{
    private array $pesos = [
        'sintomas_alta'      => 10,
        'sintomas_media'     => 5,
        'sintomas_baja'      => 1,
        'condicion_cronica'  => 3,
        'visitas_frecuentes' => 2,
        'medicamento_activo' => 2,
        'edad_factor'        => 1,
        'inasistencia'       => -3, // Penalización por no asistir
        'cancelacion'        => -1, // Penalización leve por cancelar
    ];

    private array $umbrales = [
        'alta' => 15,
        'media' => 8,
        'baja' => 0,
    ];

    /**
     * Calcula la prioridad de atención para un alumno
     */
    public function calcularPrioridad(
        array $sintomasActuales,
        array $historialAlumno,
        ?array $datosDemograficos = null
    ): array {
        $puntuacion = 0;
        $factores = [];
        $factoresDatos = MedicalDataset::getFactoresPrioridad();
        $factoresHistorial = MedicalDataset::getFactoresHistorial();

        // 1. Evaluar síntomas actuales
        foreach ($sintomasActuales as $sintoma) {
            if (in_array($sintoma, $factoresDatos['alta'])) {
                $puntuacion += $this->pesos['sintomas_alta'];
                $factores[] = ['tipo' => 'sintoma_alta', 'valor' => $sintoma];
            } elseif (in_array($sintoma, $factoresDatos['media'])) {
                $puntuacion += $this->pesos['sintomas_media'];
                $factores[] = ['tipo' => 'sintoma_media', 'valor' => $sintoma];
            } else {
                $puntuacion += $this->pesos['sintomas_baja'];
                $factores[] = ['tipo' => 'sintoma_baja', 'valor' => $sintoma];
            }
        }

        // 2. Evaluar condiciones crónicas
        if (!empty($historialAlumno['condiciones_cronicas'])) {
            foreach ($historialAlumno['condiciones_cronicas'] as $condicion) {
                if (in_array($condicion, $factoresHistorial['condiciones_cronicas'])) {
                    $puntuacion += $this->pesos['condicion_cronica'];
                    $factores[] = ['tipo' => 'condicion_cronica', 'valor' => $condicion];
                }
            }
        }

        // 3. Evaluar visitas frecuentes
        $visitasMes = $historialAlumno['visitas_ultimo_mes'] ?? 0;
        $umbralVisitas = $factoresHistorial['visitas_frecuentes']['umbral_visitas_mes'];
        if ($visitasMes >= $umbralVisitas) {
            $puntuacion += $this->pesos['visitas_frecuentes'] * $factoresHistorial['visitas_frecuentes']['peso'];
            $factores[] = ['tipo' => 'visitas_frecuentes', 'valor' => $visitasMes];
        }

        // 4. Evaluar medicamentos activos
        if (!empty($historialAlumno['medicamentos_activos'])) {
            foreach ($historialAlumno['medicamentos_activos'] as $medicamento) {
                if (in_array($medicamento, $factoresHistorial['medicamentos_activos'])) {
                    $puntuacion += $this->pesos['medicamento_activo'];
                    $factores[] = ['tipo' => 'medicamento_activo', 'valor' => $medicamento];
                }
            }
        }

        // 5. Penalizar por inasistencias y cancelaciones recientes
        $inasistencias = $historialAlumno['inasistencias_recientes'] ?? 0;
        if ($inasistencias > 0) {
            $penalizacion = $inasistencias * $this->pesos['inasistencia'];
            $puntuacion += $penalizacion;
            $factores[] = ['tipo' => 'inasistencias', 'valor' => $inasistencias];
        }

        $cancelaciones = $historialAlumno['cancelaciones_recientes'] ?? 0;
        if ($cancelaciones >= 2) {
            $penalizacion = $cancelaciones * $this->pesos['cancelacion'];
            $puntuacion += $penalizacion;
            $factores[] = ['tipo' => 'cancelaciones', 'valor' => $cancelaciones];
        }

        // Asegurar que la puntuación no sea negativa
        $puntuacion = max(0, $puntuacion);

        // 6. Factor edad (si está disponible)
        if ($datosDemograficos && isset($datosDemograficos['edad'])) {
            $edad = $datosDemograficos['edad'];
            // Mayor prioridad para mayores de 30 en universidad (personal/docentes)
            if ($edad > 30) {
                $puntuacion += $this->pesos['edad_factor'];
                $factores[] = ['tipo' => 'edad', 'valor' => $edad];
            }
        }

        // Determinar nivel de prioridad
        $prioridad = $this->determinarNivelPrioridad($puntuacion);

        return [
            'prioridad' => $prioridad,
            'puntuacion' => $puntuacion,
            'factores' => $factores,
            'justificacion' => $this->generarJustificacion($prioridad, $factores, $puntuacion),
        ];
    }

    /**
     * Determina el nivel de prioridad basado en la puntuación
     */
    private function determinarNivelPrioridad(int $puntuacion): string
    {
        if ($puntuacion >= $this->umbrales['alta']) {
            return 'alta';
        } elseif ($puntuacion >= $this->umbrales['media']) {
            return 'media';
        }
        return 'baja';
    }

    /**
     * Genera una justificación textual para la prioridad
     */
    private function generarJustificacion(string $prioridad, array $factores, int $puntuacion): string
    {
        $justificaciones = [
            'alta' => 'Requiere atención prioritaria debido a: ',
            'media' => 'Atención recomendada en el día debido a: ',
            'baja' => 'Puede esperar turno regular. Factores considerados: ',
        ];

        $descripcionFactores = [];
        foreach ($factores as $factor) {
            switch ($factor['tipo']) {
                case 'sintoma_alta':
                    $descripcionFactores[] = "síntoma de urgencia ({$factor['valor']})";
                    break;
                case 'sintoma_media':
                    $descripcionFactores[] = "síntoma moderado ({$factor['valor']})";
                    break;
                case 'condicion_cronica':
                    $descripcionFactores[] = "condición crónica ({$factor['valor']})";
                    break;
                case 'visitas_frecuentes':
                    $descripcionFactores[] = "visitas frecuentes ({$factor['valor']} este mes)";
                    break;
                case 'medicamento_activo':
                    $descripcionFactores[] = "medicamento activo ({$factor['valor']})";
                    break;
                case 'edad':
                    $descripcionFactores[] = "factor edad";
                    break;
                case 'inasistencias':
                    $descripcionFactores[] = "inasistencias recientes ({$factor['valor']})";
                    break;
                case 'cancelaciones':
                    $descripcionFactores[] = "cancelaciones recientes ({$factor['valor']})";
                    break;
            }
        }

        if (empty($descripcionFactores)) {
            return $justificaciones[$prioridad] . 'No se detectaron factores de riesgo significativos.';
        }

        return $justificaciones[$prioridad] . implode(', ', $descripcionFactores) . ". Puntuación: {$puntuacion}";
    }

    /**
     * Entrena/ajusta los pesos del clasificador (simulado con datos dummy)
     */
    public function entrenar(array $dataset): void
    {
        // En una implementación real, aquí ajustaríamos los pesos
        // basándonos en retroalimentación de doctores
        // Por ahora, los pesos son fijos basados en conocimiento médico
        
        // Analizar dataset para validar umbrales
        $distribucion = ['alta' => 0, 'media' => 0, 'baja' => 0];
        foreach ($dataset as $muestra) {
            $distribucion[$muestra['prioridad_real']]++;
        }

        // Ajustar umbrales si la distribución está desbalanceada
        $total = count($dataset);
        if ($total > 0) {
            $porcentajeAlta = $distribucion['alta'] / $total;
            if ($porcentajeAlta > 0.3) {
                // Si hay muchas "altas", subir el umbral
                $this->umbrales['alta'] = min(20, $this->umbrales['alta'] + 2);
            } elseif ($porcentajeAlta < 0.1) {
                // Si hay muy pocas "altas", bajar el umbral
                $this->umbrales['alta'] = max(10, $this->umbrales['alta'] - 2);
            }
        }
    }

    /**
     * Evalúa la precisión del clasificador
     */
    public function evaluar(array $datasetPrueba): array
    {
        $correctos = 0;
        $porPrioridad = ['alta' => ['correctos' => 0, 'total' => 0], 
                        'media' => ['correctos' => 0, 'total' => 0], 
                        'baja' => ['correctos' => 0, 'total' => 0]];

        foreach ($datasetPrueba as $muestra) {
            $historial = [
                'condiciones_cronicas' => $muestra['tiene_condicion_cronica'] ? ['asma'] : [],
                'visitas_ultimo_mes' => $muestra['visitas_previas_mes'],
                'medicamentos_activos' => [],
            ];

            $prediccion = $this->calcularPrioridad($muestra['sintomas'], $historial);
            $predicha = $prediccion['prioridad'];
            $real = $muestra['prioridad_real'];

            $porPrioridad[$real]['total']++;
            if ($predicha === $real) {
                $correctos++;
                $porPrioridad[$real]['correctos']++;
            }
        }

        $total = count($datasetPrueba);
        
        return [
            'precision_global' => $total > 0 ? $correctos / $total : 0,
            'por_prioridad' => [
                'alta' => $porPrioridad['alta']['total'] > 0 
                    ? $porPrioridad['alta']['correctos'] / $porPrioridad['alta']['total'] 
                    : 0,
                'media' => $porPrioridad['media']['total'] > 0 
                    ? $porPrioridad['media']['correctos'] / $porPrioridad['media']['total'] 
                    : 0,
                'baja' => $porPrioridad['baja']['total'] > 0 
                    ? $porPrioridad['baja']['correctos'] / $porPrioridad['baja']['total'] 
                    : 0,
            ],
            'total_muestras' => $total,
            'correctos' => $correctos,
        ];
    }

    /**
     * Obtiene la configuración actual del clasificador
     */
    public function getConfig(): array
    {
        return [
            'pesos' => $this->pesos,
            'umbrales' => $this->umbrales,
        ];
    }

    /**
     * Actualiza los pesos del clasificador
     */
    public function setPesos(array $nuevosPesos): void
    {
        $this->pesos = array_merge($this->pesos, $nuevosPesos);
    }
}
