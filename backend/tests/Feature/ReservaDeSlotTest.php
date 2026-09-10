<?php

namespace Tests\Feature;

use App\Models\Cita;
use App\Models\User;
use App\Services\CitaService;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * La invariante que protege este archivo: un horario no puede tener dos citas
 * programadas a la vez. Antes dependía de una comprobación en PHP que no
 * resistía la concurrencia; ahora la garantiza un índice único parcial.
 */
class ReservaDeSlotTest extends TestCase
{
    use RefreshDatabase;

    private CitaService $servicio;
    private string $fecha = '2026-12-15';
    private string $hora  = '10:00';

    protected function setUp(): void
    {
        parent::setUp();
        $this->servicio = new CitaService();
    }

    private function alumno(): User
    {
        return User::factory()->create();
    }

    public function test_reserva_un_horario_libre(): void
    {
        $cita = $this->servicio->reservarSlot($this->fecha, $this->hora, 'Dolor de cabeza', $this->alumno()->id);

        $this->assertNotNull($cita);
        $this->assertSame('programada', $cita->estatus);
        $this->assertDatabaseCount('citas', 1);
    }

    public function test_el_segundo_alumno_no_puede_tomar_el_mismo_horario(): void
    {
        $this->servicio->reservarSlot($this->fecha, $this->hora, null, $this->alumno()->id);
        $segunda = $this->servicio->reservarSlot($this->fecha, $this->hora, null, $this->alumno()->id);

        $this->assertNull($segunda);
        $this->assertDatabaseCount('citas', 1);
    }

    public function test_la_base_rechaza_el_duplicado_aunque_la_aplicacion_falle(): void
    {
        // Se salta el servicio a propósito: comprueba que la garantía vive en la
        // base de datos y no en la comprobación de PHP, que es lo que fallaba
        // bajo concurrencia.
        $this->servicio->reservarSlot($this->fecha, $this->hora, null, $this->alumno()->id);
        $otro = $this->alumno();

        $this->expectException(UniqueConstraintViolationException::class);

        Cita::create([
            'fecha_cita' => $this->fecha,
            'hora_cita'  => $this->hora,
            'alumno_id'  => $otro->id,
            'clave_cita' => Cita::generarClaveCita(),
            'estatus'    => 'programada',
        ]);
    }

    public function test_cancelar_una_cita_libera_el_horario(): void
    {
        $primera = $this->servicio->reservarSlot($this->fecha, $this->hora, null, $this->alumno()->id);
        $primera->update(['estatus' => 'cancelada']);

        $segunda = $this->servicio->reservarSlot($this->fecha, $this->hora, null, $this->alumno()->id);

        $this->assertNotNull($segunda, 'Un horario cancelado debe poder reservarse otra vez');
        $this->assertDatabaseCount('citas', 2);
    }

    public function test_borrar_una_cita_libera_el_horario(): void
    {
        // Borrado lógico: la fila sigue en la tabla, pero no debe ocupar el hueco.
        $primera = $this->servicio->reservarSlot($this->fecha, $this->hora, null, $this->alumno()->id);
        $primera->delete();

        $segunda = $this->servicio->reservarSlot($this->fecha, $this->hora, null, $this->alumno()->id);

        $this->assertNotNull($segunda, 'Un horario liberado por borrado lógico debe poder reservarse otra vez');
    }

    public function test_horarios_distintos_del_mismo_dia_conviven(): void
    {
        $this->servicio->reservarSlot($this->fecha, '10:00', null, $this->alumno()->id);
        $this->servicio->reservarSlot($this->fecha, '10:15', null, $this->alumno()->id);

        $this->assertDatabaseCount('citas', 2);
    }

    public function test_la_migracion_cancela_los_duplicados_que_ya_existieran(): void
    {
        // Simula el estado que dejaba el bug: dos citas programadas en el mismo
        // hueco. Se inserta con el índice fuera para poder reproducirlo.
        DB::statement('DROP INDEX IF EXISTS citas_slot_programado_unico');

        $primera = $this->servicio->reservarSlot($this->fecha, $this->hora, null, $this->alumno()->id);
        $duplicada = Cita::create([
            'fecha_cita' => $this->fecha,
            'hora_cita'  => $this->hora,
            'alumno_id'  => $this->alumno()->id,
            'clave_cita' => Cita::generarClaveCita(),
            'estatus'    => 'programada',
        ]);

        // Se invoca el up() directamente: artisan migrate no repite una migración
        // que ya figura como aplicada, y aquí lo que se prueba es su contenido.
        $migracion = require database_path('migrations/2026_09_09_000001_add_unique_slot_index_to_citas.php');
        $migracion->up();

        // Se conserva la reserva más antigua, que fue la que llegó primero.
        $this->assertSame('programada', $primera->fresh()->estatus);
        $this->assertSame('cancelada', $duplicada->fresh()->estatus);
    }
}
