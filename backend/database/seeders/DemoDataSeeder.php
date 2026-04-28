<?php

namespace Database\Seeders;

use App\Models\Cita;
use App\Models\Bitacora;
use App\Models\Receta;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * Seeder de datos de demo para el panel del doctor.
 * Crea citas distribuidas en los últimos 6 meses para que las gráficas
 * del dashboard (barras por mes + donut por estado) se vean con datos reales.
 *
 * Es idempotente: no crea datos si ya existen suficientes citas para el doctor.
 */
class DemoDataSeeder extends Seeder
{
    private array $diagnosticos = [
        ['nombre' => 'Gripe / Influenza',         'tratamiento' => 'Reposo, hidratación, paracetamol cada 8h por 3 días.'],
        ['nombre' => 'Resfriado Común',            'tratamiento' => 'Vitamina C, líquidos calientes, descanso 48h.'],
        ['nombre' => 'Faringitis',                 'tratamiento' => 'Gárgaras con sal, antiinflamatorios, antibiótico si bacteriana.'],
        ['nombre' => 'Gastroenteritis',            'tratamiento' => 'Dieta blanda BRAT, suero oral, reposo intestinal.'],
        ['nombre' => 'Migraña',                    'tratamiento' => 'Analgésicos, descanso en oscuridad, evitar estímulos.'],
        ['nombre' => 'Cefalea tensional',          'tratamiento' => 'Masaje cervical, analgésicos leves, técnicas de relajación.'],
        ['nombre' => 'Ansiedad leve',              'tratamiento' => 'Técnicas de respiración, orientación psicológica, seguimiento.'],
        ['nombre' => 'Alergia respiratoria',       'tratamiento' => 'Antihistamínicos orales, lavado nasal, evitar alérgenos.'],
        ['nombre' => 'Bronquitis aguda',           'tratamiento' => 'Mucolíticos, hidratación abundante, evitar irritantes.'],
        ['nombre' => 'Conjuntivitis viral',        'tratamiento' => 'Lágrimas artificiales, higiene ocular, no compartir toallas.'],
        ['nombre' => 'Dolor lumbar / contractura', 'tratamiento' => 'AINE tópico, calor local, reposo relativo 48h.'],
        ['nombre' => 'Estrés académico',           'tratamiento' => 'Organización del tiempo, ejercicio moderado, seguimiento.'],
    ];

    private array $motivos = [
        'Dolor de cabeza frecuente',
        'Malestar general con fiebre',
        'Congestión nasal y estornudos',
        'Dolor de garganta',
        'Náuseas y malestar estomacal',
        'Revisión general',
        'Dolor de espalda',
        'Alergia',
        'Tos persistente',
        'Ansiedad y estrés',
        'Conjuntivitis',
        'Dolor muscular',
    ];

    private array $medicamentos = [
        'Paracetamol 500mg — 1 tableta cada 8 horas por 5 días',
        'Ibuprofeno 400mg — 1 tableta cada 8 horas con alimentos',
        'Amoxicilina 500mg — 1 cápsula cada 8 horas por 7 días',
        'Loratadina 10mg — 1 tableta cada 24 horas',
        'Naproxeno 250mg — 1 tableta cada 12 horas con alimentos',
        'Metoclopramida 10mg — 1 tableta 30 min antes de comidas',
    ];

    public function run(): void
    {
        $doctor = User::where('username', 'doctorOmar')->first();

        if (! $doctor) {
            $this->command->warn('doctorOmar no encontrado. Ejecuta primero: php artisan db:seed');
            return;
        }

        // Evitar duplicar datos si el seeder ya se ejecutó
        $citasExistentes = Cita::where('doctor_id', $doctor->id)->count();
        if ($citasExistentes >= 25) {
            $this->command->info("Ya existen {$citasExistentes} citas para doctorOmar. Seeder omitido.");
            return;
        }

        $this->command->info('Creando datos de demo para el dashboard...');

        $alumnos = $this->obtenerOCrearAlumnos();

        // Distribuir citas en los últimos 6 meses (5-8 citas por mes)
        $citasPorMes = [6, 7, 5, 8, 6, 7]; // meses 5 a 0 (el más reciente al final)
        $mesOffset = 5;

        foreach ($citasPorMes as $numCitas) {
            $this->crearCitasDelMes($alumnos, $doctor, $mesOffset, $numCitas);
            $mesOffset--;
        }

        // Unas pocas citas futuras (programadas)
        $this->crearCitasFuturas($alumnos, $doctor, 4);

        $total = Cita::where('doctor_id', $doctor->id)->count();
        $this->command->info("Listo. Total citas para doctorOmar: {$total}");
    }

    private function obtenerOCrearAlumnos(): array
    {
        // Usar el alumno principal de prueba
        $alumnoBase = User::where('numero_control', '22690495')->first();

        // Crear alumnos extra si no existen
        $extrasData = [
            ['nombre' => 'Ana',      'apellido' => 'García',     'nc' => '21110001', 'nip' => '111111'],
            ['nombre' => 'Carlos',   'apellido' => 'Martínez',   'nc' => '21110002', 'nip' => '222222'],
            ['nombre' => 'María',    'apellido' => 'Torres',     'nc' => '21110003', 'nip' => '333333'],
            ['nombre' => 'Juan',     'apellido' => 'Sánchez',    'nc' => '21110004', 'nip' => '444444'],
            ['nombre' => 'Laura',    'apellido' => 'Fernández',  'nc' => '21110005', 'nip' => '555555'],
            ['nombre' => 'Roberto',  'apellido' => 'Díaz',       'nc' => '21110006', 'nip' => '666666'],
        ];

        $alumnos = $alumnoBase ? [$alumnoBase] : [];

        foreach ($extrasData as $datos) {
            $alumno = User::firstOrCreate(
                ['numero_control' => $datos['nc']],
                [
                    'nombre'   => $datos['nombre'],
                    'apellido' => $datos['apellido'],
                    'email'    => strtolower($datos['nombre'] . '.' . $datos['apellido']) . '@demo.edu',
                    'password' => Hash::make($datos['nip']),
                    'nip'      => Hash::make($datos['nip']),
                    'tipo'     => 'alumno',
                ]
            );
            $alumnos[] = $alumno;
        }

        return $alumnos;
    }

    private function crearCitasDelMes(array $alumnos, User $doctor, int $mesAtras, int $cantidad): void
    {
        // En meses pasados la mayoría son atendidas/canceladas (no programadas)
        $estatusPasados = [
            'atendida'   => 65,
            'cancelada'  => 20,
            'no_asistio' => 15,
        ];

        for ($i = 0; $i < $cantidad; $i++) {
            $alumno = $alumnos[array_rand($alumnos)];
            $diagnosticoIdx = array_rand($this->diagnosticos);
            $diagnostico = $this->diagnosticos[$diagnosticoIdx];
            $motivo = $this->motivos[array_rand($this->motivos)];

            // Fecha aleatoria dentro del mes
            $diaBase = now()->subMonths($mesAtras);
            $diaMin = (int) $diaBase->copy()->startOfMonth()->diffInDays(now()->subMonths($mesAtras + 1)->endOfMonth());
            $fechaCita = $diaBase->copy()->startOfMonth()->addDays(rand(0, (int) $diaBase->daysInMonth - 1));

            // Asegurarse que no sea domingo
            while ($fechaCita->dayOfWeek === 0) {
                $fechaCita->addDay();
            }

            $hora = sprintf('%02d:%02d', rand(8, 16), [0, 15, 30, 45][rand(0, 3)]);
            $estatus = $this->sortearEstatus($estatusPasados);

            $cita = Cita::create([
                'clave_cita'          => Cita::generarClaveCita(),
                'alumno_id'           => $alumno->id,
                'doctor_id'           => $doctor->id,
                'fecha_cita'          => $fechaCita->toDateString(),
                'hora_cita'           => $hora,
                'motivo'              => $motivo,
                'estatus'             => $estatus,
                'fecha_hora_atencion' => $estatus === 'atendida'
                    ? $fechaCita->copy()->setTimeFromTimeString($hora)->addMinutes(rand(5, 20))
                    : null,
                'created_at'          => $fechaCita,
                'updated_at'          => $fechaCita,
            ]);

            if ($estatus === 'atendida') {
                $this->crearBitacora($cita, $alumno, $doctor, $diagnostico, $fechaCita);
            }
        }
    }

    private function crearCitasFuturas(array $alumnos, User $doctor, int $cantidad): void
    {
        for ($i = 1; $i <= $cantidad; $i++) {
            $alumno = $alumnos[array_rand($alumnos)];
            $motivo = $this->motivos[array_rand($this->motivos)];
            $fechaCita = now()->addDays($i * 2);

            while ($fechaCita->dayOfWeek === 0) {
                $fechaCita->addDay();
            }

            Cita::create([
                'clave_cita' => Cita::generarClaveCita(),
                'alumno_id'  => $alumno->id,
                'doctor_id'  => $doctor->id,
                'fecha_cita' => $fechaCita->toDateString(),
                'hora_cita'  => sprintf('%02d:%02d', rand(8, 16), [0, 15, 30][rand(0, 2)]),
                'motivo'     => $motivo,
                'estatus'    => 'programada',
            ]);
        }
    }

    private function crearBitacora(Cita $cita, User $alumno, User $doctor, array $diagnostico, $fecha): void
    {
        Bitacora::create([
            'cita_id'          => $cita->id,
            'alumno_id'        => $alumno->id,
            'doctor_id'        => $doctor->id,
            'diagnostico'      => $diagnostico['nombre'],
            'tratamiento'      => $diagnostico['tratamiento'],
            'observaciones'    => 'Paciente con buena respuesta al tratamiento inicial.',
            'peso'             => rand(50, 85) . ' kg',
            'altura'           => rand(155, 185) . ' cm',
            'temperatura'      => number_format(rand(365, 378) / 10, 1) . ' °C',
            'presion_arterial' => rand(110, 130) . '/' . rand(68, 85) . ' mmHg',
            'created_at'       => $fecha,
            'updated_at'       => $fecha,
        ]);

        // 40% de probabilidad de crear receta
        if (rand(1, 100) <= 40) {
            Receta::create([
                'cita_id'      => $cita->id,
                'alumno_id'    => $alumno->id,
                'doctor_id'    => $doctor->id,
                'medicamentos' => $this->medicamentos[array_rand($this->medicamentos)],
                'indicaciones' => 'Tomar con alimentos. Suspender si hay reacciones adversas.',
                'fecha_emision'=> $fecha,
                'created_at'   => $fecha,
                'updated_at'   => $fecha,
            ]);
        }
    }

    private function sortearEstatus(array $pesos): string
    {
        $rand = rand(1, 100);
        $acumulado = 0;
        foreach ($pesos as $estatus => $peso) {
            $acumulado += $peso;
            if ($rand <= $acumulado) {
                return $estatus;
            }
        }
        return 'atendida';
    }
}
