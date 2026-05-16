<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Cita;
use App\Models\User;
use App\Services\CitaService;
use App\Services\FcmService;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;

class CitaController extends Controller
{
    public function __construct(private CitaService $citaService) {}

    public function index(Request $request)
    {
        // Lazy fallback al scheduler (Render free tier no ejecuta cron)
        $this->citaService->marcarPasadasComoNoAsistio();

        $user = $request->user();

        $citas = $user->esAlumno()
            ? Cita::where('alumno_id', $user->id)
                ->with(['doctor:id,nombre,apellido,username'])
                ->orderBy('fecha_cita', 'desc')->orderBy('hora_cita', 'desc')->get()
            : Cita::with(['alumno:id,nombre,apellido,numero_control'])
                ->orderBy('fecha_cita', 'desc')->orderBy('hora_cita', 'desc')->get();

        return response()->json(['citas' => $citas]);
    }

    public function availability(Request $request)
    {
        $request->validate([
            'month' => 'nullable|integer|min:1|max:12',
            'year'  => 'nullable|integer|min:2000|max:2100',
        ]);

        $month = $request->input('month', now()->month);
        $year  = $request->input('year', now()->year);
        $days  = $this->citaService->getAvailability($month, $year);

        return response()->json(['month' => $month, 'year' => $year, 'days' => $days]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'fecha_cita'      => 'required|date|after_or_equal:today',
            'hora_cita'       => 'required|date_format:H:i',
            'motivo'          => 'nullable|string|max:500',
            'numero_control'  => 'nullable|string|exists:users,numero_control',
        ], [
            'fecha_cita.required'       => 'La fecha de la cita es obligatoria.',
            'fecha_cita.date'           => 'Ingresa una fecha de cita válida.',
            'fecha_cita.after_or_equal' => 'La fecha de la cita debe ser hoy o una fecha futura.',
            'hora_cita.required'        => 'La hora de la cita es obligatoria.',
            'hora_cita.date_format'     => 'La hora de la cita debe tener el formato HH:MM.',
            'numero_control.exists'     => 'No se encontró un alumno con ese número de control.',
        ]);

        if ($error = $this->citaService->validarHorario($validated['fecha_cita'], $validated['hora_cita'])) {
            return response()->json(['message' => $error], 422);
        }

        $user = $request->user();

        if ($user->esAlumno()) {
            $alumnoId = $user->id;
        } elseif ($request->filled('numero_control')) {
            $alumnoId = User::where('numero_control', $request->numero_control)->firstOrFail()->id;
        } else {
            $alumnoId = $request->alumno_id;
        }

        $cita = $this->citaService->reservarSlot(
            $validated['fecha_cita'],
            $validated['hora_cita'],
            $validated['motivo'] ?? null,
            $alumnoId
        );

        if (!$cita) {
            return response()->json(['message' => 'El horario seleccionado ya no está disponible. Elige otra hora.'], 422);
        }

        $cita->load(['alumno:id,nombre,apellido,numero_control,fcm_token', 'doctor:id,nombre,apellido']);
        Cache::forget("disp_{$cita->fecha_cita->year}_{$cita->fecha_cita->month}");

        // FCM diferido: envía la notificación DESPUÉS del response (evita bloquear ~2-5s)
        if ($cita->alumno?->fcm_token) {
            $token = $cita->alumno->fcm_token;
            $fecha = (string) $cita->fecha_cita;
            $hora  = (string) $cita->hora_cita;
            $citaId = (string) $cita->id;
            defer(fn() => (new FcmService())->send(
                $token,
                'Cita confirmada',
                "Tu cita está programada para el {$fecha} a las {$hora}.",
                ['cita_id' => $citaId, 'tipo' => 'cita_confirmada']
            ));
        }

        return response()->json(['message' => 'Cita agendada exitosamente', 'cita' => $cita], 201);
    }

    public function show(Request $request, $id)
    {
        $user = $request->user();
        $cita = Cita::with(['alumno', 'doctor', 'bitacora', 'receta'])->findOrFail($id);

        if ($user->esAlumno() && $cita->alumno_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        return response()->json($cita);
    }

    public function cancelar(Request $request, $id)
    {
        $user = $request->user();
        $cita = Cita::findOrFail($id);

        if ($user->esAlumno() && $cita->alumno_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        if (in_array($cita->estatus, ['atendida', 'no_asistio'])) {
            return response()->json(['message' => 'No se puede cancelar una cita que ya fue procesada.'], 400);
        }

        $mes = Carbon::parse($cita->fecha_cita);
        $cita->update(['estatus' => 'cancelada']);
        Cache::forget("disp_{$mes->year}_{$mes->month}");
        $cita->load('alumno');

        if ($cita->alumno?->fcm_token) {
            $token = $cita->alumno->fcm_token;
            $fecha = (string) $cita->fecha_cita;
            $hora  = (string) $cita->hora_cita;
            $citaId = (string) $cita->id;
            defer(fn() => (new FcmService())->send(
                $token,
                'Cita cancelada',
                "Tu cita del {$fecha} a las {$hora} fue cancelada.",
                ['cita_id' => $citaId, 'tipo' => 'cita_cancelada']
            ));
        }

        return response()->json(['message' => 'Cita cancelada exitosamente', 'cita' => $cita]);
    }

    // Solo doctor — ruta protegida por role:doctor middleware
    public function atender(Request $request, $id)
    {
        $cita = Cita::findOrFail($id);
        $cita->update([
            'estatus'            => 'atendida',
            'doctor_id'          => $request->user()->id,
            'fecha_hora_atencion' => now(),
        ]);

        return response()->json(['message' => 'Cita marcada como atendida', 'cita' => $cita]);
    }

    // Solo doctor — ruta protegida por role:doctor middleware
    public function reprogramar(Request $request, $id)
    {
        $cita = Cita::findOrFail($id);

        if ($cita->estatus !== 'programada') {
            return response()->json(['message' => 'Solo se pueden reprogramar citas programadas'], 422);
        }

        $validated = $request->validate([
            'fecha_cita' => 'required|date|after_or_equal:today',
            'hora_cita'  => 'required|date_format:H:i',
        ]);

        if ($error = $this->citaService->validarHorario($validated['fecha_cita'], $validated['hora_cita'])) {
            return response()->json(['message' => $error], 422);
        }

        if (!$this->citaService->slotDisponible($validated['fecha_cita'], $validated['hora_cita'], $id)) {
            return response()->json(['message' => 'El horario seleccionado ya no está disponible.'], 422);
        }

        $mesAnterior = Carbon::parse($cita->fecha_cita);
        $cita->update(['fecha_cita' => $validated['fecha_cita'], 'hora_cita' => $validated['hora_cita']]);
        $mesNuevo = Carbon::parse($validated['fecha_cita']);
        Cache::forget("disp_{$mesAnterior->year}_{$mesAnterior->month}");
        Cache::forget("disp_{$mesNuevo->year}_{$mesNuevo->month}");
        $cita->load(['alumno:id,nombre,apellido,numero_control,fcm_token', 'doctor:id,nombre,apellido']);

        if ($cita->alumno?->fcm_token) {
            $token = $cita->alumno->fcm_token;
            $fecha = (string) $cita->fecha_cita;
            $hora  = (string) $cita->hora_cita;
            $citaId = (string) $cita->id;
            defer(fn() => (new FcmService())->send(
                $token,
                'Cita reprogramada',
                "Tu cita fue reprogramada para el {$fecha} a las {$hora}.",
                ['cita_id' => $citaId, 'tipo' => 'cita_reprogramada']
            ));
        }

        return response()->json(['message' => 'Cita reprogramada exitosamente', 'cita' => $cita]);
    }

    // Solo doctor — ruta protegida por role:doctor middleware
    public function noAsistio($id)
    {
        $cita = Cita::findOrFail($id);

        if ($cita->estatus !== 'programada') {
            return response()->json(['message' => 'Solo se pueden marcar como no asistidas las citas programadas'], 422);
        }

        $cita->update(['estatus' => 'no_asistio']);
        return response()->json(['message' => 'Cita marcada como no asistida', 'cita' => $cita]);
    }

    // Solo doctor — busca alumnos por número de control, nombre o apellido (max 20 resultados)
    public function buscarAlumno(Request $request)
    {
        $q = trim((string) $request->input('q', ''));
        if (strlen($q) < 2) {
            return response()->json(['alumnos' => []]);
        }
        $alumnos = User::where('tipo', 'alumno')
            ->where(function ($query) use ($q) {
                $query->where('numero_control', 'ILIKE', "%{$q}%")
                    ->orWhere('nombre', 'ILIKE', "%{$q}%")
                    ->orWhere('apellido', 'ILIKE', "%{$q}%");
            })
            ->select('id', 'numero_control', 'nombre', 'apellido')
            ->limit(20)
            ->get()
            ->map(fn($a) => [
                'id' => $a->id,
                'numero_control' => $a->numero_control,
                'nombre' => "{$a->nombre} {$a->apellido}",
            ]);
        return response()->json(['alumnos' => $alumnos]);
    }
}
