<?php

namespace Tests\Feature;

use App\Mail\TwoFactorCodeMail;
use App\Models\User;
use Database\Seeders\LocalDevelopmentSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use RuntimeException;
use Tests\TestCase;

class LocalDevelopmentTest extends TestCase
{
    use RefreshDatabase;

    private function seedLocal(): void
    {
        $this->app->instance('env', 'local');
        config(['app.env' => 'local']);
        $this->seed(LocalDevelopmentSeeder::class);
    }

    public function test_cuentas_locales_son_idempotentes_y_no_reescriben_datos(): void
    {
        $this->seedLocal();
        User::where('tipo', 'alumno')->update(['nombre' => 'Nombre editado']);
        $this->seed(LocalDevelopmentSeeder::class);

        $this->assertDatabaseCount('users', 3);
        $this->assertDatabaseHas('users', ['tipo' => 'alumno', 'nombre' => 'Nombre editado']);
    }

    public function test_seeder_local_rechaza_produccion(): void
    {
        $this->app->instance('env', 'production');
        config(['app.env' => 'production']);
        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('solo se pueden crear');
        $this->artisan('db:seed', [
            '--class' => LocalDevelopmentSeeder::class,
            '--force' => true,
        ])->run();
    }

    public function test_alumno_puede_entrar_y_no_accede_a_administracion(): void
    {
        $this->seedLocal();
        $response = $this->postJson('/api/login', [
            'identificador' => '99000001', 'password' => '123456', 'tipo_usuario' => 'alumno',
        ])->assertOk()->assertJsonStructure(['token']);

        $this->withToken($response->json('token'))->getJson('/api/admin/stats')->assertForbidden();
    }

    public function test_doctor_requiere_2fa_tambien_en_local_y_el_codigo_es_de_un_uso(): void
    {
        $this->seedLocal();
        Mail::fake();

        $response = $this->postJson('/api/login', [
            'identificador' => 'doctor-local', 'password' => 'SoloLocal123!', 'tipo_usuario' => 'doctor',
        ])->assertOk()->assertJsonPath('requires_2fa', true)->assertJsonMissingPath('token');

        $code = null;
        Mail::assertSent(TwoFactorCodeMail::class, function ($mail) use (&$code) {
            $code = $mail->code;
            return $mail->hasTo('doctor@yoltec.test');
        });
        $payload = ['user_id' => $response->json('user_id'), 'code' => $code];
        $this->postJson('/api/verify-2fa', $payload)->assertOk()->assertJsonStructure(['token']);
        $this->postJson('/api/verify-2fa', $payload)->assertUnauthorized();
    }

    public function test_nip_incorrecto_no_entrega_token(): void
    {
        $this->seedLocal();
        $this->postJson('/api/login', [
            'identificador' => '99000001', 'password' => '000000', 'tipo_usuario' => 'alumno',
        ])->assertUnprocessable()->assertJsonMissingPath('token');
    }

    public function test_la_ruta_publica_de_siembra_no_existe(): void
    {
        $this->postJson('/api/admin/seed-demo')->assertNotFound();
        $this->assertDatabaseCount('users', 0);
    }
}
