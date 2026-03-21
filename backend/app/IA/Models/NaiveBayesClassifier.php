<?php

namespace App\IA\Models;

/**
 * Clasificador Naive Bayes para diagnóstico de síntomas
 * Implementación desde cero en PHP
 */
class NaiveBayesClassifier
{
    private array $clases = [];
    private array $frecuencias = [];
    private array $totalMuestras = [];
    private array $vocabulario = [];
    private int $totalMuestrasGlobal = 0;
    private float $smoothing = 1.0; // Laplace smoothing

    /**
     * Entrena el modelo con un dataset
     */
    public function entrenar(array $dataset): void
    {
        $this->clases = [];
        $this->frecuencias = [];
        $this->totalMuestras = [];
        $this->vocabulario = [];
        $this->totalMuestrasGlobal = count($dataset);

        foreach ($dataset as $muestra) {
            $clase = $muestra['enfermedad'];
            $sintomas = $muestra['sintomas'];

            if (!isset($this->clases[$clase])) {
                $this->clases[$clase] = 0;
                $this->frecuencias[$clase] = [];
                $this->totalMuestras[$clase] = 0;
            }

            $this->clases[$clase]++;
            $this->totalMuestras[$clase]++;

            foreach ($sintomas as $sintoma) {
                if (!isset($this->frecuencias[$clase][$sintoma])) {
                    $this->frecuencias[$clase][$sintoma] = 0;
                }
                $this->frecuencias[$clase][$sintoma]++;
                $this->vocabulario[$sintoma] = true;
            }
        }
    }

    /**
     * Predice la enfermedad más probable dado un conjunto de síntomas
     * Retorna las top N predicciones con probabilidades
     */
    public function predecir(array $sintomas, int $topN = 3): array
    {
        $probabilidades = [];
        $tamanoVocabulario = count($this->vocabulario);

        foreach ($this->clases as $clase => $conteoClase) {
            // Probabilidad a priori P(Clase)
            $probClase = $conteoClase / $this->totalMuestrasGlobal;
            $logProb = log($probClase);

            // Probabilidad condicional P(Síntoma|Clase)
            $totalSintomasClase = array_sum($this->frecuencias[$clase]);

            foreach ($sintomas as $sintoma) {
                $conteoSintoma = $this->frecuencias[$clase][$sintoma] ?? 0;
                // Laplace smoothing para evitar probabilidad 0
                $probCondicional = ($conteoSintoma + $this->smoothing) / 
                    ($totalSintomasClase + $this->smoothing * $tamanoVocabulario);
                $logProb += log($probCondicional);
            }

            $probabilidades[$clase] = exp($logProb);
        }

        // Normalizar probabilidades
        $totalProb = array_sum($probabilidades);
        if ($totalProb > 0) {
            foreach ($probabilidades as $clase => $prob) {
                $probabilidades[$clase] = $prob / $totalProb;
            }
        }

        // Ordenar por probabilidad descendente
        arsort($probabilidades);

        // Retornar top N
        return array_slice($probabilidades, 0, $topN, true);
    }

    /**
     * Calcula la precisión del modelo con un set de prueba
     */
    public function evaluar(array $datasetPrueba): array
    {
        $correctos = 0;
        $total = count($datasetPrueba);
        $matrizConfusion = [];

        foreach ($datasetPrueba as $muestra) {
            $prediccion = $this->predecir($muestra['sintomas'], 1);
            $clasePredicha = array_key_first($prediccion);
            $claseReal = $muestra['enfermedad'];

            if (!isset($matrizConfusion[$claseReal])) {
                $matrizConfusion[$claseReal] = [];
            }
            if (!isset($matrizConfusion[$claseReal][$clasePredicha])) {
                $matrizConfusion[$claseReal][$clasePredicha] = 0;
            }
            $matrizConfusion[$claseReal][$clasePredicha]++;

            if ($clasePredicha === $claseReal) {
                $correctos++;
            }
        }

        return [
            'precision' => $total > 0 ? $correctos / $total : 0,
            'correctos' => $correctos,
            'total' => $total,
            'matriz_confusion' => $matrizConfusion,
        ];
    }

    /**
     * Guarda el modelo entrenado en archivo
     */
    public function guardar(string $ruta): void
    {
        $datos = [
            'clases' => $this->clases,
            'frecuencias' => $this->frecuencias,
            'totalMuestras' => $this->totalMuestras,
            'vocabulario' => $this->vocabulario,
            'totalMuestrasGlobal' => $this->totalMuestrasGlobal,
        ];

        file_put_contents($ruta, json_encode($datos, JSON_PRETTY_PRINT));
    }

    /**
     * Carga un modelo previamente entrenado
     */
    public function cargar(string $ruta): bool
    {
        if (!file_exists($ruta)) {
            return false;
        }

        $datos = json_decode(file_get_contents($ruta), true);
        if ($datos === null) {
            return false;
        }

        $this->clases = $datos['clases'];
        $this->frecuencias = $datos['frecuencias'];
        $this->totalMuestras = $datos['totalMuestras'];
        $this->vocabulario = $datos['vocabulario'];
        $this->totalMuestrasGlobal = $datos['totalMuestrasGlobal'];

        return true;
    }

    /**
     * Obtiene información del modelo
     */
    public function getInfo(): array
    {
        return [
            'clases_entrenadas' => count($this->clases),
            'total_muestras' => $this->totalMuestrasGlobal,
            'sintomas_conocidos' => count($this->vocabulario),
            'clases' => array_keys($this->clases),
        ];
    }
}
