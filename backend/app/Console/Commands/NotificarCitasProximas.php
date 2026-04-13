<?php

namespace App\Console\Commands;

use App\Mail\CitaProximaMail;
use App\Models\Cita;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Mail;
use Carbon\Carbon;

class NotificarCitasProximas extends Command
{
    protected $signature = 'citas:notificar-proximas';
    protected $description = 'Envía recordatorio por email a alumnos con cita en las próximas 24 horas';

    public function handle(): void
    {
        $ahora = Carbon::now();
        $en24h = $ahora->copy()->addHours(24);

        $citas = Cita::with('alumno')
            ->where('estatus', 'programada')
            ->whereDate('fecha_cita', $en24h->toDateString())
            ->get();

        if ($citas->isEmpty()) {
            $this->info('Sin citas próximas para notificar.');
            return;
        }

        foreach ($citas as $cita) {
            $alumno = $cita->alumno;

            if (!$alumno || !$alumno->email) {
                continue;
            }

            // Solo notificar si la hora de la cita está dentro de las próximas 24h
            $fechaHoraCita = Carbon::parse("{$cita->fecha_cita} {$cita->hora_cita}");
            if ($fechaHoraCita->lt($ahora) || $fechaHoraCita->gt($en24h)) {
                continue;
            }

            Mail::to($alumno->email)->send(new CitaProximaMail(
                nombreAlumno: "{$alumno->nombre} {$alumno->apellido}",
                fechaCita: Carbon::parse($cita->fecha_cita)->translatedFormat('l d \d\e F \d\e Y'),
                horaCita: Carbon::parse($cita->hora_cita)->format('H:i') . ' hrs',
                motivo: $cita->motivo ?? ''
            ));

            $this->info("Notificado: {$alumno->email} — cita {$cita->clave_cita}");
        }
    }
}
