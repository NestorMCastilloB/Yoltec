<?php

namespace Tests\Feature;

use App\Mail\PasswordResetMail;
use App\Models\PasswordResetToken;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Routing\Middleware\ThrottleRequests;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class RecuperacionDePasswordTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        // Desactivar middleware ThrottleRequests para evitar HTTP 429 por límite de tasa de rutas
        $this->withoutMiddleware(ThrottleRequests::class);
    }

    /**
     * Solicitar recuperación con un correo existente genera el token en la base de datos
     * y envía el correo electrónico con el mailable correspondiente.
     */
    public function test_solicitar_recuperacion_con_correo_existente_genera_token_y_envia_correo(): void
    {
        Mail::fake();

        $doctor = User::factory()->doctor()->create([
            'email' => 'doctor@example.com',
        ]);

        $respuesta = $this->postJson('/api/forgot-password', [
            'email' => 'doctor@example.com',
        ]);

        $respuesta->assertStatus(200)
            ->assertJson([
                'message' => 'Si el correo está registrado, recibirás un enlace en breve.',
            ]);

        $this->assertDatabaseHas('password_reset_tokens', [
            'user_id' => $doctor->id,
            'used'    => false,
        ]);

        Mail::assertSent(PasswordResetMail::class, function ($mail) use ($doctor) {
            return $mail->hasTo($doctor->email);
        });
    }

    /**
     * Solicitar recuperación con un correo que no existe devuelve exactamente la misma respuesta
     * (mensaje y código de estado HTTP) que con uno existente para prevenir la enumeración de usuarios.
     */
    public function test_solicitar_recuperacion_con_correo_inexistente_devuelve_la_misma_respuesta(): void
    {
        Mail::fake();

        $doctor = User::factory()->doctor()->create([
            'email' => 'existente@example.com',
        ]);

        $respuestaExistente = $this->postJson('/api/forgot-password', [
            'email' => $doctor->email,
        ]);

        $respuestaInexistente = $this->postJson('/api/forgot-password', [
            'email' => 'noexistente@example.com',
        ]);

        $respuestaExistente->assertStatus(200);
        $respuestaInexistente->assertStatus(200);

        $this->assertSame(
            $respuestaExistente->getContent(),
            $respuestaInexistente->getContent(),
            'La respuesta para un correo existente e inexistente debe ser idéntica para evitar la enumeración de usuarios.'
        );

        Mail::assertSent(PasswordResetMail::class, 1);
    }

    /**
     * Un token válido permite cambiar la contraseña del usuario y la nueva contraseña
     * permite iniciar sesión posteriormente.
     */
    public function test_token_valido_permite_cambiar_contrasena_y_nueva_sirve_para_iniciar_sesion(): void
    {
        $doctor = User::factory()->doctor()->create([
            'username' => 'dr_simi',
            'password' => Hash::make('password_viejo_123'),
        ]);

        $tokenRecord = PasswordResetToken::create([
            'user_id'    => $doctor->id,
            'token'      => 'token-valido-123456',
            'expires_at' => Carbon::now()->addMinutes(30),
            'used'       => false,
        ]);

        $respuesta = $this->postJson('/api/reset-password', [
            'token'                 => 'token-valido-123456',
            'password'              => 'nueva_password_999',
            'password_confirmation' => 'nueva_password_999',
        ]);

        $respuesta->assertStatus(200)
            ->assertJson([
                'message' => 'Contraseña restablecida correctamente. Ahora puedes iniciar sesión.',
            ]);

        $this->assertTrue($tokenRecord->fresh()->used);
        $this->assertTrue(Hash::check('nueva_password_999', $doctor->fresh()->password));

        // Probar que la nueva contraseña sirve para iniciar sesión
        $respuestaLogin = $this->postJson('/api/login', [
            'identificador' => 'dr_simi',
            'password'      => 'nueva_password_999',
            'tipo_usuario'  => 'doctor',
        ]);

        $respuestaLogin->assertStatus(200);
    }

    /**
     * Un token que ya fue utilizado no puede reutilizarse para restablecer la contraseña nuevamente.
     */
    public function test_token_ya_usado_no_se_puede_reutilizar(): void
    {
        $doctor = User::factory()->doctor()->create();

        PasswordResetToken::create([
            'user_id'    => $doctor->id,
            'token'      => 'token-usado-123',
            'expires_at' => Carbon::now()->addMinutes(30),
            'used'       => true,
        ]);

        $respuesta = $this->postJson('/api/reset-password', [
            'token'                 => 'token-usado-123',
            'password'              => 'nueva_password_999',
            'password_confirmation' => 'nueva_password_999',
        ]);

        $respuesta->assertStatus(422)
            ->assertJson([
                'message' => 'El enlace es inválido o ha expirado.',
            ]);
    }

    /**
     * Un token expirado es rechazado al intentar restablecer la contraseña. Usa Carbon para simular el paso del tiempo.
     */
    public function test_token_expirado_se_rechaza(): void
    {
        $doctor = User::factory()->doctor()->create();

        $ahora = Carbon::now();
        Carbon::setTestNow($ahora);

        PasswordResetToken::create([
            'user_id'    => $doctor->id,
            'token'      => 'token-expirable-456',
            'expires_at' => $ahora->copy()->addMinutes(30),
            'used'       => false,
        ]);

        // Viajar en el tiempo 31 minutos al futuro
        Carbon::setTestNow($ahora->copy()->addMinutes(31));

        $respuesta = $this->postJson('/api/reset-password', [
            'token'                 => 'token-expirable-456',
            'password'              => 'nueva_password_999',
            'password_confirmation' => 'nueva_password_999',
        ]);

        $respuesta->assertStatus(422)
            ->assertJson([
                'message' => 'El enlace es inválido o ha expirado.',
            ]);

        Carbon::setTestNow(); // Restaurar el tiempo
    }

    /**
     * El token perteneciente a un usuario no altera la contraseña de otro usuario.
     */
    public function test_token_de_un_usuario_no_sirve_para_cambiar_contrasena_de_otro(): void
    {
        $usuarioA = User::factory()->doctor()->create([
            'username' => 'usuario_a',
            'password' => Hash::make('password_original_a'),
        ]);

        $usuarioB = User::factory()->doctor()->create([
            'username' => 'usuario_b',
            'password' => Hash::make('password_original_b'),
        ]);

        PasswordResetToken::create([
            'user_id'    => $usuarioA->id,
            'token'      => 'token-de-usuario-a',
            'expires_at' => Carbon::now()->addMinutes(30),
            'used'       => false,
        ]);

        // Al usar el token de Usuario A, se restablecerá la contraseña del Usuario A, no la del Usuario B
        $this->postJson('/api/reset-password', [
            'token'                 => 'token-de-usuario-a',
            'password'              => 'password_modificada_123',
            'password_confirmation' => 'password_modificada_123',
        ])->assertStatus(200);

        // La contraseña del usuario B se mantiene intacta
        $this->assertTrue(Hash::check('password_original_b', $usuarioB->fresh()->password));
        $this->assertFalse(Hash::check('password_modificada_123', $usuarioB->fresh()->password));

        // El usuario B no puede iniciar sesión con la nueva contraseña
        $respuestaLoginB = $this->postJson('/api/login', [
            'identificador' => 'usuario_b',
            'password'      => 'password_modificada_123',
            'tipo_usuario'  => 'doctor',
        ]);
        $respuestaLoginB->assertStatus(422);
    }

    /**
     * Se respetan las reglas de validación de la contraseña nueva.
     */
    public function test_se_respetan_las_reglas_de_validacion_de_la_nueva_contrasena(): void
    {
        $doctor = User::factory()->doctor()->create();

        PasswordResetToken::create([
            'user_id'    => $doctor->id,
            'token'      => 'token-para-validacion-789',
            'expires_at' => Carbon::now()->addMinutes(30),
            'used'       => false,
        ]);

        // 1. Token requerido
        $this->postJson('/api/reset-password', [
            'password'              => 'nueva_password_999',
            'password_confirmation' => 'nueva_password_999',
        ])->assertStatus(422)->assertJsonValidationErrors(['token']);

        // 2. Contraseña menor a 8 caracteres
        $this->postJson('/api/reset-password', [
            'token'                 => 'token-para-validacion-789',
            'password'              => 'corta',
            'password_confirmation' => 'corta',
        ])->assertStatus(422)->assertJsonValidationErrors(['password']);

        // 3. Confirmación de contraseña no coincide
        $this->postJson('/api/reset-password', [
            'token'                 => 'token-para-validacion-789',
            'password'              => 'nueva_password_999',
            'password_confirmation' => 'diferente_password_999',
        ])->assertStatus(422)->assertJsonValidationErrors(['password']);
    }
}
