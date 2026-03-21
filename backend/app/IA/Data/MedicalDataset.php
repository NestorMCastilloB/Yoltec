<?php

namespace App\IA\Data;

/**
 * Dataset de enfermedades comunes y sus síntomas
 * Para doctor general en consultorio universitario
 */
class MedicalDataset
{
    /**
     * Enfermedades comunes con sus síntomas característicos
     * Peso: 3 = síntoma principal, 2 = común, 1 = ocasional
     */
    public static function getEnfermedades(): array
    {
        return [
            // ENFERMEDADES RESPIRATORIAS (muy comunes en universidad)
            'gripe' => [
                'nombre' => 'Gripe/Influenza',
                'categoria' => 'Respiratoria',
                'frecuencia' => 'muy_alta',
                'sintomas' => [
                    'fiebre' => 3,
                    'dolor_cabeza' => 3,
                    'dolor_muscular' => 3,
                    'congestion_nasal' => 2,
                    'tos' => 2,
                    'escalofrios' => 2,
                    'fatiga' => 2,
                    'dolor_garganta' => 1,
                ],
                'preguntas' => [
                    '¿Tienes fiebre mayor a 38°C?',
                    '¿Te duele todo el cuerpo?',
                    '¿Tienes mucosidad nasal?',
                    '¿Te sientes muy cansado?',
                ],
            ],
            'resfriado_comun' => [
                'nombre' => 'Resfriado Común',
                'categoria' => 'Respiratoria',
                'frecuencia' => 'muy_alta',
                'sintomas' => [
                    'congestion_nasal' => 3,
                    'estornudos' => 3,
                    'dolor_garganta' => 2,
                    'tos' => 2,
                    'mucosidad' => 2,
                    'dolor_cabeza' => 1,
                ],
                'preguntas' => [
                    '¿Tienes mucho moqueo?',
                    '¿Estornudas frecuentemente?',
                    '¿Tienes la nariz tapada?',
                    '¿Es leve el malestar?',
                ],
            ],
            'faringitis' => [
                'nombre' => 'Faringitis (Infección de Garganta)',
                'categoria' => 'Respiratoria',
                'frecuencia' => 'alta',
                'sintomas' => [
                    'dolor_garganta' => 3,
                    'dolor_tragar' => 3,
                    'fiebre' => 2,
                    'ganglios_inflamados' => 2,
                    'amigdalas_rojas' => 2,
                    'tos' => 1,
                ],
                'preguntas' => [
                    '¿Te duele mucho la garganta?',
                    '¿Te cuesta trabajo tragar?',
                    '¿Tienes fiebre?',
                    '¿Sientes los ganglios inflamados?',
                ],
            ],
            'bronquitis' => [
                'nombre' => 'Bronquitis',
                'categoria' => 'Respiratoria',
                'frecuencia' => 'media',
                'sintomas' => [
                    'tos_con_flema' => 3,
                    'fatiga' => 2,
                    'dolor_pecho' => 2,
                    'dificultad_respirar' => 2,
                    'fiebre_baja' => 1,
                    'mucosidad' => 2,
                ],
                'preguntas' => [
                    '¿Tienes tos con flema?',
                    '¿Te duele el pecho al toser?',
                    '¿Te cuesta trabajo respirar?',
                    '¿La tos lleva varios días?',
                ],
            ],
            'alergia' => [
                'nombre' => 'Alergia Respiratoria',
                'categoria' => 'Respiratoria',
                'frecuencia' => 'alta',
                'sintomas' => [
                    'estornudos' => 3,
                    'picazon_nariz' => 3,
                    'ojos_llorosos' => 2,
                    'congestion_nasal' => 2,
                    'picazon_ojos' => 2,
                ],
                'preguntas' => [
                    '¿Estornudas mucho?',
                    '¿Te pica la nariz?',
                    '¿Tienes los ojos llorosos?',
                    '¿Empeora al salir al exterior?',
                ],
            ],

            // SISTEMA DIGESTIVO
            'gastroenteritis' => [
                'nombre' => 'Gastroenteritis',
                'categoria' => 'Digestiva',
                'frecuencia' => 'alta',
                'sintomas' => [
                    'diarrea' => 3,
                    'vomito' => 3,
                    'dolor_abdominal' => 3,
                    'fiebre' => 1,
                    'nauseas' => 2,
                    'cansancio' => 1,
                ],
                'preguntas' => [
                    '¿Tienes diarrea?',
                    '¿Has vomitado?',
                    '¿Te duele el estómago?',
                    '¿Crees que fue algo que comiste?',
                ],
            ],
            'intoxicacion_alimentaria' => [
                'nombre' => 'Intoxicación Alimentaria',
                'categoria' => 'Digestiva',
                'frecuencia' => 'media',
                'sintomas' => [
                    'vomito' => 3,
                    'diarrea' => 3,
                    'dolor_abdominal_intenso' => 3,
                    'fiebre' => 2,
                    'nauseas' => 3,
                    'dolor_cabeza' => 1,
                ],
                'preguntas' => [
                    '¿Vomitaste recientemente?',
                    '¿Comiste algo sospechoso?',
                    '¿El dolor abdominal es intenso?',
                    '¿Empezó súbitamente?',
                ],
            ],
            'estreñimiento' => [
                'nombre' => 'Estreñimiento',
                'categoria' => 'Digestiva',
                'frecuencia' => 'media',
                'sintomas' => [
                    'dificultad_evacuar' => 3,
                    'dolor_abdominal' => 2,
                    'gases' => 1,
                    'hinchazon' => 1,
                ],
                'preguntas' => [
                    '¿Cuántos días sin evacuar?',
                    '¿Te cuesta trabajo ir al baño?',
                    '¿Sientes hinchazón?',
                    '¿Has cambiado tu alimentación?',
                ],
            ],
            'acidez' => [
                'nombre' => 'Acidez Estomacal/Reflujo',
                'categoria' => 'Digestiva',
                'frecuencia' => 'media',
                'sintomas' => [
                    'ardor_estomago' => 3,
                    'regurgitacion' => 2,
                    'dolor_pecho_quemazon' => 2,
                    'sabor_amargo' => 1,
                    'nauseas' => 1,
                ],
                'preguntas' => [
                    '¿Sientes ardor en el estómago?',
                    '¿Empeora al acostarte?',
                    '¿Comiste comida picada o grasosa?',
                    '¿Te sube el ácido?',
                ],
            ],

            // DOLOR Y MIGRAÑA
            'migrana' => [
                'nombre' => 'Migraña',
                'categoria' => 'Neurológica',
                'frecuencia' => 'alta',
                'sintomas' => [
                    'dolor_cabeza_intenso' => 3,
                    'sensibilidad_luz' => 3,
                    'sensibilidad_sonido' => 2,
                    'nauseas' => 2,
                    'dolor_pulsatil' => 3,
                    'vision_borrosa' => 1,
                ],
                'preguntas' => [
                    '¿El dolor de cabeza es intenso?',
                    '¿Te molesta la luz?',
                    '¿Es un dolor pulsátil?',
                    '¿Tienes náuseas?',
                ],
            ],
            'cefalea_tension' => [
                'nombre' => 'Cefalea por Tensión',
                'categoria' => 'Neurológica',
                'frecuencia' => 'muy_alta',
                'sintomas' => [
                    'dolor_cabeza_opresivo' => 3,
                    'tension_cuello' => 2,
                    'estres' => 2,
                    'dolor_leve_moderado' => 2,
                ],
                'preguntas' => [
                    '¿Sientes presión en la cabeza?',
                    '¿Tienes tensión en el cuello?',
                    '¿Has estado estresado?',
                    '¿Estudias muchas horas?',
                ],
            ],

            // MENTAL/EMOCIONAL (muy común en universidad)
            'ansiedad' => [
                'nombre' => 'Ansiedad',
                'categoria' => 'Mental',
                'frecuencia' => 'muy_alta',
                'sintomas' => [
                    'preocupacion_excesiva' => 3,
                    'nerviosismo' => 3,
                    'taquicardia' => 2,
                    'dificultad_concentrar' => 2,
                    'insomnio' => 2,
                    'irritabilidad' => 1,
                    'sudoracion' => 1,
                ],
                'preguntas' => [
                    '¿Te preocupas mucho por todo?',
                    '¿Sientes que el corazón acelera?',
                    '¿Tienes dificultad para dormir?',
                    '¿Tienes exámenes o trabajos próximos?',
                ],
            ],
            'estres' => [
                'nombre' => 'Estrés',
                'categoria' => 'Mental',
                'frecuencia' => 'muy_alta',
                'sintomas' => [
                    'agotamiento' => 3,
                    'dificultad_dormir' => 2,
                    'irritabilidad' => 2,
                    'tension_muscular' => 2,
                    'dolor_cabeza' => 1,
                    'problemas_concentracion' => 2,
                ],
                'preguntas' => [
                    '¿Te sientes agotado?',
                    '¿Tienes mucha carga de trabajo?',
                    '¿Te cuesta dormir bien?',
                    '¿Estás irritable últimamente?',
                ],
            ],
            'insomnio' => [
                'nombre' => 'Insomnio',
                'categoria' => 'Mental',
                'frecuencia' => 'alta',
                'sintomas' => [
                    'dificultad_dormirse' => 3,
                    'despertar_frecuente' => 3,
                    'cansancio_dia' => 2,
                    'dificultad_concentrar' => 2,
                    'preocupacion' => 1,
                ],
                'preguntas' => [
                    '¿Te cuesta trabajo dormirte?',
                    '¿Te despiertas varias veces?',
                    '¿Te sientes cansado durante el día?',
                    '¿Piensas mucho antes de dormir?',
                ],
            ],

            // OTROS COMUNES
            'conjuntivitis' => [
                'nombre' => 'Conjuntivitis',
                'categoria' => 'Oftalmológica',
                'frecuencia' => 'media',
                'sintomas' => [
                    'ojos_rojos' => 3,
                    'comezon_ojos' => 2,
                    'lagrimeo' => 2,
                    'secrecion_ojos' => 2,
                    'sensacion_arena' => 1,
                ],
                'preguntas' => [
                    '¿Tienes los ojos rojos?',
                    '¿Te pican los ojos?',
                    '¿Tienen los ojos secreción?',
                    '¿Te duele mirar la luz?',
                ],
            ],
            'caries_dental' => [
                'nombre' => 'Dolor Dental/Caries',
                'categoria' => 'Dental',
                'frecuencia' => 'media',
                'sintomas' => [
                    'dolor_diente' => 3,
                    'sensibilidad_dolor' => 2,
                    'inflamacion_encias' => 1,
                    'dolor_masticar' => 2,
                ],
                'preguntas' => [
                    '¿Te duele un diente?',
                    '¿Te duele al comer frío o dulce?',
                    '¿Te duele al masticar?',
                    '¿Cuándo fue tu última revisión dental?',
                ],
            ],
            'lesion_muscular' => [
                'nombre' => 'Lesión Muscular/Esguince',
                'categoria' => 'Traumatológica',
                'frecuencia' => 'alta',
                'sintomas' => [
                    'dolor_muscular' => 3,
                    'inflamacion' => 2,
                    'dificultad_moverse' => 2,
                    'moreton' => 1,
                    'dolor_agudo' => 2,
                ],
                'preguntas' => [
                    '¿Dónde te duele?',
                    '¿Tuviste un golpe o caída?',
                    '¿Hay inflamación?',
                    '¿Puedes mover la zona normalmente?',
                ],
            ],
            'deshidratacion' => [
                'nombre' => 'Deshidratación',
                'categoria' => 'General',
                'frecuencia' => 'media',
                'sintomas' => [
                    'sed_intensa' => 3,
                    'orina_oscura' => 3,
                    'cansancio' => 2,
                    'mareo' => 2,
                    'boca_seca' => 2,
                    'dolor_cabeza' => 1,
                ],
                'preguntas' => [
                    '¿Tienes mucha sed?',
                    '¿Tu orina es oscura?',
                    '¿Te sientes mareado?',
                    '¿Has bebido poca agua?',
                ],
            ],
        ];
    }

    /**
     * Factores de prioridad para clasificación IA 1
     */
    public static function getFactoresPrioridad(): array
    {
        return [
            // Síntomas de prioridad ALTA
            'alta' => [
                'dificultad_respirar_severa',
                'dolor_pecho_intenso',
                'desmayo',
                'confusion_mental',
                'sangrado',
                'convulsiones',
                'fiebre_muy_alta', // > 40°C
                'dolor_abdominal_agudo',
                'reaccion_alergica_severa',
            ],
            // Síntomas de prioridad MEDIA
            'media' => [
                'fiebre_moderada', // 38-40°C
                'dolor_moderado',
                'vomito_persistente',
                'diarrea_persistente',
                'tos_severa',
                'dolor_cabeza_severo',
                'dolor_pecho_moderado',
            ],
            // Prioridad BAJA (rutina)
            'baja' => [
                'resfriado_leve',
                'dolor_cabeza_leve',
                'estres',
                'ansiedad_moderada',
                'dolor_muscular_leve',
                'congestion_nasal',
                'dolor_garganta_leve',
                'acidez',
                'estreñimiento',
            ],
        ];
    }

    /**
     * Factores del historial que aumentan prioridad
     */
    public static function getFactoresHistorial(): array
    {
        return [
            'condiciones_cronicas' => [
                'diabetes',
                'hipertension',
                'asma',
                'alergias_graves',
                'enfermedad_cardiaca',
                'epilepsia',
                'depresion',
                'ansiedad_cronica',
            ],
            'visitas_frecuentes' => [
                'umbral_visitas_mes' => 3,
                'peso' => 2, // Multiplicador de prioridad
            ],
            'medicamentos_activos' => [
                'antidepresivos',
                'antihipertensivos',
                'insulina',
                'anticonvulsivos',
                'anticoagulantes',
            ],
        ];
    }

    /**
     * Genera dataset de entrenamiento dummy para el clasificador
     */
    public static function generarDatasetEntrenamiento(int $cantidad = 500): array
    {
        $dataset = [];
        $enfermedades = self::getEnfermedades();
        $prioridades = ['baja', 'media', 'alta'];

        for ($i = 0; $i < $cantidad; $i++) {
            $enfKey = array_rand($enfermedades);
            $enfermedad = $enfermedades[$enfKey];
            
            // Determinar prioridad basada en categoría y síntomas
            $prioridad = self::calcularPrioridadDummy($enfermedad);
            
            $dataset[] = [
                'id' => $i + 1,
                'edad' => rand(18, 35), // Rango universitario
                'sexo' => rand(0, 1) ? 'M' : 'F',
                'sintomas' => array_keys($enfermedad['sintomas']),
                'categoria' => $enfermedad['categoria'],
                'tiene_condicion_cronica' => rand(1, 10) <= 2, // 20%
                'visitas_previas_mes' => rand(0, 5),
                'prioridad_real' => $prioridad,
                'enfermedad' => $enfKey,
            ];
        }

        return $dataset;
    }

    private static function calcularPrioridadDummy(array $enfermedad): string
    {
        $prioridad = 'baja';
        
        // Enfermedades digestivas suelen ser media-alta
        if ($enfermedad['categoria'] === 'Digestiva') {
            $prioridad = rand(1, 3) === 1 ? 'alta' : 'media';
        }
        // Respiratorias leves son bajas, severas son medias
        elseif ($enfermedad['categoria'] === 'Respiratoria') {
            if (in_array($enfermedad['nombre'], ['Gripe/Influenza', 'Bronquitis'])) {
                $prioridad = 'media';
            } else {
                $prioridad = 'baja';
            }
        }
        // Mentales dependen de severidad
        elseif ($enfermedad['categoria'] === 'Mental') {
            $prioridad = rand(1, 4) === 1 ? 'media' : 'baja';
        }
        // Neurológicas con dolor severo son medias
        elseif ($enfermedad['categoria'] === 'Neurológica') {
            if (strpos($enfermedad['nombre'], 'Migraña') !== false) {
                $prioridad = rand(1, 2) === 1 ? 'media' : 'baja';
            } else {
                $prioridad = 'baja';
            }
        }
        
        return $prioridad;
    }
}
