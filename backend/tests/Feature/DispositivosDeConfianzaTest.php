<?php

namespace Tests\Feature;

use App\Models\TrustedDevice;
use App\Models\TwoFactorCode;
use App\Models\User;
use App\Services\Auth2FAService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Routing\Middleware\ThrottleRequests;
use Tests\TestCase;

class DispositivosDeConfianzaTest extends TestCase
{
    use RefreshDatabase;

    private Auth2FAService $auth2FAService;

    protected function setUp(): void
    {
        parent::setUp();
        $this->withoutMiddleware(ThrottleRequests::class);
        $this->auth2FAService = new Auth2FAService();
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    /**
     * Un dispositivo de confianza válido permite iniciar sesión SIN pedir 2FA para doctor/admin.
     */
    public function test_dispositivo_de_confianza_valido_permite_login_sin_segundo_factor(): void
    {
        $doctor = User::factory()->doctor()->create();

        $trustedDevice = TrustedDevice::create([
            'user_id'      => $doctor->id,
            'device_token' => 'token_de_confianza_valido_12345678901234567890',
            'expires_at'   => Carbon::now()->addDays(30),
        ]);

        $response = $this->postJson('/api/login', [
            'identificador' => $doctor->username,
            'password'      => 'password',
            'tipo_usuario'  => 'doctor',
            'device_token'  => $trustedDevice->device_token,
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'message' => 'Inicio de sesión exitoso',
                'tipo'    => 'doctor',
            ])
            ->assertJsonMissing(['requires_2fa' => true]);

        $this->assertArrayHasKey('token', $response->json());
    }

    /**
     * Pasados más de 30 días, el dispositivo deja de valer y el login vuelve a pedir 2FA.
     */
    public function test_dispositivo_de_confianza_expirado_pide_segundo_factor_nuevamente(): void
    {
        $admin = User::factory()->admin()->create();

        $trustedDevice = TrustedDevice::create([
            'user_id'      => $admin->id,
            'device_token' => 'token_de_confianza_expirado_12345678901234567890',
            'expires_at'   => Carbon::now()->addDays(30),
        ]);

        // Avanzamos 31 días en el tiempo
        Carbon::setTestNow(Carbon::now()->addDays(31));

        $response = $this->postJson('/api/login', [
            'identificador' => $admin->username,
            'password'      => 'password',
            'tipo_usuario'  => 'admin',
            'device_token'  => $trustedDevice->device_token,
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'message'      => 'Código de verificación enviado',
                'requires_2fa' => true,
                'user_id'      => $admin->id,
            ]);
    }

    /**
     * El token de dispositivo de un usuario NO sirve para otro usuario (evita salto de autenticación).
     */
    public function test_token_de_dispositivo_de_un_usuario_no_sirve_para_otro_usuario(): void
    {
        $doctor1 = User::factory()->doctor()->create();
        $doctor2 = User::factory()->doctor()->create();

        $trustedDeviceDoctor1 = TrustedDevice::create([
            'user_id'      => $doctor1->id,
            'device_token' => 'token_exclusivo_del_doctor_1_12345678901234567890',
            'expires_at'   => Carbon::now()->addDays(30),
        ]);

        // El Doctor 2 intenta iniciar sesión utilizando el token de dispositivo del Doctor 1
        $response = $this->postJson('/api/login', [
            'identificador' => $doctor2->username,
            'password'      => 'password',
            'tipo_usuario'  => 'doctor',
            'device_token'  => $trustedDeviceDoctor1->device_token,
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'message'      => 'Código de verificación enviado',
                'requires_2fa' => true,
                'user_id'      => $doctor2->id,
            ]);
    }

    /**
     * Un token de dispositivo inventado o malformado no vale y exige 2FA.
     */
    public function test_token_de_dispositivo_inventado_o_malformado_no_vale(): void
    {
        $doctor = User::factory()->doctor()->create();

        $response = $this->postJson('/api/login', [
            'identificador' => $doctor->username,
            'password'      => 'password',
            'tipo_usuario'  => 'doctor',
            'device_token'  => 'token_inventado_que_no_existe_en_bd',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'message'      => 'Código de verificación enviado',
                'requires_2fa' => true,
                'user_id'      => $doctor->id,
            ]);
    }

    /**
     * La ausencia de token de dispositivo exige 2FA con normalidad para doctor y admin.
     */
    public function test_ausencia_de_token_de_dispositivo_exige_segundo_factor(): void
    {
        $doctor = User::factory()->doctor()->create();

        $response = $this->postJson('/api/login', [
            'identificador' => $doctor->username,
            'password'      => 'password',
            'tipo_usuario'  => 'doctor',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'message'      => 'Código de verificación enviado',
                'requires_2fa' => true,
                'user_id'      => $doctor->id,
            ]);
    }

    /**
     * Auth2FAService::confirmAndCreateDevice() crea un dispositivo de confianza y marca el código 2FA como usado.
     */
    public function test_confirm_and_create_device_genera_token_y_lo_guarda(): void
    {
        $doctor = User::factory()->doctor()->create();

        $twoFactorCode = TwoFactorCode::create([
            'user_id'    => $doctor->id,
            'code'       => '$2y$12$e0MYzXyjpJS7Pd0RVvHwHe1xZ8eS4y.f4xZ8eS4y.f4xZ8eS4y.f4', // hash dummy
            'expires_at' => Carbon::now()->addMinutes(10),
            'used'       => false,
        ]);

        $deviceToken = $this->auth2FAService->confirmAndCreateDevice($twoFactorCode, $doctor);

        $this->assertNotEmpty($deviceToken);
        $this->assertEquals(64, strlen($deviceToken));
        $this->assertTrue($twoFactorCode->fresh()->used);

        $this->assertDatabaseHas('trusted_devices', [
            'user_id'      => $doctor->id,
            'device_token' => $deviceToken,
        ]);
    }

    /**
     * Auth2FAService::isTrustedDevice() valida token y renueva la fecha de expiración si es válido.
     */
    public function test_is_trusted_device_valida_y_renueva_expiracion(): void
    {
        $admin = User::factory()->admin()->create();

        $trustedDevice = TrustedDevice::create([
            'user_id'      => $admin->id,
            'device_token' => 'token_para_probar_servicio_12345678901234567890',
            'expires_at'   => Carbon::now()->addDays(5),
        ]);

        // Verificamos token válido
        $esValido = $this->auth2FAService->isTrustedDevice($admin, $trustedDevice->device_token);
        $this->assertTrue($esValido);

        // Al ser válido, renueva la expiración a 30 días en el futuro
        $fechaExpiracionActualizada = $trustedDevice->fresh()->expires_at;
        $this->assertTrue($fechaExpiracionActualizada->gt(Carbon::now()->addDays(29)));

        // Verificamos con token nulo o invalido
        $this->assertFalse($this->auth2FAService->isTrustedDevice($admin, null));
        $this->assertFalse($this->auth2FAService->isTrustedDevice($admin, 'token_invalido'));
    }

    /**
     * El método isValid() del modelo TrustedDevice evalúa correctamente el estado del dispositivo.
     */
    public function test_metodo_is_valid_del_modelo_trusted_device(): void
    {
        $doctor = User::factory()->doctor()->create();

        $dispositivoActivo = TrustedDevice::create([
            'user_id'      => $doctor->id,
            'device_token' => 'token_activo_12345',
            'expires_at'   => Carbon::now()->addDays(10),
        ]);

        $dispositivoExpirado = TrustedDevice::create([
            'user_id'      => $doctor->id,
            'device_token' => 'token_expirado_12345',
            'expires_at'   => Carbon::now()->subMinute(),
        ]);

        $this->assertTrue($dispositivoActivo->isValid());
        $this->assertFalse($dispositivoExpirado->isValid());
    }
}
