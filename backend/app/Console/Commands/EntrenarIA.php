<?php

namespace App\Console\Commands;

use App\IA\Services\IAService;
use Illuminate\Console\Command;

/**
 * Comando para entrenar y evaluar los modelos de IA
 */
class EntrenarIA extends Command
{
    protected $signature = 'ia:entrenar 
                            {--evaluar : Solo evaluar sin reentrenar}
                            {--dataset-size=1000 : Cantidad de muestras para entrenar}';

    protected $description = 'Entrena o evalúa los modelos de IA del sistema médico';

    public function handle()
    {
        $this->info('🤖 Iniciando sistema de IA médica...');
        $this->newLine();

        $iaService = new IAService();

        // Solo evaluar
        if ($this->option('evaluar')) {
            $this->info('📊 Evaluando modelos existentes...');
            $info = $iaService->getInfoModelos();
            
            $this->table(
                ['Modelo', 'Valor'],
                [
                    ['Clasificador de Síntomas', 'Naive Bayes'],
                    ['Enfermedades conocidas', $info['dataset_enfermedades']],
                    ['Síntomas en vocabulario', $info['symptom_classifier']['sintomas_conocidos'] ?? 'N/A'],
                    ['Clases entrenadas', $info['symptom_classifier']['clases_entrenadas'] ?? 'N/A'],
                ]
            );
            
            return 0;
        }

        // Reentrenar
        $size = $this->option('dataset-size');
        $this->info("🎯 Reentrenando modelos con {$size} muestras...");
        $this->warn('⏳ Esto puede tomar unos segundos...');
        $this->newLine();

        $start = microtime(true);
        $resultados = $iaService->reentrenarModelos();
        $tiempo = round(microtime(true) - $start, 2);

        // Mostrar resultados
        $this->info('✅ Entrenamiento completado en ' . $tiempo . ' segundos');
        $this->newLine();

        // Resultados del clasificador de síntomas
        $this->info('📈 Resultados del Clasificador de Síntomas (Naive Bayes):');
        $symptom = $resultados['symptom_classifier'];
        $this->table(
            ['Métrica', 'Valor'],
            [
                ['Precisión Global', round($symptom['precision'] * 100, 2) . '%'],
                ['Correctos', $symptom['correctos'] . '/' . $symptom['total']],
            ]
        );

        $this->newLine();

        // Resultados del clasificador de prioridad
        $this->info('📈 Resultados del Clasificador de Prioridad:');
        $priority = $resultados['priority_classifier'];
        $this->table(
            ['Métrica', 'Valor'],
            [
                ['Precisión Global', round($priority['precision_global'] * 100, 2) . '%'],
                ['Precisión Prioridad Alta', round($priority['por_prioridad']['alta'] * 100, 2) . '%'],
                ['Precisión Prioridad Media', round($priority['por_prioridad']['media'] * 100, 2) . '%'],
                ['Precisión Prioridad Baja', round($priority['por_prioridad']['baja'] * 100, 2) . '%'],
            ]
        );

        $this->newLine();
        $this->info('💾 Modelos guardados en: storage/app/ia_models/');
        $this->info('🕐 Timestamp: ' . $resultados['timestamp']);

        return 0;
    }
}
