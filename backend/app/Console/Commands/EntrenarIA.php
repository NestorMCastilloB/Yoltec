<?php

namespace App\Console\Commands;

use App\IA\Services\IAService;
use Illuminate\Console\Command;

/**
 * Comando para entrenar y evaluar el clasificador de prioridad
 */
class EntrenarIA extends Command
{
    protected $signature = 'ia:entrenar 
                            {--evaluar : Solo evaluar sin reentrenar}
                            {--dataset-size=1000 : Cantidad de muestras para entrenar}';

    protected $description = 'Entrena o evalúa el clasificador de prioridad de citas';

    public function handle()
    {
        $this->info('🤖 Clasificador de prioridad de citas...');
        $this->newLine();

        $iaService = new IAService();

        // Solo evaluar
        if ($this->option('evaluar')) {
            $this->info('📊 Evaluando el modelo actual...');
            $info = $iaService->getInfoModelos();
            
            $this->table(
                ['Parámetro', 'Valor'],
                [
                    ['Enfermedades conocidas', $info['dataset_enfermedades']],
                    ['Umbral prioridad alta', $info['priority_classifier']['umbrales']['alta'] ?? 'N/A'],
                    ['Umbral prioridad media', $info['priority_classifier']['umbrales']['media'] ?? 'N/A'],
                    ['Factores ponderados', count($info['priority_classifier']['pesos'] ?? [])],
                ]
            );
            
            return 0;
        }

        // Reentrenar
        $size = $this->option('dataset-size');
        $this->info("🎯 Reentrenando con {$size} muestras...");
        $this->warn('⏳ Esto puede tomar unos segundos...');
        $this->newLine();

        $start = microtime(true);
        $resultados = $iaService->reentrenarModelos();
        $tiempo = round(microtime(true) - $start, 2);

        // Mostrar resultados
        $this->info('✅ Entrenamiento completado en ' . $tiempo . ' segundos');
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
        $this->warn('⚠️  Los pesos viven en memoria: no se guardan entre peticiones.');
        $this->info('🕐 Timestamp: ' . $resultados['timestamp']);

        return 0;
    }
}
