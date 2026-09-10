<?php

namespace Tests\Feature;

use App\Models\Cita;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Routing\Middleware\ThrottleRequests;
use Tests\TestCase;

/**
 * M-2: al agendar una cita, el alumno destinatario debe existir y ser alumno.
 * Antes, un doctor podía mandar cualquier `alumno_id` sin validar y la cita
 * quedaba colgada de un id arbitrario.
 */
class AgendarCitaValidaAlumnoTest extends TestCase
{
    use RefreshDatabase;

    private string $fecha = '2026-12-15'; // martes, día hábil
    private string $hora  = '10:00';

    protected function setUp(): void
    {
        parent::setUp();
        $this->withoutMiddleware(ThrottleRequests::class);
    }

    public function test_un_doctor_no_puede_agendar_con_un_alumno_id_inexistente(): void
    {
        $doctor = User::factory()->doctor()->create();

        $response = $this->actingAs($doctor)->postJson('/api/citas', [
            'fecha_cita' => $this->fecha,
            'hora_cita'  => $this->hora,
            'alumno_id'  => 999999,
        ]);

        $response->assertStatus(422);
        $this->assertDatabaseCount('citas', 0);
    }

    public function test_un_doctor_no_puede_agendar_a_nombre_de_otro_no_alumno(): void
    {
        $doctor = User::factory()->doctor()->create();
        $otroDoctor = User::factory()->doctor()->create();

        $response = $this->actingAs($doctor)->postJson('/api/citas', [
            'fecha_cita' => $this->fecha,
            'hora_cita'  => $this->hora,
            'alumno_id'  => $otroDoctor->id, // existe, pero no es alumno
        ]);

        $response->assertStatus(422);
        $this->assertDatabaseCount('citas', 0);
    }

    public function test_un_doctor_agenda_con_numero_control_valido(): void
    {
        $doctor = User::factory()->doctor()->create();
        $alumno = User::factory()->create();

        $response = $this->actingAs($doctor)->postJson('/api/citas', [
            'fecha_cita'     => $this->fecha,
            'hora_cita'      => $this->hora,
            'numero_control' => $alumno->numero_control,
        ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('citas', [
            'alumno_id' => $alumno->id,
            'estatus'   => 'programada',
        ]);
    }

    public function test_el_alumno_agenda_para_si_mismo_ignorando_un_alumno_id_ajeno(): void
    {
        $alumno = User::factory()->create();
        $otro   = User::factory()->create();

        $response = $this->actingAs($alumno)->postJson('/api/citas', [
            'fecha_cita' => $this->fecha,
            'hora_cita'  => $this->hora,
            'alumno_id'  => $otro->id, // debe ignorarse: el alumno agenda para sí
        ]);

        $response->assertStatus(201);
        $this->assertSame($alumno->id, Cita::first()->alumno_id);
    }
}
