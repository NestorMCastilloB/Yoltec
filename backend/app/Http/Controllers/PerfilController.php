<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

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

    // Subir foto de perfil
    public function subirFoto(Request $request)
    {
        $request->validate([
            'foto' => 'required|image|mimes:jpeg,png,jpg,webp|max:2048',
        ]);

        $user = $request->user();

        // Eliminar foto anterior si existe
        if ($user->foto_perfil) {
            Storage::disk('public')->delete($user->foto_perfil);
        }

        $path = $request->file('foto')->store('fotos-perfil', 'public');
        $user->update(['foto_perfil' => $path]);

        return response()->json([
            'message' => 'Foto actualizada.',
            'foto_url' => asset('storage/' . $path),
        ]);
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
