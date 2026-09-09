<?php

namespace App\Services;

use App\Models\PreEvaluacionIA;
use Illuminate\Support\Facades\Http;

class PreEvaluacionService
{
    // Carga preguntas desde el JSON de configuración IA
    public function getPreguntas(): array
    {
        $configPath = base_path('../IA/enfermedades_config.json');
        if (!file_exists($configPath)) {
            return [];
        }

        $config = json_decode(file_get_contents($configPath), true);
        return $config['preguntas'] ?? [];
    }

    // Llama al microservicio IA /predict. Usa fallback si no está disponible.
    public function callIAPredict(array $respuestas): array
    {
        try {
            $iaUrl    = config('yoltec.ia_service_url');
            $response = Http::timeout(15)->post("{$iaUrl}/predict", ['respuestas' => $respuestas]);

            if ($response->successful()) {
                return $response->json();
            }

            \Log::error('IA predict error: ' . $response->body());
        } catch (\Exception $e) {
            \Log::warning('IA no disponible, usando fallback: ' . $e->getMessage());
        }

        return $this->fallbackDiagnostico($respuestas);
    }

    // Llama al microservicio IA /chat. Lanza excepción si falla.
    public function callIAChat(array $messages): array
    {
        $iaUrl    = config('yoltec.ia_service_url');
        $response = Http::timeout(20)->post("{$iaUrl}/chat", ['messages' => $messages]);

        if (!$response->successful()) {
            throw new \RuntimeException($response->json('detail') ?? $response->body());
        }

        return $response->json();
    }

    // Guarda pre-evaluación desde resultado de chat (solo si no existe una previa).
    public function saveFromChat(int $citaId, int $alumnoId, array $messages, array $diagnostico): PreEvaluacionIA
    {
        return PreEvaluacionIA::create([
            'cita_id'              => $citaId,
            'alumno_id'            => $alumnoId,
            'respuestas'           => ['chat_messages' => $messages],
            'diagnostico_sugerido' => $diagnostico['diagnostico_principal'] ?? 'Sin diagnóstico claro',
            'confianza'            => $diagnostico['confianza'] ?? 0.5,
            'sintomas_detectados'  => $diagnostico['sintomas_detectados'] ?? [],
            'estatus_validacion'   => 'pendiente',
        ]);
    }

    // Diagnóstico de respaldo basado en síntomas clave cuando IA no responde
    private function fallbackDiagnostico(array $respuestas): array
    {
        $si = fn(string $k) => isset($respuestas[$k]) && !str_contains($respuestas[$k], 'No');

        if ($si('fiebre') && $si('tos') && $si('dolor_cabeza')) {
            return [
                'success' => true, 'diagnostico_principal' => 'Gripe', 'confianza' => 0.75,
                'sintomas_detectados'   => ['Fiebre', 'Tos', 'Dolor de cabeza'],
                'posibles_enfermedades' => [['enfermedad' => 'Gripe', 'confianza' => 0.75], ['enfermedad' => 'Resfriado Común', 'confianza' => 0.45]],
                'recomendacion'         => 'Probabilidad moderada de Gripe. Se recomienda consulta médica.',
            ];
        }

        if ($si('congestion_nasal') && $si('tos')) {
            return [
                'success' => true, 'diagnostico_principal' => 'Resfriado Común', 'confianza' => 0.65,
                'sintomas_detectados'   => ['Congestión nasal', 'Tos'],
                'posibles_enfermedades' => [['enfermedad' => 'Resfriado Común', 'confianza' => 0.65], ['enfermedad' => 'Alergias', 'confianza' => 0.40]],
                'recomendacion'         => 'Posible Resfriado Común. Monitorear síntomas.',
            ];
        }

        if ($si('nauseas')) {
            return [
                'success' => true, 'diagnostico_principal' => 'Infección Gastrointestinal', 'confianza' => 0.55,
                'sintomas_detectados'   => ['Náuseas'],
                'posibles_enfermedades' => [['enfermedad' => 'Infección Gastrointestinal', 'confianza' => 0.55]],
                'recomendacion'         => 'Síntomas no concluyentes. Se recomienda consulta médica.',
            ];
        }

        return [
            'success' => true, 'diagnostico_principal' => 'Sin diagnóstico claro', 'confianza' => 0.20,
            'sintomas_detectados'   => [],
            'posibles_enfermedades' => [],
            'recomendacion'         => 'Los síntomas no son concluyentes. Se recomienda consulta médica.',
        ];
    }
}
