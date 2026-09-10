<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Routing\Middleware\ThrottleRequests;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

/**
 * Pruebas de la invariante de bloqueo de login por intentos fallidos.
 * Garantiza el control de tasa de intentos de autenticación, el bloqueo
 * temporal tras superar el límite y la separación por usuario y tipo.
 */
class BloqueoDeLoginTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->withoutMiddleware(ThrottleRequests::class);
        Cache::flush();
    }

    private function alumno(): User
    {
        return User::factory()->create();
    }

    private function doctor(): User
    {
        return User::factory()->doctor()->create();
    }

    public function test_cada_intento_fallido_devuelve_422_con_attempts_remaining_decreciente(): void
    {
        $alumno = $this->alumno();

        for ($i = 1; $i <= 4; $i++) {
            $response = $this->postJson('/api/login', [
                'identificador' => $alumno->numero_control,
                'password'      => '000000', // NIP incorrecto
                'tipo_usuario'  => 'alumno',
            ]);

            $response->assertStatus(422)
                ->assertJson([
                    'attempts_remaining' => 5 - $i,
                ]);
        }
    }

    public function test_al_alcanzar_max_attempts_la_cuenta_queda_bloqueada_y_rechaza_intentos_siguientes_incluso_con_password_correcto(): void
    {
        $alumno = $this->alumno();

        // Realizamos MAX_ATTEMPTS (5) intentos fallidos
        for ($i = 1; $i <= 4; $i++) {
            $this->postJson('/api/login', [
                'identificador' => $alumno->numero_control,
                'password'      => '000000',
                'tipo_usuario'  => 'alumno',
            ])->assertStatus(422);
        }

        // Intento número 5: debe bloquear la cuenta
        $quintoIntento = $this->postJson('/api/login', [
            'identificador' => $alumno->numero_control,
            'password'      => '000000',
            'tipo_usuario'  => 'alumno',
        ]);

        $quintoIntento->assertStatus(429)
            ->assertJson([
                'locked' => true,
            ]);

        // Intento siguiente con la contraseña/NIP CORRECTO: debe seguir rechazado por bloqueo
        $intentoPosterior = $this->postJson('/api/login', [
            'identificador' => $alumno->numero_control,
            'password'      => '123456', // NIP correcto
            'tipo_usuario'  => 'alumno',
        ]);

        $intentoPosterior->assertStatus(429)
            ->assertJson([
                'locked' => true,
            ]);
    }

    public function test_login_correcto_antes_de_llegar_al_maximo_limpia_contador_de_intentos(): void
    {
        $alumno = $this->alumno();

        // 3 intentos fallidos
        for ($i = 0; $i < 3; $i++) {
            $this->postJson('/api/login', [
                'identificador' => $alumno->numero_control,
                'password'      => '000000',
                'tipo_usuario'  => 'alumno',
            ])->assertStatus(422);
        }

        // Login correcto limpia el contador
        $this->postJson('/api/login', [
            'identificador' => $alumno->numero_control,
            'password'      => '123456',
            'tipo_usuario'  => 'alumno',
        ])->assertOk();

        // Un nuevo intento fallido debe reiniciar la cuenta regresiva desde 4 restantes
        $nuevoIntentoFallido = $this->postJson('/api/login', [
            'identificador' => $alumno->numero_control,
            'password'      => '000000',
            'tipo_usuario'  => 'alumno',
        ]);

        $nuevoIntentoFallido->assertStatus(422)
            ->assertJson([
                'attempts_remaining' => 4,
            ]);
    }

    public function test_el_bloqueo_es_por_identificador_y_tipo_de_usuario(): void
    {
        $alumno1 = $this->alumno();
        $alumno2 = $this->alumno();
        $doctor  = $this->doctor();

        // Bloqueamos al alumno 1 con 5 intentos fallidos
        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/login', [
                'identificador' => $alumno1->numero_control,
                'password'      => '000000',
                'tipo_usuario'  => 'alumno',
            ]);
        }

        // Confirmamos que alumno 1 está bloqueado
        $this->postJson('/api/login', [
            'identificador' => $alumno1->numero_control,
            'password'      => '123456',
            'tipo_usuario'  => 'alumno',
        ])->assertStatus(429)->assertJson(['locked' => true]);

        // Alumno 2 puede ingresar sin ser afectado por el bloqueo del alumno 1
        $this->postJson('/api/login', [
            'identificador' => $alumno2->numero_control,
            'password'      => '123456',
            'tipo_usuario'  => 'alumno',
        ])->assertOk();

        // Doctor no es afectado por el bloqueo del alumno
        $this->postJson('/api/login', [
            'identificador' => $doctor->username,
            'password'      => 'password',
            'tipo_usuario'  => 'doctor',
        ])->assertOk()->assertJsonPath('requires_2fa', true);
    }
}
