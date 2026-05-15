<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Cita;
use App\Models\User;
use App\Models\DiaEspecial;
use App\Services\FcmService;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

/**
 * Controlador para gestionar citas
 */
class CitaController extends Controller
{
    // Listar citas
    public function index(Request $request)
    {
        $user = $request->user();

        if ($user->esAlumno()) {
            $citas = Cita::where('alumno_id', $user->id)
                        ->with(['doctor:id,nombre,apellido,username'])
                        ->orderBy('fecha_cita', 'desc')
                        ->orderBy('hora_cita', 'desc')
                        ->get();
        } else {
            $citas = Cita::with(['alumno:id,nombre,apellido,numero_control'])
                        ->orderBy('fecha_cita', 'desc')
                        ->orderBy('hora_cita', 'desc')
                        ->get();
        }

        return response()->json(['citas' => $citas], 200);
    }

    public function availability(Request $request)
    {
        $request->validate([
            'month' => 'nullable|integer|min:1|max:12',
            'year' => 'nullable|integer|min:2000|max:2100',
        ]);

        $month = $request->input('month', now()->month);
        $year = $request->input('year', now()->year);

        $start = Carbon::create($year, $month, 1)->startOfMonth();
        $end = (clone $start)->endOfMonth();

        $days = Cache::remember("disp_{$year}_{$month}", 900, function () use ($start, $end, $year, $month) {
            $citas = Cita::whereBetween('fecha_cita', [$start->toDateString(), $end->toDateString()])
                ->where('estatus', 'programada')
                ->select('fecha_cita', 'hora_cita')
                ->get();

            $grouped = [];
            foreach ($citas as $cita) {
                $dateKey = $cita->fecha_cita instanceof Carbon
                    ? $cita->fecha_cita->toDateString()
                    : (string) $cita->fecha_cita;

                $grouped[$dateKey][] = Carbon::parse($cita->hora_cita)->format('H:i');
            }

            $types = config('clinic.types', []);
            $result = [];
            foreach ($grouped as $date => $slots) {
                $result[$date] = ['date' => $date, 'taken_slots' => array_values(array_unique($slots)), 'special' => null];
            }

            foreach (DiaEspecial::whereYear('fecha', $year)->whereMonth('fecha', $month)->get() as $dia) {
                $date = $dia->fecha->toDateString();
                $result[$date] = array_merge($result[$date] ?? ['date' => $date, 'taken_slots' => [], 'special' => null], [
                    'special' => [
                        'type'   => $dia->tipo,
                        'label'  => $dia->etiqueta,
                        'status' => $types[$dia->tipo]['status'] ?? 'full',
                        'color'  => $types[$dia->tipo]['color'] ?? '#ef5350',
                    ],
                ]);
            }

            return array_values($result);
        });

        return response()->json(['month' => $month, 'year' => $year, 'days' => $days]);
    }

    // Crear cita
    public function store(Request $request)
    {
        $validated = $request->validate([
            'fecha_cita' => 'required|date|after_or_equal:today',
            'hora_cita' => 'required|date_format:H:i',
            'motivo' => 'nullable|string|max:500',
            'numero_control' => 'nullable|string|exists:users,numero_control',
        ], [
            'fecha_cita.required' => 'La fecha de la cita es obligatoria.',
            'fecha_cita.date' => 'Ingresa una fecha de cita válida.',
            'fecha_cita.after_or_equal' => 'La fecha de la cita debe ser hoy o una fecha futura.',
            'hora_cita.required' => 'La hora de la cita es obligatoria.',
            'hora_cita.date_format' => 'La hora de la cita debe tener el formato HH:MM.',
            'numero_control.exists' => 'No se encontró un alumno con ese número de control. Verifica los datos ingresados.',
        ]);

        // Validar que no sea domingo
        $diaSemana = Carbon::parse($validated['fecha_cita'])->dayOfWeek;
        if ($diaSemana === 0) {
            return response()->json([
                'message' => 'No se pueden agendar citas los domingos.',
            ], 422);
        }

        // Validar horario de atención: 08:00 a 16:45 (último slot antes de las 17:00)
        $hora = $validated['hora_cita'];
        if ($hora < '08:00' || $hora > '16:45') {
            return response()->json([
                'message' => 'El horario de atención es de 08:00 a 16:45.',
            ], 422);
        }

        $user = $request->user();

        // Usar transacción con lockForUpdate para prevenir double-booking
        $cita = DB::transaction(function () use ($validated, $user, $request) {
            $slotOcupado = Cita::where('fecha_cita', $validated['fecha_cita'])
                ->where('hora_cita', $validated['hora_cita'])
                ->where('estatus', 'programada')
                ->lockForUpdate()
                ->exists();

            if ($slotOcupado) {
                return null;
            }

            // Generar clave única
            $validated['clave_cita'] = Cita::generarClaveCita();
            if ($user->esAlumno()) {
                $validated['alumno_id'] = $user->id;
            } elseif ($request->filled('numero_control')) {
                $alumno = User::where('numero_control', $request->numero_control)->firstOrFail();
                $validated['alumno_id'] = $alumno->id;
            } else {
                $validated['alumno_id'] = $request->alumno_id;
            }
            $validated['estatus'] = 'programada';

            return Cita::create($validated);
        });

        if (!$cita) {
            return response()->json([
                'message' => 'El horario seleccionado ya no está disponible. Elige otra hora.',
            ], 422);
        }

        $cita->load(['alumno:id,nombre,apellido,numero_control,fcm_token', 'doctor:id,nombre,apellido']);
        $fechaCita = Carbon::parse($cita->fecha_cita);
        Cache::forget("disp_{$fechaCita->year}_{$fechaCita->month}");

        // Notificación push al alumno
        if ($cita->alumno?->fcm_token) {
            (new FcmService())->send(
                $cita->alumno->fcm_token,
                'Cita confirmada',
                "Tu cita está programada para el {$cita->fecha_cita} a las {$cita->hora_cita}.",
                ['cita_id' => (string) $cita->id, 'tipo' => 'cita_confirmada']
            );
        }

        return response()->json([
            'message' => 'Cita agendada exitosamente',
            'cita' => $cita
        ], 201);
    }

    // Ver una cita
    public function show(Request $request, $id)
    {
        $user = $request->user();
        $cita = Cita::with(['alumno', 'doctor', 'bitacora', 'receta'])->findOrFail($id);

        // Verificar permisos
        if ($user->esAlumno() && $cita->alumno_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        return response()->json($cita, 200);
    }

    // Cancelar cita
    public function cancelar(Request $request, $id)
    {
        $user = $request->user();
        $cita = Cita::findOrFail($id);

        // Verificar permisos
        if ($user->esAlumno() && $cita->alumno_id !== $user->id) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        if (in_array($cita->estatus, ['atendida', 'no_asistio'])) {
            return response()->json([
                'message' => 'No se puede cancelar una cita que ya fue procesada.'
            ], 400);
        }

        $mes = Carbon::parse($cita->fecha_cita);
        $cita->update(['estatus' => 'cancelada']);
        Cache::forget("disp_{$mes->year}_{$mes->month}");
        $cita->load('alumno');

        // Notificación push al alumno
        if ($cita->alumno?->fcm_token) {
            (new FcmService())->send(
                $cita->alumno->fcm_token,
                'Cita cancelada',
                "Tu cita del {$cita->fecha_cita} a las {$cita->hora_cita} fue cancelada.",
                ['cita_id' => (string) $cita->id, 'tipo' => 'cita_cancelada']
            );
        }

        return response()->json([
            'message' => 'Cita cancelada exitosamente',
            'cita' => $cita
        ], 200);
    }

    // Marcar como atendida (solo doctor)
    public function atender(Request $request, $id)
    {
        $user = $request->user();

        if (!$user->esDoctor()) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $cita = Cita::findOrFail($id);

        $cita->update([
            'estatus' => 'atendida',
            'doctor_id' => $user->id,
            'fecha_hora_atencion' => now(),
        ]);

        return response()->json([
            'message' => 'Cita marcada como atendida',
            'cita' => $cita
        ], 200);
    }

    // Reprogramar cita (solo doctor)
    public function reprogramar(Request $request, $id)
    {
        $user = $request->user();

        if (!$user->esDoctor()) {
            return response()->json(['message' => 'Solo el doctor puede reprogramar citas'], 403);
        }

        $cita = Cita::findOrFail($id);

        if ($cita->estatus !== 'programada') {
            return response()->json(['message' => 'Solo se pueden reprogramar citas programadas'], 422);
        }

        $validated = $request->validate([
            'fecha_cita' => 'required|date|after_or_equal:today',
            'hora_cita'  => 'required|date_format:H:i',
        ]);

        $diaSemana = Carbon::parse($validated['fecha_cita'])->dayOfWeek;
        if ($diaSemana === 0) {
            return response()->json(['message' => 'No se pueden agendar citas los domingos.'], 422);
        }

        if ($validated['hora_cita'] < '08:00' || $validated['hora_cita'] > '16:45') {
            return response()->json(['message' => 'El horario de atención es de 08:00 a 16:45.'], 422);
        }

        $slotOcupado = Cita::where('fecha_cita', $validated['fecha_cita'])
            ->where('hora_cita', $validated['hora_cita'])
            ->where('estatus', 'programada')
            ->where('id', '!=', $id)
            ->exists();

        if ($slotOcupado) {
            return response()->json(['message' => 'El horario seleccionado ya no está disponible.'], 422);
        }

        $mesAnterior = Carbon::parse($cita->fecha_cita);
        $cita->update([
            'fecha_cita' => $validated['fecha_cita'],
            'hora_cita'  => $validated['hora_cita'],
        ]);
        $mesNuevo = Carbon::parse($validated['fecha_cita']);
        Cache::forget("disp_{$mesAnterior->year}_{$mesAnterior->month}");
        Cache::forget("disp_{$mesNuevo->year}_{$mesNuevo->month}");
        $cita->load(['alumno:id,nombre,apellido,numero_control,fcm_token', 'doctor:id,nombre,apellido']);

        if ($cita->alumno?->fcm_token) {
            (new FcmService())->send(
                $cita->alumno->fcm_token,
                'Cita reprogramada',
                "Tu cita fue reprogramada para el {$cita->fecha_cita} a las {$cita->hora_cita}.",
                ['cita_id' => (string) $cita->id, 'tipo' => 'cita_reprogramada']
            );
        }

        return response()->json([
            'message' => 'Cita reprogramada exitosamente',
            'cita'    => $cita
        ], 200);
    }

    // Marcar como no asistió (solo doctor, manual)
    public function noAsistio(Request $request, $id)
    {
        $user = $request->user();

        if (!$user->esDoctor()) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $cita = Cita::findOrFail($id);

        if ($cita->estatus !== 'programada') {
            return response()->json(['message' => 'Solo se pueden marcar como no asistidas las citas programadas'], 422);
        }

        $cita->update(['estatus' => 'no_asistio']);

        return response()->json([
            'message' => 'Cita marcada como no asistida',
            'cita' => $cita
        ], 200);
    }
}

