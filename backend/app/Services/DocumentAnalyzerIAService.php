<?php

namespace App\Services;

use App\Models\DocumentoMedico;
use App\Models\AnalisisDocumentoIA;

/**
 * Servicio de IA para Análisis de Documentos Médicos
 * 
 * Esta IA analiza el texto extraído de documentos médicos (PDF, Word)
 * y extrae datos clínicos relevantes para sugerir diagnósticos.
 * 
 * Es un sistema de IA propio basado en:
 * - Procesamiento de Lenguaje Natural (NLP) básico
 * - Reconocimiento de patrones médicos
 * - Análisis de datos clínicos estructurados
 */
class DocumentAnalyzerIAService
{
    /**
     * Patrones de reconocimiento para datos médicos
     */
    private array $medicalPatterns = [
        // Signos vitales
        'presion_arterial' => [
            'patterns' => ['/presi[oó]n\s+arterial[:\s]+(\d{2,3}\/\d{2,3})/i', '/PA[:\s]+(\d{2,3}\/\d{2,3})/i'],
            'unit' => 'mmHg',
            'normal_range' => '120/80',
        ],
        'glucosa' => [
            'patterns' => ['/glucosa[:\s]+(\d{2,3})/i', '/glucemia[:\s]+(\d{2,3})/i', '/az[uú]car\s+en\s+sangre[:\s]+(\d{2,3})/i'],
            'unit' => 'mg/dL',
            'normal_range' => '70-100',
        ],
        'temperatura' => [
            'patterns' => ['/temperatura[:\s]+(\d{2}\.?\d?)/i', '/temp[:\s]+(\d{2}\.?\d?)/i', '/fiebre[:\s]+(\d{2}\.?\d?)/i'],
            'unit' => '°C',
            'normal_range' => '36.5-37.5',
        ],
        'frecuencia_cardiaca' => [
            'patterns' => ['/frecuencia\s+card[ií]aca[:\s]+(\d{2,3})/i', '/FC[:\s]+(\d{2,3})/i', '/pulso[:\s]+(\d{2,3})/i'],
            'unit' => 'lpm',
            'normal_range' => '60-100',
        ],
        'frecuencia_respiratoria' => [
            'patterns' => ['/frecuencia\s+respiratoria[:\s]+(\d{2})/i', '/FR[:\s]+(\d{2})/i'],
            'unit' => 'rpm',
            'normal_range' => '12-20',
        ],
        'oxigenacion' => [
            'patterns' => ['/saturaci[oó]n\s+de\s+ox[ií]geno[:\s]+(\d{2,3})/i', '/SpO2[:\s]+(\d{2,3})/i', '/oxigenaci[oó]n[:\s]+(\d{2,3})/i'],
            'unit' => '%',
            'normal_range' => '95-100',
        ],
        'peso' => [
            'patterns' => ['/peso[:\s]+(\d{2,3}\.?\d?)/i', '/weight[:\s]+(\d{2,3}\.?\d?)/i'],
            'unit' => 'kg',
        ],
        'talla' => [
            'patterns' => ['/talla[:\s]+(\d{2,3}\.?\d?)/i', '/altura[:\s]+(\d{2,3}\.?\d?)/i', '/height[:\s]+(\d{2,3}\.?\d?)/i'],
            'unit' => 'cm',
        ],
        // Análisis de sangre
        'hemoglobina' => [
            'patterns' => ['/hemoglobina[:\s]+(\d{2}\.?\d?)/i', '/Hb[:\s]+(\d{2}\.?\d?)/i'],
            'unit' => 'g/dL',
            'normal_range' => '12-16',
        ],
        'plaquetas' => [
            'patterns' => ['/plaquetas[:\s]+(\d{3,6})/i', '/platelets[:\s]+(\d{3,6})/i'],
            'unit' => 'x10³/μL',
            'normal_range' => '150,000-400,000',
        ],
        'leucocitos' => [
            'patterns' => ['/leucocitos[:\s]+(\d{2,3}\.?\d?)/i', '/gl[oó]bulos\s+blancos[:\s]+(\d{2,3}\.?\d?)/i', '/WBC[:\s]+(\d{2,3}\.?\d?)/i'],
            'unit' => 'x10³/μL',
            'normal_range' => '4.5-11.0',
        ],
        // Función renal
        'creatinina' => [
            'patterns' => ['/creatinina[:\s]+(\d\.?\d{1,2})/i', '/creatinine[:\s]+(\d\.?\d{1,2})/i'],
            'unit' => 'mg/dL',
            'normal_range' => '0.7-1.3',
        ],
        // Función hepática
        'transaminasas' => [
            'patterns' => ['/ALT[:\s]+(\d{1,3})/i', '/AST[:\s]+(\d{1,3})/i', '/TGP[:\s]+(\d{1,3})/i', '/TGO[:\s]+(\d{1,3})/i'],
            'unit' => 'U/L',
            'normal_range' => '10-40',
        ],
    ];

    /**
     * Patrones para síntomas y diagnósticos
     */
    private array $symptomPatterns = [
        'diabetes' => ['/diabetes/i', '/hiperglucemia/i', '/resistencia\s+a\s+la\s+insulina/i'],
        'hipertension' => ['/hipertensi[oó]n/i', '/presi[oó]n\s+arterial\s+alta/i', '/HTA/i'],
        'anemia' => ['/anemia/i', '/deficiencia\s+de\s+hierro/i', '/ferropenia/i'],
        'infeccion' => ['/infecci[oó]n/i', '/sepsis/i', '/bacteremia/i', '/viremia/i'],
        'inflamacion' => ['/inflamaci[oó]n/i', '/elevaci[oó]n\s+de\s+VSG/i', '/PCR\s+elevada/i', '/prote[ií]na\s+C\s+reactiva/i'],
        'insuficiencia_renal' => ['/insuficiencia\s+renal/i', '/fallo\s+renal/i', '/enfermedad\s+renal/i', '/uercia/i'],
        'hepatitis' => ['/hepatitis/i', '/elevaci[oó]n\s+de\s+transaminasas/i', '/daño\s+hepático/i'],
        'dislipidemia' => ['/dislipidemia/i', '/colesterol\s+elevado/i', '/hipercolesterolemia/i', '/triglic[eé]ridos\s+elevados/i'],
        'hipotiroidismo' => ['/hipotiroidismo/i', '/TSH\s+elevada/i', '/hormona\s+estimulante\s+del\s+tiroides/i'],
        'hipertiroidismo' => ['/hipertiroidismo/i', '/TSH\s+baja/i', '/T4\s+libre\s+elevada/i'],
    ];

    /**
     * Analiza un documento médico y extrae información clínica
     */
    public function analizarDocumento(DocumentoMedico $documento): AnalisisDocumentoIA
    {
        // Crear registro de análisis
        $analisis = AnalisisDocumentoIA::create([
            'documento_id' => $documento->id,
            'estatus' => 'procesando',
        ]);

        try {
            $texto = $documento->texto_extraido;
            
            if (empty($texto)) {
                throw new \Exception('No hay texto extraído para analizar');
            }

            // 1. Extraer datos médicos estructurados
            $datosDetectados = $this->extraerDatosMedicos($texto);
            
            // 2. Detectar síntomas/patologías mencionadas
            $sintomasDetectados = $this->detectarSintomas($texto);
            
            // 3. Sugerir diagnóstico basado en datos
            $diagnosticoSugerido = $this->sugerirDiagnostico($datosDetectados, $sintomasDetectados, $texto);
            
            // 4. Calcular nivel de confianza
            $nivelConfianza = $this->calcularConfianza($datosDetectados, $sintomasDetectados, $diagnosticoSugerido);
            
            // 5. Generar descripción del análisis
            $descripcion = $this->generarDescripcion($datosDetectados, $sintomasDetectados, $diagnosticoSugerido);
            
            // 6. Extraer palabras clave
            $palabrasClave = $this->extraerPalabrasClave($texto);

            // Actualizar análisis
            $analisis->update([
                'estatus' => 'completado',
                'datos_detectados' => $datosDetectados,
                'diagnostico_sugerido' => $diagnosticoSugerido['diagnostico'],
                'descripcion_analisis' => $descripcion,
                'nivel_confianza' => $nivelConfianza,
                'palabras_clave_detectadas' => $palabrasClave,
            ]);

            // Actualizar documento
            $documento->update([
                'estatus_procesamiento' => 'completado',
                'datos_extraidos' => $datosDetectados,
            ]);

        } catch (\Exception $e) {
            $analisis->update([
                'estatus' => 'error',
                'descripcion_analisis' => 'Error en análisis: ' . $e->getMessage(),
            ]);

            $documento->update([
                'estatus_procesamiento' => 'error',
            ]);
        }

        return $analisis;
    }

    /**
     * Extrae datos médicos estructurados del texto
     */
    private function extraerDatosMedicos(string $texto): array
    {
        $datos = [];

        foreach ($this->medicalPatterns as $key => $config) {
            foreach ($config['patterns'] as $pattern) {
                if (preg_match($pattern, $texto, $matches)) {
                    $valor = $matches[1];
                    
                    // Determinar si está en rango normal
                    $estado = $this->evaluarRango($key, $valor, $config['normal_range'] ?? null);
                    
                    $datos[$key] = [
                        'valor' => $valor,
                        'unidad' => $config['unit'],
                        'rango_normal' => $config['normal_range'] ?? null,
                        'estado' => $estado,
                        'patron_encontrado' => $matches[0],
                    ];
                    
                    break; // Solo tomar el primer match
                }
            }
        }

        return $datos;
    }

    /**
     * Detecta síntomas y patologías mencionadas
     */
    private function detectarSintomas(string $texto): array
    {
        $sintomas = [];

        foreach ($this->symptomPatterns as $sintoma => $patterns) {
            foreach ($patterns as $pattern) {
                if (preg_match($pattern, $texto)) {
                    $sintomas[] = [
                        'sintoma' => $sintoma,
                        'confianza' => 'alta',
                        'patron' => $pattern,
                    ];
                    break;
                }
            }
        }

        return $sintomas;
    }

    /**
     * Sugiere diagnóstico basado en datos y síntomas
     */
    private function sugerirDiagnostico(array $datos, array $sintomas, string $texto): array
    {
        $diagnosticosPosibles = [];

        // Análisis basado en glucosa
        if (isset($datos['glucosa'])) {
            $glucosa = (float) $datos['glucosa']['valor'];
            if ($glucosa > 126) {
                $diagnosticosPosibles[] = ['diagnostico' => 'Diabetes Mellitus Tipo 2', 'confianza' => 0.8];
            } elseif ($glucosa > 100) {
                $diagnosticosPosibles[] = ['diagnostico' => 'Prediabetes / Intolerancia a la glucosa', 'confianza' => 0.7];
            }
        }

        // Análisis basado en presión arterial
        if (isset($datos['presion_arterial'])) {
            $pa = $datos['presion_arterial']['valor'];
            if (preg_match('/(\d{2,3})\/(\d{2,3})/', $pa, $matches)) {
                $sistolica = (int) $matches[1];
                $diastolica = (int) $matches[2];
                
                if ($sistolica >= 140 || $diastolica >= 90) {
                    $diagnosticosPosibles[] = ['diagnostico' => 'Hipertensión Arterial', 'confianza' => 0.75];
                } elseif ($sistolica >= 130 || $diastolica >= 80) {
                    $diagnosticosPosibles[] = ['diagnostico' => 'Prehipertensión', 'confianza' => 0.6];
                }
            }
        }

        // Análisis basado en hemoglobina
        if (isset($datos['hemoglobina'])) {
            $hb = (float) $datos['hemoglobina']['valor'];
            if ($hb < 12) {
                $diagnosticosPosibles[] = ['diagnostico' => 'Anemia', 'confianza' => 0.7];
            }
        }

        // Análisis basado en síntomas detectados
        foreach ($sintomas as $sintoma) {
            switch ($sintoma['sintoma']) {
                case 'infeccion':
                    $diagnosticosPosibles[] = ['diagnostico' => 'Infección sistémica', 'confianza' => 0.65];
                    break;
                case 'hepatitis':
                    $diagnosticosPosibles[] = ['diagnostico' => 'Hepatitis / Daño hepático', 'confianza' => 0.7];
                    break;
                case 'insuficiencia_renal':
                    $diagnosticosPosibles[] = ['diagnostico' => 'Insuficiencia Renal Crónica', 'confianza' => 0.75];
                    break;
            }
        }

        // Si no hay diagnósticos claros, buscar en texto
        if (empty($diagnosticosPosibles)) {
            $diagnosticoTexto = $this->buscarDiagnosticoEnTexto($texto);
            if ($diagnosticoTexto) {
                $diagnosticosPosibles[] = ['diagnostico' => $diagnosticoTexto, 'confianza' => 0.5];
            }
        }

        // Ordenar por confianza y retornar el mejor
        usort($diagnosticosPosibles, function($a, $b) {
            return $b['confianza'] <=> $a['confianza'];
        });

        return $diagnosticosPosibles[0] ?? ['diagnostico' => 'No se pudo determinar diagnóstico específico', 'confianza' => 0.3];
    }

    /**
     * Busca diagnóstico explícito en el texto
     */
    private function buscarDiagnosticoEnTexto(string $texto): ?string
    {
        $patronesDiagnostico = [
            '/diagn[oó]stico[:\s]+([^\.\n]+)/i',
            '/impresi[oó]n\s+diagn[oó]stica[:\s]+([^\.\n]+)/i',
            '/conclusi[oó]n[:\s]+([^\.\n]+)/i',
        ];

        foreach ($patronesDiagnostico as $pattern) {
            if (preg_match($pattern, $texto, $matches)) {
                return trim($matches[1]);
            }
        }

        return null;
    }

    /**
     * Calcula nivel de confianza del análisis
     */
    private function calcularConfianza(array $datos, array $sintomas, array $diagnostico): float
    {
        $confianza = $diagnostico['confianza'] ?? 0.5;

        // Aumentar confianza si hay más datos numéricos
        $confianza += count($datos) * 0.05;
        
        // Aumentar confianza si hay síntomas detectados
        $confianza += count($sintomas) * 0.03;

        // Limitar a 0.95 máximo
        return min(0.95, $confianza);
    }

    /**
     * Genera descripción legible del análisis
     */
    private function generarDescripcion(array $datos, array $sintomas, array $diagnostico): string
    {
        $descripcion = "Análisis realizado por IA:\n\n";

        if (!empty($datos)) {
            $descripcion .= "📊 Datos clínicos detectados:\n";
            foreach ($datos as $key => $dato) {
                $estado = $dato['estado'] === 'normal' ? '✅' : ($dato['estado'] === 'alto' ? '⚠️ Alto' : '⚠️ Bajo');
                $descripcion .= "• {$key}: {$dato['valor']} {$dato['unidad']} {$estado}\n";
            }
            $descripcion .= "\n";
        }

        if (!empty($sintomas)) {
            $descripcion .= "🔍 Patologías/Condiciones detectadas en texto:\n";
            foreach ($sintomas as $sintoma) {
                $descripcion .= "• " . ucfirst(str_replace('_', ' ', $sintoma['sintoma'])) . "\n";
            }
            $descripcion .= "\n";
        }

        $descripcion .= "💡 Diagnóstico sugerido: {$diagnostico['diagnostico']}\n";
        $descripcion .= "📈 Confianza del análisis: " . round(($diagnostico['confianza'] ?? 0.5) * 100) . "%\n\n";
        $descripcion .= "⚠️ NOTA: Este diagnóstico es una sugerencia basada en el análisis automatizado del documento. Debe ser validado por un médico profesional.";

        return $descripcion;
    }

    /**
     * Extrae palabras clave médicas del texto
     */
    private function extraerPalabrasClave(string $texto): array
    {
        $palabrasMedicasComunes = [
            'glucosa', 'presión arterial', 'temperatura', 'fiebre', 'dolor', 'náuseas',
            'vómito', 'diarrea', 'constipación', 'dolor de cabeza', 'mareo', 'fatiga',
            'anemia', 'diabetes', 'hipertensión', 'hipotensión', 'infección', 'inflamación',
            'antibiótico', 'antihistamínico', 'analgesico', 'antipirético', 'insulina',
            'creatinina', 'urea', 'transaminasas', 'bilirrubina', 'colesterol', 'triglicéridos',
            'hemoglobina', 'hematocrito', 'plaquetas', 'leucocitos', 'linfocitos',
            'radiografía', 'tomografía', 'ultrasonido', 'resonancia', 'electrocardiograma',
        ];

        $encontradas = [];
        $textoLower = strtolower($texto);

        foreach ($palabrasMedicasComunes as $palabra) {
            if (strpos($textoLower, strtolower($palabra)) !== false) {
                $encontradas[] = $palabra;
            }
        }

        return $encontradas;
    }

    /**
     * Evalúa si un valor está en rango normal
     */
    private function evaluarRango(string $tipo, string $valor, ?string $rangoNormal): string
    {
        if (!$rangoNormal) return 'no_evaluable';

        // Parsear valor
        $valorNumerico = (float) $valor;

        // Parsear rango
        if (strpos($rangoNormal, '-') !== false) {
            [$min, $max] = explode('-', $rangoNormal);
            $min = (float) trim($min);
            $max = (float) trim($max);

            if ($valorNumerico >= $min && $valorNumerico <= $max) {
                return 'normal';
            } elseif ($valorNumerico > $max) {
                return 'alto';
            } else {
                return 'bajo';
            }
        }

        return 'no_evaluable';
    }

    /**
     * Regenera análisis de un documento (para correcciones)
     */
    public function regenerarAnalisis(AnalisisDocumentoIA $analisis): AnalisisDocumentoIA
    {
        $documento = $analisis->documento;
        
        // Resetear estado
        $analisis->update([
            'estatus' => 'pendiente',
            'estatus_validacion' => 'pendiente',
        ]);

        return $this->analizarDocumento($documento);
    }
}
