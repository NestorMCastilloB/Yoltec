<?php

namespace Tests\Feature;

use App\Models\Cita;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Prueba de Feature que verifica la invariante de seguridad principal:
 * el control de acceso basado en roles y el aislamiento de información
 * confidencial entre usuarios del mismo rol.
 *
 * Roles evaluados: alumno, doctor, admin y usuario sin autenticar.
 */
class AislamientoDeRolesTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Data provider para rutas reservadas para doctores.
     */
    public static function rutasDoctorProvider(): array
    {
        return [
            'reprogramar cita' => ['PUT', '/api/citas/1/reprogramar', ['fecha_cita' => '2026-12-20', 'hora_cita' => '10:00']],
            'atender cita'     => ['POST', '/api/citas/1/atender', []],
            'registrar consulta' => ['POST', '/api/citas/1/consulta', ['diagnostico' => 'Diagnostico test', 'tratamiento' => 'Tratamiento test', 'observaciones' => 'Obs']],
            'buscar alumnos'   => ['GET', '/api/alumnos/buscar?q=juan', []],
            'crear bitácora'   => ['POST', '/api/bitacoras', [
                'cita_id' => 1, 'diagnostico' => 'Dx', 'tratamiento' => 'Tx', 'observaciones' => 'Obs',
                'peso' => '70', 'altura' => '170', 'temperatura' => '36', 'presion_arterial' => '120/80',
            ]],
            'crear receta'     => ['POST', '/api/recetas', [
                'cita_id' => 1, 'medicamentos' => 'Paracetamol', 'indicaciones' => '1 cada 8h', 'fecha_emision' => '2026-12-20',
            ]],
            'ver estadísticas' => ['GET', '/api/estadisticas', []],
            'ver pendientes IA priority' => ['GET', '/api/ia/priority/pendientes', []],
        ];
    }

    /**
     * Data provider para rutas reservadas para administradores.
     */
    public static function rutasAdminProvider(): array
    {
        return [
            'stats de admin'    => ['GET', '/api/admin/stats', []],
            'listar alumnos'    => ['GET', '/api/admin/alumnos', []],
            'crear doctor'      => ['POST', '/api/admin/doctores', [
                'nombre' => 'Doc', 'apellido' => 'Test', 'email' => 'doc@test.com', 'username' => 'doctest', 'password' => 'Password123!',
            ]],
            'listar sesiones'   => ['GET', '/api/admin/sesiones', []],
        ];
    }

    /**
     * Data provider para muestra representativa de rutas protegidas que requieren autenticación.
     */
    public static function rutasProtegidasSinAuthProvider(): array
    {
        return [
            'me'                     => ['GET', '/api/me'],
            'perfil'                 => ['GET', '/api/perfil'],
            'citas'                  => ['GET', '/api/citas'],
            'estadísticas doctor'    => ['GET', '/api/estadisticas'],
            'stats admin'            => ['GET', '/api/admin/stats'],
            'pendientes IA priority' => ['GET', '/api/ia/priority/pendientes'],
        ];
    }

    /**
     * Comprueba que un ALUMNO autenticado recibe 403 (Forbidden) al intentar acceder a rutas de DOCTOR.
     *
     * @dataProvider rutasDoctorProvider
     */
    public function test_alumno_recibe_403_en_rutas_de_doctor(string $metodo, string $uri, array $payload = []): void
    {
        $alumno = User::factory()->create();

        $response = $this->actingAs($alumno)->json($metodo, $uri, $payload);

        $response->assertStatus(403);
    }

    /**
     * Comprueba que un ALUMNO autenticado recibe 403 (Forbidden) al intentar acceder al bloque de ADMIN.
     *
     * @dataProvider rutasAdminProvider
     */
    public function test_alumno_recibe_403_en_bloque_de_admin(string $metodo, string $uri, array $payload = []): void
    {
        $alumno = User::factory()->create();

        $response = $this->actingAs($alumno)->json($metodo, $uri, $payload);

        $response->assertStatus(403);
    }

    /**
     * Comprueba que un DOCTOR autenticado recibe 403 (Forbidden) al intentar acceder al bloque de ADMIN.
     *
     * @dataProvider rutasAdminProvider
     */
    public function test_doctor_recibe_403_en_bloque_de_admin(string $metodo, string $uri, array $payload = []): void
    {
        $doctor = User::factory()->doctor()->create();

        $response = $this->actingAs($doctor)->json($metodo, $uri, $payload);

        $response->assertStatus(403);
    }

    /**
     * Comprueba que un usuario SIN autenticar recibe 401 (Unauthorized) en una muestra representativa de rutas protegidas.
     *
     * @dataProvider rutasProtegidasSinAuthProvider
     */
    public function test_usuario_sin_autenticar_recibe_401_en_rutas_protegidas(string $metodo, string $uri): void
    {
        $response = $this->json($metodo, $uri);

        $response->assertStatus(401);
    }

    /**
     * Comprueba el aislamiento entre iguales: un alumno NO puede consultar la cita de otro alumno.
     */
    public function test_alumno_no_puede_ver_cita_de_otro_alumno(): void
    {
        $alumnoA = User::factory()->create();
        $alumnoB = User::factory()->create();

        $citaB = Cita::create([
            'fecha_cita' => '2026-12-25',
            'hora_cita'  => '11:00',
            'alumno_id'  => $alumnoB->id,
            'clave_cita' => Cita::generarClaveCita(),
            'estatus'    => 'programada',
            'motivo'     => 'Consulta confidencial alumno B',
        ]);

        $response = $this->actingAs($alumnoA)->getJson("/api/citas/{$citaB->id}");

        $response->assertStatus(403);
    }

    /**
     * Comprueba el aislamiento entre iguales en perfil médico e historial.
     *
     * HALLAZGO DE SEGURIDAD / DISEÑO:
     * Las rutas `GET /api/perfil-medico/alumno/{id}` y `GET /api/perfil-medico/alumno/{id}/historial`
     * fueron diseñadas en las rutas de api.php para que un doctor consulte el expediente de un alumno,
     * pero NO están bajo el middleware `role:doctor`.
     *
     * Cuando un alumno (alumnoA) realiza la petición pasando la ID de otro alumno (alumnoB),
     * el controlador `PerfilMedicoController` evalúa `$user->esAlumno()` y, en lugar de retornar
     * 403 Forbidden por no tener rol de doctor, ignora el parámetro `$id` de la URL y devuelve
     * los datos del propio alumnoA con status 200 OK.
     *
     * Esta prueba verifica la invariante de que alumnoA NO puede leer la información privada de alumnoB.
     */
    public function test_alumno_no_puede_leer_perfil_medico_ni_historial_de_otro_alumno(): void
    {
        $alumnoA = User::factory()->create([
            'email' => 'alumnoA@yoltec.test',
        ]);
        $alumnoB = User::factory()->create([
            'email' => 'alumnoB_privado@yoltec.test',
        ]);

        // Intento de consultar el perfil médico de alumnoB por parte de alumnoA
        $responsePerfil = $this->actingAs($alumnoA)->getJson("/api/perfil-medico/alumno/{$alumnoB->id}");
        $responsePerfil->assertOk();
        $responsePerfil->assertJsonMissing(['email' => 'alumnoB_privado@yoltec.test']);
        $this->assertEquals($alumnoA->id, $responsePerfil->json('perfil.id'));

        // Intento de consultar el historial médico de alumnoB por parte de alumnoA
        $responseHistorial = $this->actingAs($alumnoA)->getJson("/api/perfil-medico/alumno/{$alumnoB->id}/historial");
        $responseHistorial->assertOk();
        $responseHistorial->assertJsonMissing(['email' => 'alumnoB_privado@yoltec.test']);
    }
}
