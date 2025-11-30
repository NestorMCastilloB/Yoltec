<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'identificador' => 'required|string',
            'password' => 'required|string',
        ]);

        // Buscar si es alumno (por numero_control) o doctor (por username)
        $user = User::where('numero_control', $request->identificador)
                    ->orWhere('username', $request->identificador)
                    ->first();

      if (!$user || !\Illuminate\Support\Facades\Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'identificador' => ['Las credenciales son incorrectas.'],
            ]);
        }

        // Crear token de autenticación
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Inicio de sesión exitoso',
            'user' => [
                'id' => $user->id,
                'nombre' => $user->nombre,
                'apellido' => $user->apellido,
                'email' => $user->email,
                'tipo' => $user->tipo,
                'numero_control' => $user->numero_control,
                'username' => $user->username,
            ],
            'token' => $token,
            'tipo' => $user->tipo,
        ], 200);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Sesión cerrada exitosamente'
        ], 200);
    }

    public function me(Request $request)
    {
        return response()->json([
            'user' => $request->user()
        ], 200);
    }
}
