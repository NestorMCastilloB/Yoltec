<?php

namespace Tests\Feature;

use App\IA\Services\IAService;
use App\Models\Bitacora;
use App\Models\Cita;
use App\Models\PreEvaluacionIA;
use App\Models\Receta;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * Protege el refactor del N+1: clasificar un listado de citas debe dar el
 * mismo resultado que clasificarlas una por una, y sin disparar un puñado de
 * consultas por cada cita.
 */
class ClasificacionEnLoteTest extends TestCase
{
    use RefreshDatabase;

    private function crearEscenario(): array
    {
        $alumnoA = User::factory()->create();
        $alumnoB = User::factory()->create();
        $doctor  = User::factory()->doctor()->create();

        $c1 = Cita::create([
            'clave_cita' => Cita::generarClaveCita(),
            'alumno_id'  => $alumnoA->id,
            'fecha_cita' => '2026-12-15',
            'hora_cita'  => '10:00',
            'motivo'     => 'Tengo mucha fiebre y tos',
            'estatus'    => 'programada',
        ]);

        // Historial de alumnoA colgado de su cita (bitacoras/recetas exigen cita_id).
        Bitacora::create([
            'cita_id'     => $c1->id,
            'alumno_id'   => $alumnoA->id,
            'doctor_id'   => $doctor->id,
            'diagnostico' => 'Cuadro de asma leve',
            'tratamiento' => 'Inhalador',
        ]);
        Receta::create([
            'cita_id'      => $c1->id,
            'alumno_id'    => $alumnoA->id,
            'doctor_id'    => $doctor->id,
            'medicamentos' => 'Salbutamol, Paracetamol',
            'indicaciones' => 'Cada 8 horas',
            'fecha_emision' => now()->toDateString(),
        ]);
        $c2 = Cita::create([
            'clave_cita' => Cita::generarClaveCita(),
            'alumno_id'  => $alumnoA->id,
            'fecha_cita' => '2026-12-15',
            'hora_cita'  => '11:00',
            'motivo'     => 'Dolor de cabeza',
            'estatus'    => 'programada',
        ]);
        $c3 = Cita::create([
            'clave_cita' => Cita::generarClaveCita(),
            'alumno_id'  => $alumnoB->id,
            'fecha_cita' => '2026-12-15',
            'hora_cita'  => '12:00',
            'motivo'     => 'Malestar general',
            'estatus'    => 'programada',
        ]);

        PreEvaluacionIA::create([
            'cita_id'              => $c1->id,
            'alumno_id'            => $alumnoA->id,
            'respuestas'           => ['dolor' => 'si'],
            'diagnostico_sugerido' => 'Gripe',
            'confianza'            => 0.80,
            'sintomas_detectados'  => ['fiebre', 'tos'],
            'estatus_validacion'   => 'pendiente',
        ]);

        return [$c1->id, $c2->id, $c3->id];
    }

    public function test_el_lote_da_el_mismo_resultado_que_una_por_una(): void
    {
        $ids = $this->crearEscenario();

        // Una por una.
        $servicioUno = new IAService();
        $unaPorUna = [];
        foreach ($ids as $id) {
            $r = $servicioUno->clasificarPrioridad($id);
            $unaPorUna[$id] = [$r['prioridad'], $r['puntuacion']];
        }

        // En lote.
        $citas = Cita::with('alumno')->whereIn('id', $ids)->get();
        $servicioLote = new IAService();
        $servicioLote->precargar($citas);
        $enLote = [];
        foreach ($citas as $cita) {
            $r = $servicioLote->clasificarPrioridadDeCita($cita);
            $enLote[$cita->id] = [$r['prioridad'], $r['puntuacion']];
        }

        $this->assertSame($unaPorUna, $enLote);
    }

    public function test_el_lote_no_dispara_consultas_por_cada_cita(): void
    {
        $ids = $this->crearEscenario();
        $citas = Cita::with('alumno')->whereIn('id', $ids)->get();

        $servicio = new IAService();

        DB::connection()->enableQueryLog();
        $servicio->precargar($citas);
        foreach ($citas as $cita) {
            $servicio->clasificarPrioridadDeCita($cita);
        }
        $consultas = count(DB::connection()->getQueryLog());
        DB::connection()->disableQueryLog();

        // Con 3 citas, el camino antiguo hacía ~21 consultas (7 por cita). El
        // precargado usa un número acotado que no crece con el número de citas.
        $this->assertLessThanOrEqual(12, $consultas,
            "El listado en lote hizo {$consultas} consultas; debería estar acotado.");
    }
}
