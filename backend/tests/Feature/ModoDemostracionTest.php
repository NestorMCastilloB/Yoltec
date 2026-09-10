<?php

namespace Tests\Feature;

use App\Mail\TwoFactorCodeMail;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Routing\Middleware\ThrottleRequests;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

/**
 * Pruebas del modo demostración del segundo factor.
 *
 * El plan gratuito de Resend solo entrega al correo verificado de la cuenta, así
 * que un visitante nunca recibe el código de 2FA y no puede pasar de esa pantalla.
 * Con DEMO_MODE activo, las cuentas listadas reciben el código en la respuesta.
 *
 * Lo que estas pruebas vigilan no es que el atajo funcione, sino que **no se
 * desborde**: que no alcance a ninguna cuenta que no esté nombrada, que no se
 * active con la bandera apagada, y que el segundo factor siga siendo real.
 */
class ModoDemostracionTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->withoutMiddleware(ThrottleRequests::class);
        Cache::flush();
        Mail::fake();
    }

    /** Enciende el modo demostración para los usernames indicados. */
    private function activarDemo(string ...$usernames): void
    {
        config([
            'yoltec.demo_mode'     => true,
            'yoltec.demo_usuarios' => $usernames,
        ]);
    }

    private function login(User $doctor): \Illuminate\Testing\TestResponse
    {
        return $this->postJson('/api/login', [
            'identificador' => $doctor->username,
            'password'      => 'password',
            'tipo_usuario'  => 'doctor',
        ]);
    }

    public function test_una_cuenta_de_demostracion_recibe_el_codigo_en_la_respuesta(): void
    {
        $doctor = User::factory()->doctor()->create();
        $this->activarDemo($doctor->username);

        $respuesta = $this->login($doctor);

        $respuesta->assertOk()
            ->assertJson([
                'requires_2fa'      => true,
                'modo_demostracion' => true,
            ])
            ->assertJsonStructure(['codigo_demo']);

        $this->assertMatchesRegularExpression('/^\d{6}$/', $respuesta->json('codigo_demo'));
    }

    public function test_a_una_cuenta_de_demostracion_no_se_le_envia_correo(): void
    {
        $doctor = User::factory()->doctor()->create();
        $this->activarDemo($doctor->username);

        $this->login($doctor)->assertOk();

        Mail::assertNothingSent();
    }

    public function test_el_codigo_de_demostracion_sirve_para_verificar_el_segundo_factor(): void
    {
        $doctor = User::factory()->doctor()->create();
        $this->activarDemo($doctor->username);

        $codigo = $this->login($doctor)->json('codigo_demo');

        $this->postJson('/api/verify-2fa', [
            'user_id' => $doctor->id,
            'code'    => $codigo,
        ])->assertOk()->assertJsonStructure(['token']);
    }

    public function test_el_codigo_de_demostracion_sigue_siendo_de_un_solo_uso(): void
    {
        $doctor = User::factory()->doctor()->create();
        $this->activarDemo($doctor->username);

        $codigo = $this->login($doctor)->json('codigo_demo');

        $this->postJson('/api/verify-2fa', [
            'user_id' => $doctor->id,
            'code'    => $codigo,
        ])->assertOk();

        // El atajo cambia por dónde llega el código, no lo que vale.
        $this->postJson('/api/verify-2fa', [
            'user_id' => $doctor->id,
            'code'    => $codigo,
        ])->assertUnauthorized();
    }

    public function test_con_el_modo_apagado_la_cuenta_listada_no_recibe_el_codigo(): void
    {
        $doctor = User::factory()->doctor()->create();
        config([
            'yoltec.demo_mode'     => false,
            'yoltec.demo_usuarios' => [$doctor->username],
        ]);

        $respuesta = $this->login($doctor);

        $respuesta->assertOk()
            ->assertJson(['requires_2fa' => true])
            ->assertJsonMissing(['modo_demostracion' => true]);

        $this->assertNull($respuesta->json('codigo_demo'));
        Mail::assertSent(TwoFactorCodeMail::class);
    }

    public function test_una_cuenta_no_listada_no_recibe_el_codigo_aunque_el_modo_este_activo(): void
    {
        $listado    = User::factory()->doctor()->create();
        $noListado  = User::factory()->doctor()->create();
        $this->activarDemo($listado->username);

        $respuesta = $this->login($noListado);

        $respuesta->assertOk()->assertJsonMissing(['modo_demostracion' => true]);
        $this->assertNull($respuesta->json('codigo_demo'));
        Mail::assertSent(TwoFactorCodeMail::class);
    }

    public function test_sin_lista_de_usuarios_el_modo_no_alcanza_a_nadie(): void
    {
        $doctor = User::factory()->doctor()->create();
        config([
            'yoltec.demo_mode'     => true,
            'yoltec.demo_usuarios' => [],
        ]);

        $respuesta = $this->login($doctor);

        $respuesta->assertOk()->assertJsonMissing(['modo_demostracion' => true]);
        $this->assertNull($respuesta->json('codigo_demo'));
    }

    public function test_el_alumno_no_se_ve_afectado_porque_nunca_pasa_por_el_segundo_factor(): void
    {
        $alumno = User::factory()->create();
        config([
            'yoltec.demo_mode'     => true,
            'yoltec.demo_usuarios' => [$alumno->numero_control],
        ]);

        $respuesta = $this->postJson('/api/login', [
            'identificador' => $alumno->numero_control,
            'password'      => '123456',
            'tipo_usuario'  => 'alumno',
        ]);

        $respuesta->assertOk()->assertJsonMissing(['modo_demostracion' => true]);
        $this->assertNull($respuesta->json('codigo_demo'));
    }

    public function test_el_reenvio_tambien_devuelve_el_codigo_en_una_cuenta_de_demostracion(): void
    {
        $doctor = User::factory()->doctor()->create();
        $this->activarDemo($doctor->username);

        $primero = $this->login($doctor)->json('codigo_demo');

        $respuesta = $this->postJson('/api/resend-2fa', ['user_id' => $doctor->id]);

        $respuesta->assertOk()->assertJson(['modo_demostracion' => true]);
        $this->assertMatchesRegularExpression('/^\d{6}$/', $respuesta->json('codigo_demo'));
        Mail::assertNothingSent();

        // El código nuevo verifica; que coincida o no con el primero es indiferente.
        $this->postJson('/api/verify-2fa', [
            'user_id' => $doctor->id,
            'code'    => $respuesta->json('codigo_demo'),
        ])->assertOk();
    }
}
