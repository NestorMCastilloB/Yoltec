<?php

namespace App\Services;

use App\Models\Cita;
use App\Models\DiaEspecial;
use Carbon\Carbon;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\Cache;

class CitaService
{
    // Retorna disponibilidad del mes con días especiales — cacheado 15 min
    public function getAvailability(int $month, int $year): array
    {
        return Cache::remember("disp_{$year}_{$month}", 900, function () use ($month, $year) {
            $start = Carbon::create($year, $month, 1)->startOfMonth();
            $end   = (clone $start)->endOfMonth();

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

            $types  = config('clinic.types', []);
            $result = [];
            foreach ($grouped as $date => $slots) {
                $result[$date] = ['date' => $date, 'taken_slots' => array_values(array_unique($slots)), 'special' => null];
            }

            foreach (DiaEspecial::whereYear('fecha', $year)->whereMonth('fecha', $month)->get() as $dia) {
                $date = $dia->fecha->toDateString();
                $result[$date] = array_merge($result[$date] ?? ['date' => $date, 'taken_slots' => [], 'special' => null], [
                    'special' => [
                        'type'        => $dia->tipo,
                        'label'       => $dia->etiqueta,
                        'status'      => $types[$dia->tipo]['status'] ?? 'full',
                        'color'       => $types[$dia->tipo]['color'] ?? '#ef5350',
                        'hora_cierre' => $dia->hora_cierre ? substr((string) $dia->hora_cierre, 0, 5) : null,
                    ],
                ]);
            }

            return array_values($result);
        });
    }

    // Valida día y hora. Retorna null si OK, string de error si inválido.
    public function validarHorario(string $fecha, string $hora): ?string
    {
        if (Carbon::parse($fecha)->dayOfWeek === 0) {
            return 'No se pueden agendar citas los domingos.';
        }
        if ($hora < '08:00' || $hora > '16:45') {
            return 'El horario de atención es de 08:00 a 16:45.';
        }
        if (Carbon::parse($fecha)->isToday() && $hora <= Carbon::now()->format('H:i')) {
            return 'La hora seleccionada ya pasó. Elige una hora futura.';
        }
        $dia = DiaEspecial::where('fecha', $fecha)->first();
        if ($dia) {
            $status = config("clinic.types.{$dia->tipo}.status", 'full');
            if ($status === 'full') {
                $motivo = $dia->etiqueta ?: ($dia->tipo === 'vacation' ? 'vacaciones' : 'festivo');
                return "Este día no hay atención ({$motivo}).";
            }
            if ($status === 'partial' && $dia->hora_cierre) {
                $cierre = substr((string) $dia->hora_cierre, 0, 5);
                if ($hora >= $cierre) {
                    return "Hoy la atención es hasta las {$cierre}. Elige una hora anterior.";
                }
            }
        }
        return null;
    }

    // Reserva slot en transacción con lockForUpdate. Retorna Cita o null si ocupado.
    /**
     * Reserva un horario · devuelve null si ya estaba ocupado · Cita si se creó.
     *
     * Quien garantiza la exclusividad es el índice único parcial
     * citas_slot_programado_unico, no esta comprobación: en PostgreSQL
     * lockForUpdate() no puede bloquear una fila que todavía no existe, así que
     * dos reservas simultáneas del mismo hueco veían "libre" las dos.
     * La consulta previa solo evita el viaje a la base en el caso corriente.
     */
    public function reservarSlot(string $fecha, string $hora, ?string $motivo, int $alumnoId): ?Cita
    {
        $ocupado = Cita::where('fecha_cita', $fecha)
            ->where('hora_cita', $hora)
            ->where('estatus', 'programada')
            ->exists();

        if ($ocupado) {
            return null;
        }

        try {
            return Cita::create([
                'fecha_cita' => $fecha,
                'hora_cita'  => $hora,
                'motivo'     => $motivo,
                'alumno_id'  => $alumnoId,
                'clave_cita' => Cita::generarClaveCita(),
                'estatus'    => 'programada',
            ]);
        } catch (UniqueConstraintViolationException $e) {
            // Otra reserva ganó la carrera entre la comprobación y el insert.
            return null;
        }
    }

    // Comprueba si un slot está disponible, excluyendo opcionalmente una cita (reprogramar).
    public function slotDisponible(string $fecha, string $hora, ?int $exceptId = null): bool
    {
        return !Cita::where('fecha_cita', $fecha)
            ->where('hora_cita', $hora)
            ->where('estatus', 'programada')
            ->when($exceptId, fn($q) => $q->where('id', '!=', $exceptId))
            ->exists();
    }

    // Marca como "no asistió" citas vencidas (grace 15 min). Throttled a 1 ejecución/5min vía caché
    // para evitar update masivo en cada request. Fallback al scheduler cuando éste no corre (Render).
    public function marcarPasadasComoNoAsistio(): void
    {
        if (Cache::has('auto_no_asistio_lock')) {
            return;
        }
        Cache::put('auto_no_asistio_lock', true, 300);

        $cutoff = Carbon::now()->subMinutes(15);

        Cita::where('estatus', 'programada')
            ->where(function ($query) use ($cutoff) {
                $query->where('fecha_cita', '<', $cutoff->toDateString())
                    ->orWhere(function ($sub) use ($cutoff) {
                        $sub->where('fecha_cita', $cutoff->toDateString())
                            ->where('hora_cita', '<=', $cutoff->format('H:i'));
                    });
            })
            ->update(['estatus' => 'no_asistio']);
    }

    // Invalida el cache de disponibilidad del mes correspondiente a la fecha dada.
    public function invalidateAvailabilityCache(string|Carbon $fecha): void
    {
        $mes = $fecha instanceof Carbon ? $fecha : Carbon::parse($fecha);
        Cache::forget("disp_{$mes->year}_{$mes->month}");
    }

    // Envía notificación FCM al alumno de la cita (diferida, solo si tiene token).
    public function notifyAlumno(Cita $cita, string $titulo, string $mensaje, string $tipo): void
    {
        if (!$cita->alumno?->fcm_token) {
            return;
        }
        $token  = $cita->alumno->fcm_token;
        $fecha  = (string) $cita->fecha_cita;
        $hora   = (string) $cita->hora_cita;
        $citaId = (string) $cita->id;
        defer(fn() => (new FcmService())->send(
            $token,
            $titulo,
            str_replace([':fecha', ':hora'], [$fecha, $hora], $mensaje),
            ['cita_id' => $citaId, 'tipo' => $tipo]
        ));
    }
}
