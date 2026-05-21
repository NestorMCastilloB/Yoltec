<?php

namespace Database\Seeders;

use App\Models\Bitacora;
use App\Models\Cita;
use App\Models\Consulta;
use App\Models\DiaEspecial;
use App\Models\PreEvaluacionIA;
use App\Models\Receta;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

/**
 * Seed integral para demos: limpia citas/bitacoras/recetas/consultas/pre-evaluaciones
 * y repuebla con data realista distribuida en el tiempo para que las 3 vistas
 * (alumno, doctor, admin) se vean completas. Conserva usuarios reales y dias especiales.
 *
 * Ejecutar: php artisan db:seed --class=DemoCompletoSeeder --force
 */
class DemoCompletoSeeder extends Seeder
{
    private array $doctoresData = [
        ['username' => 'doctorOmar',   'nombre' => 'Omar',   'apellido' => 'Gonzalez',  'email' => 'omar.gonzalez@yoltec.com',  'tel' => '4441234567'],
        ['username' => 'doctorCarlos', 'nombre' => 'Carlos', 'apellido' => 'Ramirez',   'email' => 'carlos.ramirez@yoltec.com', 'tel' => '4449876543'],
        ['username' => 'doctorLucia',  'nombre' => 'Lucia',  'apellido' => 'Hernandez', 'email' => 'lucia.hernandez@yoltec.com', 'tel' => '4445550101'],
    ];

    private array $alumnosData = [
        ['nc' => '22690495', 'nombre' => 'Nestor Moises', 'apellido' => 'Castillo Bautista', 'gen' => 'masculino', 'fn' => '2004-03-02'],
        ['nc' => '22690496', 'nombre' => 'Ana',        'apellido' => 'Lopez',     'gen' => 'femenino',  'fn' => '2004-08-20'],
        ['nc' => '22690497', 'nombre' => 'Pedro',      'apellido' => 'Martinez',  'gen' => 'masculino', 'fn' => '2004-03-10'],
        ['nc' => '22691001', 'nombre' => 'Maria',      'apellido' => 'Torres',    'gen' => 'femenino',  'fn' => '2003-11-14'],
        ['nc' => '22691002', 'nombre' => 'Juan',       'apellido' => 'Sanchez',   'gen' => 'masculino', 'fn' => '2002-06-08'],
        ['nc' => '22691003', 'nombre' => 'Laura',      'apellido' => 'Fernandez', 'gen' => 'femenino',  'fn' => '2004-01-22'],
        ['nc' => '22691004', 'nombre' => 'Roberto',    'apellido' => 'Diaz',      'gen' => 'masculino', 'fn' => '2003-09-30'],
        ['nc' => '22691005', 'nombre' => 'Sofia',      'apellido' => 'Vargas',    'gen' => 'femenino',  'fn' => '2004-05-17'],
        ['nc' => '22691006', 'nombre' => 'Diego',      'apellido' => 'Morales',   'gen' => 'masculino', 'fn' => '2002-12-03'],
        ['nc' => '22691007', 'nombre' => 'Valeria',    'apellido' => 'Rios',      'gen' => 'femenino',  'fn' => '2003-04-29'],
        ['nc' => '22691008', 'nombre' => 'Andres',     'apellido' => 'Gutierrez', 'gen' => 'masculino', 'fn' => '2003-07-11'],
        ['nc' => '22691009', 'nombre' => 'Camila',     'apellido' => 'Mendoza',   'gen' => 'femenino',  'fn' => '2004-02-25'],
        ['nc' => '22691010', 'nombre' => 'Jorge',      'apellido' => 'Castillo',  'gen' => 'masculino', 'fn' => '2002-10-19'],
        ['nc' => '22691011', 'nombre' => 'Daniela',    'apellido' => 'Rojas',     'gen' => 'femenino',  'fn' => '2004-08-07'],
        ['nc' => '22691012', 'nombre' => 'Miguel',     'apellido' => 'Cruz',      'gen' => 'masculino', 'fn' => '2003-01-13'],
        ['nc' => '22691013', 'nombre' => 'Fernanda',   'apellido' => 'Aguilar',   'gen' => 'femenino',  'fn' => '2003-06-26'],
        ['nc' => '22691014', 'nombre' => 'Eduardo',    'apellido' => 'Reyes',     'gen' => 'masculino', 'fn' => '2002-04-04'],
        ['nc' => '22691015', 'nombre' => 'Paola',      'apellido' => 'Jimenez',   'gen' => 'femenino',  'fn' => '2004-09-15'],
        ['nc' => '22691016', 'nombre' => 'Ricardo',    'apellido' => 'Vasquez',   'gen' => 'masculino', 'fn' => '2003-12-21'],
        ['nc' => '22691017', 'nombre' => 'Isabella',   'apellido' => 'Ortega',    'gen' => 'femenino',  'fn' => '2004-07-09'],
    ];

    private array $diagnosticos = [
        ['nombre' => 'Gripe / Influenza',         'tratamiento' => 'Reposo, hidratacion, paracetamol cada 8h por 3 dias.'],
        ['nombre' => 'Resfriado comun',           'tratamiento' => 'Vitamina C, liquidos calientes, descanso 48h.'],
        ['nombre' => 'Faringitis',                'tratamiento' => 'Gargaras con sal, antiinflamatorios, antibiotico si bacteriana.'],
        ['nombre' => 'Gastroenteritis',           'tratamiento' => 'Dieta blanda BRAT, suero oral, reposo intestinal.'],
        ['nombre' => 'Migrana',                   'tratamiento' => 'Analgesicos, descanso en oscuridad, evitar estimulos.'],
        ['nombre' => 'Cefalea tensional',         'tratamiento' => 'Masaje cervical, analgesicos leves, tecnicas de relajacion.'],
        ['nombre' => 'Ansiedad leve',             'tratamiento' => 'Tecnicas de respiracion, orientacion psicologica, seguimiento.'],
        ['nombre' => 'Alergia respiratoria',      'tratamiento' => 'Antihistaminicos orales, lavado nasal, evitar alergenos.'],
        ['nombre' => 'Bronquitis aguda',          'tratamiento' => 'Mucoliticos, hidratacion abundante, evitar irritantes.'],
        ['nombre' => 'Conjuntivitis viral',       'tratamiento' => 'Lagrimas artificiales, higiene ocular, no compartir toallas.'],
        ['nombre' => 'Dolor lumbar/contractura',  'tratamiento' => 'AINE topico, calor local, reposo relativo 48h.'],
        ['nombre' => 'Estres academico',          'tratamiento' => 'Organizacion del tiempo, ejercicio moderado, seguimiento.'],
        ['nombre' => 'Otitis externa',            'tratamiento' => 'Gotas oticas con antibiotico, evitar humedad.'],
        ['nombre' => 'Dermatitis de contacto',    'tratamiento' => 'Crema con hidrocortisona, evitar el alergeno identificado.'],
    ];

    private array $motivos = [
        'Dolor de cabeza frecuente', 'Malestar general con fiebre', 'Congestion nasal y estornudos',
        'Dolor de garganta', 'Nauseas y malestar estomacal', 'Revision general', 'Dolor de espalda',
        'Alergia', 'Tos persistente', 'Ansiedad y estres', 'Conjuntivitis', 'Dolor muscular',
        'Mareo y debilidad', 'Dolor de oido', 'Erupcion en la piel',
    ];

    private array $medicamentos = [
        'Paracetamol 500mg — 1 tableta cada 8 horas por 5 dias',
        'Ibuprofeno 400mg — 1 tableta cada 8 horas con alimentos',
        'Amoxicilina 500mg — 1 capsula cada 8 horas por 7 dias',
        'Loratadina 10mg — 1 tableta cada 24 horas',
        'Naproxeno 250mg — 1 tableta cada 12 horas con alimentos',
        'Metoclopramida 10mg — 1 tableta 30 min antes de comidas',
        'Cetirizina 10mg — 1 tableta al dia por 7 dias',
        'Omeprazol 20mg — 1 capsula en ayunas por 14 dias',
    ];

    private array $tiposSangre = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];

    public function run(): void
    {
        $this->command->warn('Limpieza: citas, bitacoras, recetas, consultas, pre_evaluaciones_ia.');

        DB::transaction(function () {
            PreEvaluacionIA::query()->delete();
            Receta::query()->delete();
            Consulta::query()->delete();
            Bitacora::query()->delete();
            Cita::withTrashed()->forceDelete();
        });

        $this->command->info('Tablas limpiadas. Insertando demo...');

        $doctores = $this->ensureDoctores();
        $alumnos  = $this->ensureAlumnos();
        $this->ensureDiasEspeciales();

        DB::transaction(function () use ($doctores, $alumnos) {
            $this->crearCitasPasadas($alumnos, $doctores);
            $this->crearCitasRecientes($alumnos, $doctores);
            $this->crearCitasHoy($alumnos, $doctores);
            $this->crearCitasFuturas($alumnos, $doctores);
            $this->crearPreEvaluaciones($alumnos, $doctores);
        });

        $this->resumen();
    }

    private function ensureDoctores(): array
    {
        $doctores = [];
        foreach ($this->doctoresData as $d) {
            $doctores[] = User::updateOrCreate(
                ['username' => $d['username']],
                [
                    'nombre'   => $d['nombre'],
                    'apellido' => $d['apellido'],
                    'email'    => $d['email'],
                    'password' => Hash::make('doctor123'),
                    'tipo'     => 'doctor',
                    'telefono' => $d['tel'],
                ]
            );
        }
        return $doctores;
    }

    private function ensureAlumnos(): array
    {
        $alumnos = [];
        foreach ($this->alumnosData as $i => $a) {
            $alumnos[] = User::updateOrCreate(
                ['numero_control' => $a['nc']],
                [
                    'nombre'                 => $a['nombre'],
                    'apellido'               => $a['apellido'],
                    'email'                  => strtolower(str_replace(' ', '', $a['nombre']) . '.' . $a['apellido']) . '@demo.edu',
                    'password'               => Hash::make('password123'),
                    'nip'                    => Hash::make(str_pad((string) (100000 + $i), 6, '0', STR_PAD_LEFT)),
                    'tipo'                   => 'alumno',
                    'telefono'               => '44' . str_pad((string) (10000000 + $i * 7), 8, '0', STR_PAD_LEFT),
                    'fecha_nacimiento'       => $a['fn'],
                    'genero'                 => $a['gen'],
                    'tipo_sangre'            => $this->tiposSangre[array_rand($this->tiposSangre)],
                    'alergias'               => $i % 3 === 0 ? 'Penicilina' : null,
                    'enfermedades_cronicas'  => $i % 5 === 0 ? 'Asma leve' : null,
                ]
            );
        }
        return $alumnos;
    }

    private function ensureDiasEspeciales(): void
    {
        if (DiaEspecial::count() >= 3) {
            return;
        }

        $hoy = Carbon::today();
        $base = [
            ['fecha' => $hoy->copy()->addDays(10)->toDateString(), 'tipo' => 'holiday',        'etiqueta' => 'Dia del estudiante',   'hora_cierre' => null],
            ['fecha' => $hoy->copy()->addDays(18)->toDateString(), 'tipo' => 'early_close',    'etiqueta' => 'Cierre temprano',       'hora_cierre' => '14:00'],
            ['fecha' => $hoy->copy()->addDays(25)->toDateString(), 'tipo' => 'holiday',        'etiqueta' => 'Capacitacion docente', 'hora_cierre' => null],
            ['fecha' => $hoy->copy()->addDays(40)->toDateString(), 'tipo' => 'early_close',    'etiqueta' => 'Junta general',         'hora_cierre' => '15:00'],
            ['fecha' => $hoy->copy()->addMonths(2)->toDateString(),'tipo' => 'holiday',        'etiqueta' => 'Receso semestral',      'hora_cierre' => null],
        ];

        foreach ($base as $d) {
            DiaEspecial::firstOrCreate(['fecha' => $d['fecha']], $d);
        }
    }

    private function crearCitasPasadas(array $alumnos, array $doctores): void
    {
        // 6 a 12 meses atras: atendidas, una que otra no_asistio
        for ($i = 0; $i < 25; $i++) {
            $fecha = $this->fechaHabilLaborable(Carbon::now()->subMonths(rand(6, 12)));
            $estatus = rand(1, 100) <= 85 ? 'atendida' : 'no_asistio';
            $this->crearCita($alumnos, $doctores, $fecha, $estatus);
        }
    }

    private function crearCitasRecientes(array $alumnos, array $doctores): void
    {
        // 1 a 5 meses atras: mas variedad
        for ($i = 0; $i < 30; $i++) {
            $fecha = $this->fechaHabilLaborable(Carbon::now()->subMonths(rand(1, 5)));
            $estatus = $this->sortear(['atendida' => 70, 'cancelada' => 20, 'no_asistio' => 10]);
            $this->crearCita($alumnos, $doctores, $fecha, $estatus);
        }
    }

    private function crearCitasHoy(array $alumnos, array $doctores): void
    {
        // Hoy: mezcla — algunas atendidas (manana), algunas confirmadas (tarde), 1 cancelada
        $hoy = $this->fechaHabilLaborable(Carbon::today());
        $horas = ['08:30', '09:15', '10:00', '11:30', '13:00', '15:00', '16:15'];
        foreach ($horas as $idx => $hora) {
            $estatus = match (true) {
                $idx < 3        => 'atendida',
                $idx === 3      => 'cancelada',
                default         => 'confirmada',
            };
            $this->crearCita($alumnos, $doctores, $hoy, $estatus, $hora);
        }
    }

    private function crearCitasFuturas(array $alumnos, array $doctores): void
    {
        // Proximas 4 semanas: confirmadas y programadas
        for ($i = 1; $i <= 18; $i++) {
            $fecha = $this->fechaHabilLaborable(Carbon::today()->addDays(rand(1, 28)));
            $estatus = rand(1, 100) <= 60 ? 'programada' : 'confirmada';
            $this->crearCita($alumnos, $doctores, $fecha, $estatus);
        }
    }

    private function crearCita(array $alumnos, array $doctores, Carbon $fecha, string $estatus, ?string $horaForzada = null): void
    {
        $alumno  = $alumnos[array_rand($alumnos)];
        $doctor  = $doctores[array_rand($doctores)];
        $diag    = $this->diagnosticos[array_rand($this->diagnosticos)];
        $motivo  = $this->motivos[array_rand($this->motivos)];
        $hora    = $horaForzada ?? sprintf('%02d:%02d', rand(8, 16), [0, 15, 30, 45][rand(0, 3)]);

        $cita = Cita::create([
            'clave_cita'          => Cita::generarClaveCita(),
            'alumno_id'           => $alumno->id,
            'doctor_id'           => $doctor->id,
            'fecha_cita'          => $fecha->toDateString(),
            'hora_cita'           => $hora,
            'motivo'              => $motivo,
            'estatus'             => $estatus,
            'fecha_hora_atencion' => $estatus === 'atendida'
                ? $fecha->copy()->setTimeFromTimeString($hora)->addMinutes(rand(5, 20))
                : null,
            'notas'               => $estatus === 'cancelada'
                ? 'Cancelacion por conflicto de horario del alumno.'
                : null,
            'created_at'          => $fecha->copy()->subDays(rand(1, 5)),
            'updated_at'          => $fecha,
        ]);

        if ($estatus === 'atendida') {
            $this->crearBitacoraYConsulta($cita, $alumno, $doctor, $diag, $fecha);
            if (rand(1, 100) <= 55) {
                $this->crearReceta($cita, $alumno, $doctor, $fecha);
            }
        }
    }

    private function crearBitacoraYConsulta(Cita $cita, User $alumno, User $doctor, array $diag, Carbon $fecha): void
    {
        $obs = 'Paciente responde adecuadamente al tratamiento inicial. Seguimiento opcional.';
        $peso = rand(50, 85) . ' kg';
        $altura = rand(155, 185) . ' cm';
        $temp = number_format(rand(365, 378) / 10, 1) . ' C';
        $presion = rand(110, 130) . '/' . rand(68, 85) . ' mmHg';

        Bitacora::create([
            'cita_id'          => $cita->id,
            'alumno_id'        => $alumno->id,
            'doctor_id'        => $doctor->id,
            'diagnostico'      => $diag['nombre'],
            'tratamiento'      => $diag['tratamiento'],
            'observaciones'    => $obs,
            'peso'             => $peso,
            'altura'           => $altura,
            'temperatura'      => $temp,
            'presion_arterial' => $presion,
            'created_at'       => $fecha,
            'updated_at'       => $fecha,
        ]);

        Consulta::create([
            'cita_id'       => $cita->id,
            'doctor_id'     => $doctor->id,
            'alumno_id'     => $alumno->id,
            'diagnostico'   => $diag['nombre'],
            'tratamiento'   => $diag['tratamiento'],
            'observaciones' => $obs,
            'created_at'    => $fecha,
            'updated_at'    => $fecha,
        ]);
    }

    private function crearReceta(Cita $cita, User $alumno, User $doctor, Carbon $fecha): void
    {
        Receta::create([
            'cita_id'      => $cita->id,
            'alumno_id'    => $alumno->id,
            'doctor_id'    => $doctor->id,
            'medicamentos' => $this->medicamentos[array_rand($this->medicamentos)],
            'indicaciones' => 'Tomar con alimentos. Suspender si hay reacciones adversas. Acudir si los sintomas persisten 72h.',
            'fecha_emision'=> $fecha,
            'created_at'   => $fecha,
            'updated_at'   => $fecha,
        ]);
    }

    private function crearPreEvaluaciones(array $alumnos, array $doctores): void
    {
        // Vincula a citas existentes (preferentemente proximas/hoy para que aparezcan en IA Prioridad)
        $citas = Cita::whereIn('estatus', ['programada', 'confirmada'])->inRandomOrder()->limit(10)->get();
        if ($citas->isEmpty()) return;

        $perfiles = [
            ['diag' => 'Posible infeccion respiratoria',  'conf' => 0.86, 'sint' => ['Fiebre', 'Tos seca', 'Dolor de garganta'],         'est' => 'pendiente'],
            ['diag' => 'Migrana sin aura',                'conf' => 0.78, 'sint' => ['Dolor pulsatil', 'Fotofobia', 'Nauseas'],          'est' => 'pendiente'],
            ['diag' => 'Gastroenteritis viral',           'conf' => 0.82, 'sint' => ['Diarrea', 'Nauseas', 'Dolor abdominal'],            'est' => 'validado'],
            ['diag' => 'Estres / ansiedad',               'conf' => 0.65, 'sint' => ['Insomnio', 'Cansancio', 'Dificultad para concentrarse'], 'est' => 'pendiente'],
            ['diag' => 'Alergia estacional',              'conf' => 0.73, 'sint' => ['Estornudos', 'Picazon ocular', 'Congestion nasal'], 'est' => 'validado'],
            ['diag' => 'Posible cuadro emergente',        'conf' => 0.91, 'sint' => ['Dolor toracico leve', 'Mareo', 'Sudoracion'],       'est' => 'pendiente'],
            ['diag' => 'Lumbalgia mecanica',              'conf' => 0.70, 'sint' => ['Dolor lumbar', 'Rigidez matutina'],                  'est' => 'descartado'],
            ['diag' => 'Conjuntivitis probable',          'conf' => 0.69, 'sint' => ['Ojo rojo', 'Secrecion', 'Picazon'],                  'est' => 'pendiente'],
            ['diag' => 'Sindrome gripal',                 'conf' => 0.84, 'sint' => ['Fiebre', 'Cefalea', 'Mialgias'],                     'est' => 'validado'],
            ['diag' => 'Dermatitis por contacto',         'conf' => 0.62, 'sint' => ['Eritema', 'Picazon localizada'],                     'est' => 'pendiente'],
        ];

        foreach ($citas as $i => $cita) {
            $p = $perfiles[$i % count($perfiles)];
            $doctorValida = $p['est'] !== 'pendiente' ? $doctores[array_rand($doctores)]->id : null;

            PreEvaluacionIA::create([
                'cita_id'              => $cita->id,
                'alumno_id'            => $cita->alumno_id,
                'respuestas'           => [
                    'tiempo_sintomas'   => ['1-3 dias', '3-7 dias', 'mas de 7 dias'][rand(0, 2)],
                    'intensidad_dolor'  => rand(3, 8),
                    'fiebre'            => (bool) rand(0, 1),
                    'medicacion_previa' => (bool) rand(0, 1),
                ],
                'diagnostico_sugerido' => $p['diag'],
                'confianza'            => $p['conf'],
                'sintomas_detectados'  => $p['sint'],
                'estatus_validacion'   => $p['est'],
                'validado_por'         => $doctorValida,
                'comentario_doctor'    => $p['est'] === 'validado'
                    ? 'Confirmado tras revision clinica.'
                    : ($p['est'] === 'descartado' ? 'Diagnostico final difiere; ver bitacora.' : null),
                'fecha_validacion'     => $doctorValida ? Carbon::now()->subDays(rand(0, 3)) : null,
            ]);
        }
    }

    private function fechaHabilLaborable(Carbon $base): Carbon
    {
        $fecha = $base->copy();
        while ($fecha->dayOfWeek === Carbon::SUNDAY) {
            $fecha->addDay();
        }
        return $fecha;
    }

    private function sortear(array $pesos): string
    {
        $rand = rand(1, 100);
        $acumulado = 0;
        foreach ($pesos as $estatus => $peso) {
            $acumulado += $peso;
            if ($rand <= $acumulado) return $estatus;
        }
        return array_key_first($pesos);
    }

    private function resumen(): void
    {
        $this->command->info(sprintf(
            'Listo. Alumnos=%d, Doctores=%d, Citas=%d, Bitacoras=%d, Consultas=%d, Recetas=%d, PreEvaluaciones=%d, DiasEspeciales=%d',
            User::where('tipo', 'alumno')->count(),
            User::where('tipo', 'doctor')->count(),
            Cita::count(),
            Bitacora::count(),
            Consulta::count(),
            Receta::count(),
            PreEvaluacionIA::count(),
            DiaEspecial::count(),
        ));
    }
}
