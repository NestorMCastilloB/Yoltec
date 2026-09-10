<?php

namespace Tests\Feature;

use App\Mail\TwoFactorCodeMail;
use App\Models\User;
use App\Services\Auth2FAService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

/**
 * Pruebas de la invariante de verificación de 2FA.
 * Garantiza que solo códigos válidos, vigentes, no reutilizados y pertenecientes
 * al usuario correcto permitan la verificación en el servicio y controlador.
 */
class Verificacion2FATest extends TestCase
{
    use RefreshDatabase;

    private Auth2FAService $servicio2FA;

    protected function setUp(): void
    {
        parent::setUp();
        $this->servicio2FA = new Auth2FAService();
    }

    private function doctor(): User
    {
        return User::factory()->doctor()->create();
    }

    private function generarCodigo2FA(User $user): string
    {
        Mail::fake();
        $code = null;
        $this->servicio2FA->sendCode($user);

        Mail::assertSent(TwoFactorCodeMail::class, function ($mail) use (&$code) {
            $code = $mail->code;
            return true;
        });

        return $code;
    }

    public function test_codigo_valido_y_no_expirado_verifica_correctamente(): void
    {
        $doctor = $this->doctor();
        $code = $this->generarCodigo2FA($doctor);

        $response = $this->postJson('/api/verify-2fa', [
            'user_id' => $doctor->id,
            'code'    => $code,
        ]);

        $response->assertOk()
            ->assertJsonStructure(['token', 'device_token']);
    }

    public function test_codigo_expirado_no_verifica(): void
    {
        $doctor = $this->doctor();
        $code = $this->generarCodigo2FA($doctor);

        // La caducidad es de 10 minutos (Auth2FAService::CODE_MINUTES). Viajamos en el tiempo 11 minutos.
        Carbon::setTestNow(Carbon::now()->addMinutes(11));

        $response = $this->postJson('/api/verify-2fa', [
            'user_id' => $doctor->id,
            'code'    => $code,
        ]);

        $response->assertUnauthorized()
            ->assertJson(['message' => 'Código inválido o expirado']);

        Carbon::setTestNow();
    }

    public function test_codigo_incorrecto_no_verifica(): void
    {
        $doctor = $this->doctor();
        $this->generarCodigo2FA($doctor);

        $response = $this->postJson('/api/verify-2fa', [
            'user_id' => $doctor->id,
            'code'    => '000000',
        ]);

        $response->assertUnauthorized()
            ->assertJson(['message' => 'Código inválido o expirado']);
    }

    public function test_codigo_ya_usado_no_se_puede_reutilizar(): void
    {
        $doctor = $this->doctor();
        $code = $this->generarCodigo2FA($doctor);

        // Primer uso
        $this->postJson('/api/verify-2fa', [
            'user_id' => $doctor->id,
            'code'    => $code,
        ])->assertOk();

        // Reutilización
        $response = $this->postJson('/api/verify-2fa', [
            'user_id' => $doctor->id,
            'code'    => $code,
        ]);

        $response->assertUnauthorized()
            ->assertJson(['message' => 'Código inválido o expirado']);
    }

    public function test_codigo_de_un_usuario_no_sirve_para_otro_usuario(): void
    {
        $doctor1 = $this->doctor();
        $doctor2 = $this->doctor();

        $codeDoctor1 = $this->generarCodigo2FA($doctor1);

        $response = $this->postJson('/api/verify-2fa', [
            'user_id' => $doctor2->id,
            'code'    => $codeDoctor1,
        ]);

        $response->assertUnauthorized()
            ->assertJson(['message' => 'Código inválido o expirado']);
    }
}
