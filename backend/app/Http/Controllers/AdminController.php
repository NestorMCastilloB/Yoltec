<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use App\Models\Cita;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AdminController extends Controller
{
    // ===== STATS =====

    public function getStats()
    {
        $hoy = now()->toDateString();
        $hace30 = now()->subDays(30)->toDateString();

        $totalAlumnos  = User::where('tipo', 'alumno')->count();
        $totalDoctores = User::where('tipo', 'doctor')->count();

        $citasHoy          = Cita::whereDate('fecha_cita', $hoy)->count();
        $citasCompletadas  = Cita::whereDate('fecha_cita', $hoy)->where('estatus', 'atendida')->count();
        $citasPendientes   = Cita::whereDate('fecha_cita', $hoy)->whereIn('estatus', ['programada', 'pendiente'])->count();

        $alumnosActivos = Cita::where('fecha_cita', '>=', $hace30)
            ->whereNotNull('alumno_id')
            ->distinct('alumno_id')
            ->count('alumno_id');

        $ultimoToken = DB::table('personal_access_tokens')
            ->join('users', 'tokenable_id', '=', 'users.id')
            ->orderByDesc('personal_access_tokens.created_at')
            ->select('personal_access_tokens.created_at', 'users.email')
            ->first();

        return response()->json([
            'total_usuarios'        => $totalAlumnos + $totalDoctores,
            'total_alumnos'         => $totalAlumnos,
            'total_doctores'        => $totalDoctores,
            'citas_hoy'             => $citasHoy,
            'citas_completadas_hoy' => $citasCompletadas,
            'citas_pendientes_hoy'  => $citasPendientes,
            'alumnos_activos'       => $alumnosActivos,
            'ultimo_acceso_hora'    => $ultimoToken ? \Carbon\Carbon::parse($ultimoToken->created_at)->format('H:i') : null,
            'ultimo_acceso_email'   => $ultimoToken?->email,
        ]);
    }

    // ===== ALUMNOS =====

    public function indexAlumnos(Request $request)
    {
        $alumnos = User::where('tipo', 'alumno')
            ->select('id', 'numero_control', 'nombre', 'apellido', 'email', 'telefono', 'fecha_nacimiento', 'created_at')
            ->orderBy('apellido')
            ->get();
        return response()->json(['alumnos' => $alumnos]);
    }

    public function storeAlumno(Request $request)
    {
        $data = $request->validate([
            'numero_control'  => 'required|string|unique:users,numero_control',
            'nombre'          => 'required|string|max:100',
            'apellido'        => 'required|string|max:100',
            'email'           => 'required|email|unique:users,email',
            'nip'             => 'required|string|size:6',
            'telefono'        => 'nullable|string|max:15',
            'fecha_nacimiento' => 'nullable|date',
        ]);

        $alumno = User::create([
            'numero_control'  => $data['numero_control'],
            'nombre'          => $data['nombre'],
            'apellido'        => $data['apellido'],
            'email'           => $data['email'],
            'nip'             => Hash::make($data['nip']),
            'password'        => Hash::make($data['nip']),
            'tipo'            => 'alumno',
            'telefono'        => $data['telefono'] ?? null,
            'fecha_nacimiento' => $data['fecha_nacimiento'] ?? null,
        ]);

        return response()->json(['message' => 'Alumno creado correctamente', 'alumno' => $alumno], 201);
    }

    public function updateAlumno(Request $request, $id)
    {
        $alumno = User::where('tipo', 'alumno')->findOrFail($id);

        $data = $request->validate([
            'numero_control'  => ['required', 'string', Rule::unique('users', 'numero_control')->ignore($alumno->id)],
            'nombre'          => 'required|string|max:100',
            'apellido'        => 'required|string|max:100',
            'email'           => ['required', 'email', Rule::unique('users', 'email')->ignore($alumno->id)],
            'nip'             => 'nullable|string|size:6',
            'telefono'        => 'nullable|string|max:15',
            'fecha_nacimiento' => 'nullable|date',
        ]);

        $alumno->numero_control  = $data['numero_control'];
        $alumno->nombre          = $data['nombre'];
        $alumno->apellido        = $data['apellido'];
        $alumno->email           = $data['email'];
        $alumno->telefono        = $data['telefono'] ?? $alumno->telefono;
        $alumno->fecha_nacimiento = $data['fecha_nacimiento'] ?? $alumno->fecha_nacimiento;
        if (!empty($data['nip'])) {
            $alumno->nip      = Hash::make($data['nip']);
            $alumno->password = Hash::make($data['nip']);
        }
        $alumno->save();

        return response()->json(['message' => 'Alumno actualizado correctamente', 'alumno' => $alumno]);
    }

    public function destroyAlumno(Request $request, $id)
    {
        $alumno = User::where('tipo', 'alumno')->findOrFail($id);
        $alumno->delete();
        return response()->json(['message' => 'Alumno eliminado correctamente']);
    }

    // ===== DOCTORES =====

    public function indexDoctores(Request $request)
    {
        $doctores = User::where('tipo', 'doctor')
            ->select('id', 'username', 'nombre', 'apellido', 'email', 'telefono', 'created_at')
            ->orderBy('apellido')
            ->get();
        return response()->json(['doctores' => $doctores]);
    }

    public function storeDoctor(Request $request)
    {
        $data = $request->validate([
            'username' => ['required', 'string', Rule::unique('users', 'username')->where('tipo', 'doctor')],
            'nombre'   => 'required|string|max:100',
            'apellido' => 'required|string|max:100',
            'email'    => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
            'telefono' => 'nullable|string|max:15',
        ]);

        $doctor = User::create([
            'username' => $data['username'],
            'nombre'   => $data['nombre'],
            'apellido' => $data['apellido'],
            'email'    => $data['email'],
            'password' => Hash::make($data['password']),
            'tipo'     => 'doctor',
            'telefono' => $data['telefono'] ?? null,
        ]);

        return response()->json(['message' => 'Doctor creado correctamente', 'doctor' => $doctor], 201);
    }

    public function updateDoctor(Request $request, $id)
    {
        $doctor = User::where('tipo', 'doctor')->findOrFail($id);

        $data = $request->validate([
            'username' => ['required', 'string', Rule::unique('users', 'username')->where('tipo', 'doctor')->ignore($doctor->id)],
            'nombre'   => 'required|string|max:100',
            'apellido' => 'required|string|max:100',
            'email'    => ['required', 'email', Rule::unique('users', 'email')->ignore($doctor->id)],
            'password' => 'nullable|string|min:6',
            'telefono' => 'nullable|string|max:15',
        ]);

        $doctor->username = $data['username'];
        $doctor->nombre   = $data['nombre'];
        $doctor->apellido = $data['apellido'];
        $doctor->email    = $data['email'];
        $doctor->telefono = $data['telefono'] ?? $doctor->telefono;
        if (!empty($data['password'])) {
            $doctor->password = Hash::make($data['password']);
        }
        $doctor->save();

        return response()->json(['message' => 'Doctor actualizado correctamente', 'doctor' => $doctor]);
    }

    public function destroyDoctor(Request $request, $id)
    {
        $doctor = User::where('tipo', 'doctor')->findOrFail($id);
        $doctor->delete();
        return response()->json(['message' => 'Doctor eliminado correctamente']);
    }
}
