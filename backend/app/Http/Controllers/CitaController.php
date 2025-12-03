<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Cita;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

/**
 * Controlador para gestionar citas
 */
class CitaController extends Controller
{
    /**
     * Marcar automáticamente como canceladas las citas programadas
     * cuya fecha y hora ya quedaron en el pasado.
     */
    private function autoCancelPastAppointments(): void
    {
        $now = Carbon::now();

        Cita::where('estatus', 'programada')
            ->where(function ($query) use ($now) {
                $query->where('fecha_cita', '<', $now->toDateString())
                    ->orWhere(function ($sub) use ($now) {
                        $sub->where('fecha_cita', $now->toDateString())
                            ->where('hora_cita', '<=', $now->format('H:i'));
                    });
            })
            ->update(['estatus' => 'cancelada']);
    }

    // Listar citas
    public function index(Request $request)
    {
        // Antes de devolver las citas, actualizar estatus de las que ya pasaron
        $this->autoCancelPastAppointments();

        $user = $request->user();

        if ($user->esAlumno()) {
            $citas = Cita::where('alumno_id', $user->id)
                        ->with(['doctor'])
                        ->orderBy('fecha_cita', 'desc')
                        ->orderBy('hora_cita', 'desc')
                        ->get();
        } else {
            $citas = Cita::with(['alumno'])
                        ->orderBy('fecha_cita', 'desc')
                        ->orderBy('hora_cita', 'desc')
                        ->get();
        }

        return response()->json($citas, 200);
    }

    public function availability(Request $request)
    {
        // Asegurar que citas pasadas ya no cuenten como "programadas" para la disponibilidad
        $this->autoCancelPastAppointments();

        $request->validate([
            'month' => 'nullable|integer|min:1|max:12',
            'year' => 'nullable|integer|min:2000|max:2100',
        ]);

        $month = $request->input('month', now()->month);
        $year = $request->input('year', now()->year);

        $start = Carbon::create($year, $month, 1)->startOfMonth();
        $end = (clone $start)->endOfMonth();

        $citas = Cita::whereBetween('fecha_cita', [$start->toDateString(), $end->toDateString()])
            ->where('estatus', 'programada')
            ->get();

        $grouped = [];
        foreach ($citas as $cita) {
            // "fecha_cita" está casteada como Carbon en el modelo, así que
            // la normalizamos a string (Y-m-d) para usarla como llave de arreglo.
            $dateKey = $cita->fecha_cita instanceof Carbon
                ? $cita->fecha_cita->toDateString()
                : (string) $cita->fecha_cita;

            $normalizedHour = Carbon::parse($cita->hora_cita)->format('H:i');
            $grouped[$dateKey][] = $normalizedHour;
        }

        $specialDays = config('clinic.special_days', []);
        $types = config('clinic.types', []);

        $days = [];
        foreach ($grouped as $date => $slots) {
            $uniqueSlots = array_values(array_unique($slots));
            $days[$date] = [
                'date' => $date,
                'taken_slots' => $uniqueSlots,
                'special' => null,
            ];
        }

        foreach ($specialDays as $day) {
            if (!isset($day['date'], $day['type'])) {
                continue;
            }
            $date = $day['date'];
            $type = $day['type'];

            $dateCarbon = Carbon::parse($date);
            if ($dateCarbon->month !== $month || $dateCarbon->year !== $year) {
                continue;
            }

            $days[$date] = array_merge($days[$date] ?? [
                'date' => $date,
                'taken_slots' => [],
                'special' => null,
            ], [
                'special' => [
                    'type' => $type,
                    'label' => $day['label'] ?? null,
                    'status' => $types[$type]['status'] ?? 'full',
                    'color' => $types[$type]['color'] ?? '#ef5350',
                ],
            ]);
        }

        return response()->json([
            'month' => $month,
            'year' => $year,
            'days' => array_values($days),
        ]);
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

        $slotOcupado = Cita::where('fecha_cita', $validated['fecha_cita'])
            ->where('hora_cita', $validated['hora_cita'])
            ->where('estatus', 'programada')
            ->exists();

        if ($slotOcupado) {
            return response()->json([
                'message' => 'El horario seleccionado ya no está disponible. Elige otra hora.',
            ], 422);
        }

        $user = $request->user();

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

        $cita = Cita::create($validated);

        return response()->json([
            'message' => 'Cita agendada exitosamente',
            'cita' => $cita->load(['alumno', 'doctor'])
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

        if ($cita->estatus === 'atendida') {
            return response()->json([
                'message' => 'No se puede cancelar una cita ya atendida'
            ], 400);
        }

        $cita->update(['estatus' => 'cancelada']);

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
}

