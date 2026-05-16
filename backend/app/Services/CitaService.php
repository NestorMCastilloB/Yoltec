<?php

namespace App\Services;

use App\Models\Cita;
use App\Models\DiaEspecial;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

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
    public function reservarSlot(string $fecha, string $hora, ?string $motivo, int $alumnoId): ?Cita
    {
        return DB::transaction(function () use ($fecha, $hora, $motivo, $alumnoId) {
            $ocupado = Cita::where('fecha_cita', $fecha)
                ->where('hora_cita', $hora)
                ->where('estatus', 'programada')
                ->lockForUpdate()
                ->exists();

            if ($ocupado) {
                return null;
            }

            return Cita::create([
                'fecha_cita' => $fecha,
                'hora_cita'  => $hora,
                'motivo'     => $motivo,
                'alumno_id'  => $alumnoId,
                'clave_cita' => Cita::generarClaveCita(),
                'estatus'    => 'programada',
            ]);
        });
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
}
