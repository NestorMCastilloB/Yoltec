<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class PerfilController extends Controller

{
    // Ver perfil
    public function show(Request $request)
    {
        return response()->json([
            'perfil' => $request->user()
        ], 200);
    }

    // Actualizar perfil
    public function update(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'nombre' => 'sometimes|string|max:255',
            'apellido' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,' . $user->id,
            'telefono' => 'nullable|string|max:20',
            'fecha_nacimiento' => 'nullable|date',
        ]);

        $user->update($validated);

        return response()->json([
            'message' => 'Perfil actualizado exitosamente',
            'perfil' => $user
        ], 200);
    }

    // Subir foto de perfil (almacenada como base64 en BD)
    public function subirFoto(Request $request)
    {
        $request->validate([
            'foto' => 'required|image|mimes:jpeg,png,jpg,webp|max:2048',
        ]);

        $user = $request->user();

        $file = $request->file('foto');
        $ext = $file->getClientOriginalExtension();
        $base64 = 'data:image/' . $ext . ';base64,' . base64_encode(file_get_contents($file->getRealPath()));

        $user->update(['foto_perfil' => $base64]);

        return response()->json([
            'message' => 'Foto actualizada.',
            'foto_url' => $base64,
        ]);
    }

    // Listar sesiones activas (tokens Sanctum)
    public function sesiones(Request $request)
    {
        $user = $request->user();
        $currentTokenId = $user->currentAccessToken()->id;

        $sesiones = $user->tokens()->orderByDesc('last_used_at')->get()->map(function ($token) use ($currentTokenId) {
            return [
                'id'           => $token->id,
                'nombre'       => $token->name,
                'ultimo_uso'   => $token->last_used_at,
                'creada_en'    => $token->created_at,
                'es_actual'    => $token->id === $currentTokenId,
            ];
        });

        return response()->json(['sesiones' => $sesiones]);
    }

    // Revocar una sesión específica
    public function revocarSesion(Request $request, $id)
    {
        $user = $request->user();
        $token = $user->tokens()->find($id);

        if (!$token) {
            return response()->json(['message' => 'Sesión no encontrada'], 404);
        }

        $token->delete();
        return response()->json(['message' => 'Sesión cerrada.']);
    }

    // Cambiar contraseña
    public function cambiarPassword(Request $request)
    {
        $validated = $request->validate([
            'password_actual' => 'required|string',
            'password_nuevo' => 'required|string|min:8|confirmed',
        ]);

        $user = $request->user();

        if (!Hash::check($validated['password_actual'], $user->password)) {
            return response()->json([
                'message' => 'La contraseña actual es incorrecta'
            ], 400);
        }

        $user->update([
            'password' => Hash::make($validated['password_nuevo'])
        ]);

        return response()->json([
            'message' => 'Contraseña actualizada exitosamente'
        ], 200);
    }
}
