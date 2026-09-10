<?php

namespace Tests\Feature;

use App\Models\Cita;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Pruebas de integración/feature para verificar que la cancelación o borrado lógico
 * de una cita libera el horario gracias al índice único parcial en PostgreSQL.
 */
class LiberacionDeSlotTest extends TestCase
{
    use RefreshDatabase;

    private string $fecha = '2028-10-16'; // Lunes
    private string $hora  = '10:00';

    private function alumno(): User
    {
        return User::factory()->create();
    }

    public function test_con_cita_programada_otro_alumno_no_puede_reservar_mismo_horario(): void
    {
        $alumno1 = $this->alumno();
        $alumno2 = $this->alumno();

        Sanctum::actingAs($alumno1);
        $this->postJson('/api/citas', [
            'fecha_cita' => $this->fecha,
            'hora_cita'  => $this->hora,
            'motivo'     => 'Consulta general',
        ])->assertCreated();

        Sanctum::actingAs($alumno2);
        $response = $this->postJson('/api/citas', [
            'fecha_cita' => $this->fecha,
            'hora_cita'  => $this->hora,
            'motivo'     => 'Revisión médica',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('message', 'El horario seleccionado ya no está disponible. Elige otra hora.');

        $this->assertDatabaseCount('citas', 1);
    }

    public function test_tras_cancelar_cita_otro_alumno_puede_reservar_el_mismo_horario(): void
    {
        $alumno1 = $this->alumno();
        $alumno2 = $this->alumno();

        Sanctum::actingAs($alumno1);
        $reservaOriginal = $this->postJson('/api/citas', [
            'fecha_cita' => $this->fecha,
            'hora_cita'  => $this->hora,
            'motivo'     => 'Dolor de cabeza',
        ])->assertCreated();

        $citaId = $reservaOriginal->json('cita.id');

        $this->postJson("/api/citas/{$citaId}/cancelar")
            ->assertOk()
            ->assertJsonPath('message', 'Cita cancelada exitosamente');

        Sanctum::actingAs($alumno2);
        $nuevaReserva = $this->postJson('/api/citas', [
            'fecha_cita' => $this->fecha,
            'hora_cita'  => $this->hora,
            'motivo'     => 'Fiebre',
        ]);

        $nuevaReserva->assertCreated()
            ->assertJsonPath('message', 'Cita agendada exitosamente');

        $this->assertDatabaseCount('citas', 2);
        $this->assertDatabaseHas('citas', ['id' => $citaId, 'estatus' => 'cancelada']);
        $this->assertDatabaseHas('citas', ['id' => $nuevaReserva->json('cita.id'), 'estatus' => 'programada']);
    }

    public function test_tras_borrado_logico_el_horario_queda_libre_para_otro_alumno(): void
    {
        $alumno1 = $this->alumno();
        $alumno2 = $this->alumno();

        Sanctum::actingAs($alumno1);
        $reserva = $this->postJson('/api/citas', [
            'fecha_cita' => $this->fecha,
            'hora_cita'  => $this->hora,
            'motivo'     => 'Chequeo',
        ])->assertCreated();

        $cita = Cita::findOrFail($reserva->json('cita.id'));
        $cita->delete();

        Sanctum::actingAs($alumno2);
        $nuevaReserva = $this->postJson('/api/citas', [
            'fecha_cita' => $this->fecha,
            'hora_cita'  => $this->hora,
            'motivo'     => 'Gripe',
        ]);

        $nuevaReserva->assertCreated();
        $this->assertSoftDeleted('citas', ['id' => $cita->id]);
    }

    public function test_se_pueden_tener_dos_citas_canceladas_en_el_mismo_horario(): void
    {
        $alumno1 = $this->alumno();
        $alumno2 = $this->alumno();

        Sanctum::actingAs($alumno1);
        $reserva1 = $this->postJson('/api/citas', [
            'fecha_cita' => $this->fecha,
            'hora_cita'  => $this->hora,
            'motivo'     => 'Primera cita',
        ])->assertCreated();

        $this->postJson('/api/citas/' . $reserva1->json('cita.id') . '/cancelar')->assertOk();

        Sanctum::actingAs($alumno2);
        $reserva2 = $this->postJson('/api/citas', [
            'fecha_cita' => $this->fecha,
            'hora_cita'  => $this->hora,
            'motivo'     => 'Segunda cita',
        ])->assertCreated();

        $this->postJson('/api/citas/' . $reserva2->json('cita.id') . '/cancelar')->assertOk();

        $this->assertDatabaseCount('citas', 2);
        $this->assertDatabaseHas('citas', ['id' => $reserva1->json('cita.id'), 'estatus' => 'cancelada']);
        $this->assertDatabaseHas('citas', ['id' => $reserva2->json('cita.id'), 'estatus' => 'cancelada']);
    }

    public function test_endpoint_disponibilidad_refleja_el_horario_como_libre_tras_cancelar(): void
    {
        $alumno = $this->alumno();
        Sanctum::actingAs($alumno);

        $reserva = $this->postJson('/api/citas', [
            'fecha_cita' => $this->fecha,
            'hora_cita'  => $this->hora,
            'motivo'     => 'Consulta de revisión',
        ])->assertCreated();

        $citaId = $reserva->json('cita.id');

        $dispAntes = $this->getJson('/api/citas/disponibilidad?month=10&year=2028')->assertOk();
        $daysAntes = collect($dispAntes->json('days'))->keyBy('date');
        $this->assertContains($this->hora, $daysAntes[$this->fecha]['taken_slots']);

        $this->postJson("/api/citas/{$citaId}/cancelar")->assertOk();

        $dispDespues = $this->getJson('/api/citas/disponibilidad?month=10&year=2028')->assertOk();
        $daysDespues = collect($dispDespues->json('days'))->keyBy('date');

        $takenSlots = $daysDespues->has($this->fecha) ? $daysDespues[$this->fecha]['taken_slots'] : [];
        $this->assertNotContains($this->hora, $takenSlots);
    }
}
