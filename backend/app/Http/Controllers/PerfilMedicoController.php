<?php

namespace App\Http\Controllers;

use App\Models\Cita;
use App\Models\User;
use Illuminate\Http\Request;

class PerfilMedicoController extends Controller
{
    // Ver perfil médico propio (alumno) o de un alumno (doctor)
    public function show(Request $request, ?int $alumnoId = null)
    {
        $user = $request->user();

        if ($user->esAlumno()) {
            $alumno = $user;
        } elseif ($user->esDoctor() && $alumnoId) {
            $alumno = User::where('id', $alumnoId)->where('tipo', 'alumno')->firstOrFail();
        } else {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        return response()->json([
            'perfil' => [
                'id'                   => $alumno->id,
                'nombre'               => $alumno->nombre,
                'apellido'             => $alumno->apellido,
                'numero_control'       => $alumno->numero_control,
                'email'                => $alumno->email,
                'telefono'             => $alumno->telefono,
                'fecha_nacimiento'     => $alumno->fecha_nacimiento,
                'tipo_sangre'          => $alumno->tipo_sangre,
                'alergias'             => $alumno->alergias,
                'enfermedades_cronicas' => $alumno->enfermedades_cronicas,
            ]
        ]);
    }

    // Actualizar perfil médico (solo el propio alumno)
    public function update(Request $request)
    {
        $user = $request->user();

        if (!$user->esAlumno()) {
            return response()->json(['message' => 'Solo los alumnos pueden actualizar su perfil médico.'], 403);
        }

        $data = $request->validate([
            'tipo_sangre'           => 'nullable|string|max:5',
            'alergias'              => 'nullable|string|max:1000',
            'enfermedades_cronicas' => 'nullable|string|max:1000',
        ]);

        $user->update($data);

        return response()->json(['message' => 'Perfil médico actualizado.', 'perfil' => $user->fresh()]);
    }

    // Historial de consultas del alumno
    public function historial(Request $request, ?int $alumnoId = null)
    {
        $user = $request->user();

        if ($user->esAlumno()) {
            $id = $user->id;
        } elseif ($user->esDoctor() && $alumnoId) {
            $id = $alumnoId;
        } else {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $citas = Cita::with(['doctor', 'consulta', 'receta'])
            ->where('alumno_id', $id)
            ->where('estatus', 'atendida')
            ->orderByDesc('fecha_cita')
            ->get()
            ->map(fn($c) => [
                'id'           => $c->id,
                'clave_cita'   => $c->clave_cita,
                'fecha_cita'   => $c->fecha_cita,
                'hora_cita'    => $c->hora_cita,
                'motivo'       => $c->motivo,
                'doctor'       => $c->doctor ? [
                    'nombre'   => $c->doctor->nombre,
                    'apellido' => $c->doctor->apellido,
                ] : null,
                'consulta'     => $c->consulta ? [
                    'diagnostico'    => $c->consulta->diagnostico,
                    'tratamiento'    => $c->consulta->tratamiento,
                    'observaciones'  => $c->consulta->observaciones,
                ] : null,
                'receta'       => $c->receta ? [
                    'medicamento'  => $c->receta->medicamento,
                    'dosis'        => $c->receta->dosis,
                    'indicaciones' => $c->receta->indicaciones,
                ] : null,
            ]);

        return response()->json(['historial' => $citas, 'total' => $citas->count()]);
    }
}
