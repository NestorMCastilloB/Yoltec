<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Cita;
use App\Models\Bitacora;
use App\Models\Receta;
use App\Models\PreEvaluacionIA;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * Seeder para crear datos de prueba de la IA
 * Incluye citas, bitácoras y pre-evaluaciones de ejemplo
 */
class IADummyDataSeeder extends Seeder
{
    /**
     * Enfermedades comunes de doctor general en universidad
     */
    private array $diagnosticosComunes = [
        'Gripe/Influenza' => ['fiebre', 'dolor_cabeza', 'dolor_muscular', 'tos'],
        'Resfriado Común' => ['congestion_nasal', 'estornudos', 'dolor_garganta'],
        'Faringitis' => ['dolor_garganta', 'fiebre', 'dolor_tragar'],
        'Gastroenteritis' => ['diarrea', 'vomito', 'dolor_abdominal'],
        'Migraña' => ['dolor_cabeza_intenso', 'sensibilidad_luz', 'nauseas'],
        'Cefalea por Tensión' => ['dolor_cabeza_opresivo', 'tension_cuello', 'estres'],
        'Ansiedad' => ['preocupacion_excesiva', 'nerviosismo', 'taquicardia'],
        'Estrés' => ['agotamiento', 'dificultad_dormir', 'irritabilidad'],
        'Alergia Respiratoria' => ['estornudos', 'picazon_nariz', 'ojos_llorosos'],
        'Bronquitis' => ['tos_con_flema', 'fatiga', 'dolor_pecho'],
        'Conjuntivitis' => ['ojos_rojos', 'comezon_ojos', 'lagrimeo'],
        'Intoxicación Alimentaria' => ['vomito', 'diarrea', 'dolor_abdominal_intenso'],
    ];

    private array $tratamientos = [
        'Gripe/Influenza' => 'Reposo en cama, hidratación abundante, paracetamol cada 8h por 3 días.',
        'Resfriado Común' => 'Vitamina C, líquidos calientes, descanso.',
        'Faringitis' => 'Gárgaras con sal, antiinflamatorios, si es bacteriana: amoxicilina.',
        'Gastroenteritis' => 'Dieta blanda (BRAT), hidratación oral, reposo intestinal.',
        'Migraña' => 'Analgésicos específicos, descanso en oscuridad, evitar estímulos.',
        'Cefalea por Tensión' => 'Masaje cervical, analgésicos leves, técnicas de relajación.',
        'Ansiedad' => 'Técnicas de respiración, terapia psicológica, seguimiento.',
        'Estrés' => 'Manejo del tiempo, ejercicio moderado, técnicas de relajación.',
        'Alergia Respiratoria' => 'Antihistamínicos, evitar alérgenos, lavado nasal.',
        'Bronquitis' => 'Mucolíticos, hidratación, evitar irritantes.',
        'Conjuntivitis' => 'Lágrimas artificiales, higiene ocular, no compartir toallas.',
        'Intoxicación Alimentaria' => 'Hidratación intensiva, dieta blanda, reposo.',
    ];

    public function run(): void
    {
        $this->command->info('🌱 Creando datos de prueba para IA...');

        // Crear alumnos de prueba
        $alumnos = $this->crearAlumnos();
        
        // Crear doctor si no existe
        $doctor = $this->crearDoctor();

        // Crear citas y bitácoras de ejemplo
        $this->crearHistorialMedico($alumnos, $doctor);

        // Crear algunas citas pendientes con pre-evaluaciones
        $this->crearCitasPendientes($alumnos, $doctor);

        $this->command->info('✅ Datos de prueba creados exitosamente!');
        $this->command->info('   - Alumnos de prueba: ' . count($alumnos));
        $this->command->info('   - Doctor de prueba: ' . $doctor->email);
        $this->command->info('   - Usa: php artisan ia:entrenar para entrenar los modelos');
    }

    private function crearAlumnos(): array
    {
        $alumnos = [];
        
        $nombres = [
            ['name' => 'Ana García López', 'nc' => '19120001'],
            ['name' => 'Carlos Martínez Ruiz', 'nc' => '19120002'],
            ['name' => 'María Elena Torres', 'nc' => '19120003'],
            ['name' => 'Juan Pedro Sánchez', 'nc' => '19120004'],
            ['name' => 'Laura Fernández', 'nc' => '19120005'],
            ['name' => 'Roberto Díaz', 'nc' => '19120006'],
            ['name' => 'Patricia Mendoza', 'nc' => '19120007'],
            ['name' => 'Fernando Castillo', 'nc' => '19120008'],
        ];

        foreach ($nombres as $datos) {
            $alumno = User::firstOrCreate(
                ['numero_control' => $datos['nc']],
                [
                    'name' => $datos['name'],
                    'email' => strtolower(str_replace(' ', '.', $datos['name'])) . '@universidad.edu',
                    'password' => Hash::make('password123'),
                    'tipo' => 'alumno',
                    'telefono' => '444' . rand(1000000, 9999999),
                ]
            );
            $alumnos[] = $alumno;
        }

        return $alumnos;
    }

    private function crearDoctor(): User
    {
        return User::firstOrCreate(
            ['email' => 'doctor@universidad.edu'],
            [
                'name' => 'Dr. José Hernández Gómez',
                'numero_control' => 'DOC001',
                'password' => Hash::make('password123'),
                'tipo' => 'doctor',
                'telefono' => '4445556666',
            ]
        );
    }

    private function crearHistorialMedico(array $alumnos, User $doctor): void
    {
        $this->command->info('   📋 Creando historial médico de ejemplo...');

        foreach ($alumnos as $alumno) {
            // Crear entre 1 y 5 citas atendidas por alumno
            $numCitas = rand(1, 5);
            
            for ($i = 0; $i < $numCitas; $i++) {
                $diagnosticoNombre = array_rand($this->diagnosticosComunes);
                $sintomas = $this->diagnosticosComunes[$diagnosticoNombre];
                
                // Fecha aleatoria en los últimos 6 meses
                $fechaCita = now()->subDays(rand(7, 180));
                
                $cita = Cita::create([
                    'clave_cita' => Cita::generarClaveCita(),
                    'alumno_id' => $alumno->id,
                    'doctor_id' => $doctor->id,
                    'fecha_cita' => $fechaCita,
                    'hora_cita' => sprintf('%02d:%02d', rand(8, 17), [0, 30][rand(0, 1)]),
                    'motivo' => 'Consulta por ' . strtolower($diagnosticoNombre),
                    'estatus' => 'atendida',
                    'fecha_hora_atencion' => $fechaCita->copy()->addMinutes(rand(1, 30)),
                    'created_at' => $fechaCita,
                    'updated_at' => $fechaCita,
                ]);

                // Crear bitácora
                Bitacora::create([
                    'cita_id' => $cita->id,
                    'alumno_id' => $alumno->id,
                    'doctor_id' => $doctor->id,
                    'diagnostico' => $diagnosticoNombre,
                    'tratamiento' => $this->tratamientos[$diagnosticoNombre],
                    'observaciones' => 'Paciente con buena respuesta al tratamiento. Seguimiento en caso de recaída.',
                    'peso' => rand(50, 85) . ' kg',
                    'altura' => rand(160, 185) . ' cm',
                    'temperatura' => (rand(365, 375) / 10) . ' °C',
                    'presion_arterial' => rand(110, 130) . '/' . rand(70, 85) . ' mmHg',
                    'created_at' => $fechaCita,
                    'updated_at' => $fechaCita,
                ]);

                // 30% de probabilidad de crear receta
                if (rand(1, 100) <= 30) {
                    Receta::create([
                        'cita_id' => $cita->id,
                        'alumno_id' => $alumno->id,
                        'doctor_id' => $doctor->id,
                        'medicamentos' => 'Paracetamol 500mg, Ibuprofeno 400mg',
                        'indicaciones' => 'Tomar cada 8 horas después de los alimentos.',
                        'fecha_emision' => $fechaCita,
                        'created_at' => $fechaCita,
                        'updated_at' => $fechaCita,
                    ]);
                }
            }
        }
    }

    private function crearCitasPendientes(array $alumnos, User $doctor): void
    {
        $this->command->info('   📅 Creando citas pendientes con pre-evaluaciones...');

        // Seleccionar 4 alumnos aleatorios para citas pendientes
        $alumnosPendientes = array_slice($alumnos, 0, 4);

        foreach ($alumnosPendientes as $index => $alumno) {
            $diagnosticoNombre = array_rand($this->diagnosticosComunes);
            $sintomas = $this->diagnosticosComunes[$diagnosticoNombre];
            
            // Fecha futura próxima
            $fechaCita = now()->addDays(rand(1, 7));
            
            $cita = Cita::create([
                'clave_cita' => Cita::generarClaveCita(),
                'alumno_id' => $alumno->id,
                'doctor_id' => null, // Se asigna al atender
                'fecha_cita' => $fechaCita,
                'hora_cita' => sprintf('%02d:%02d', rand(8, 17), [0, 30][rand(0, 1)]),
                'motivo' => 'Consulta por ' . strtolower($diagnosticoNombre),
                'estatus' => 'programada',
            ]);

            // Crear pre-evaluación IA para algunas citas
            if ($index < 3) { // 3 de 4 tendrán pre-evaluación
                $respuestas = [];
                foreach ($sintomas as $sintoma) {
                    $respuestas[] = [
                        'sintoma_relacionado' => $sintoma,
                        'respuesta' => 'si',
                    ];
                }

                // Detectar posibles enfermedades basadas en síntomas
                $posibles = $this->detectarEnfermedades($sintomas);

                PreEvaluacionIA::create([
                    'cita_id' => $cita->id,
                    'alumno_id' => $alumno->id,
                    'respuestas' => $respuestas,
                    'sintomas_detectados' => $sintomas,
                    'posibles_enfermedades' => $posibles,
                    'confianza' => rand(60, 90) / 100,
                ]);
            }
        }
    }

    private function detectarEnfermedades(array $sintomas): array
    {
        $coincidencias = [];
        
        foreach ($this->diagnosticosComunes as $enfermedad => $sintomasEnf) {
            $coincidencia = count(array_intersect($sintomas, $sintomasEnf));
            $totalSintomas = count($sintomasEnf);
            $porcentaje = $totalSintomas > 0 ? ($coincidencia / $totalSintomas) * 100 : 0;
            
            if ($porcentaje > 30) {
                $coincidencias[] = [
                    'enfermedad_key' => $this->keyFromName($enfermedad),
                    'nombre' => $enfermedad,
                    'probabilidad' => round($porcentaje, 2),
                    'sintomas_coincidentes' => array_intersect($sintomas, $sintomasEnf),
                ];
            }
        }

        // Ordenar por probabilidad
        usort($coincidencias, fn($a, $b) => $b['probabilidad'] <=> $a['probabilidad']);
        
        return array_slice($coincidencias, 0, 3);
    }

    private function keyFromName(string $name): string
    {
        return strtolower(str_replace(['/', ' '], ['_', '_'], $name));
    }
}
