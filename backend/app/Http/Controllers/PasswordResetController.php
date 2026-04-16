<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use App\Models\PasswordResetToken;
use App\Mail\PasswordResetMail;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;
use Carbon\Carbon;

class PasswordResetController extends Controller
{
    public function forgotPassword(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        $user = User::where('email', $request->email)
            ->whereIn('tipo', ['doctor', 'admin'])
            ->first();

        // Siempre respuesta genérica para no revelar si el email existe
        if (!$user) {
            return response()->json(['message' => 'Si el correo está registrado, recibirás un enlace en breve.']);
        }

        // Invalidar tokens anteriores del usuario
        PasswordResetToken::where('user_id', $user->id)->delete();

        $token = Str::random(64);

        PasswordResetToken::create([
            'user_id'    => $user->id,
            'token'      => $token,
            'expires_at' => Carbon::now()->addMinutes(30),
            'used'       => false,
        ]);

        $frontendUrl = config('app.frontend_url', 'http://localhost:4200');
        $resetUrl = "{$frontendUrl}/reset-password?token={$token}";

        try {
            Mail::to($user->email)->send(new PasswordResetMail($user->nombre, $resetUrl));
        } catch (\Exception $e) {
            \Log::error('Error enviando email de reset: ' . $e->getMessage());
        }

        return response()->json(['message' => 'Si el correo está registrado, recibirás un enlace en breve.']);
    }

    public function resetPassword(Request $request)
    {
        $request->validate([
            'token'    => 'required|string',
            'password' => 'required|string|min:6|confirmed',
        ]);

        $record = PasswordResetToken::where('token', $request->token)
            ->where('used', false)
            ->where('expires_at', '>', Carbon::now())
            ->first();

        if (!$record) {
            return response()->json(['message' => 'El enlace es inválido o ha expirado.'], 422);
        }

        $user = User::find($record->user_id);
        if (!$user) {
            return response()->json(['message' => 'Usuario no encontrado.'], 404);
        }

        $user->password = Hash::make($request->password);
        $user->save();

        $record->update(['used' => true]);

        // Revocar todos los tokens de acceso activos
        $user->tokens()->delete();

        return response()->json(['message' => 'Contraseña restablecida correctamente. Ahora puedes iniciar sesión.']);
    }
}
