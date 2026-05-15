<?php

namespace App\Console\Commands;

use App\Models\Cita;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

class AutoCancelarCitasPasadas extends Command
{
    protected $signature = 'citas:auto-cancelar-pasadas';
    protected $description = 'Marca como "no asistió" las citas programadas cuya fecha y hora ya pasaron';

    public function handle(): void
    {
        // Grace period 15 min: la cita se marca como "no asistió" 15 min después de la hora agendada
        $cutoff = Carbon::now()->subMinutes(15);

        $affected = Cita::where('estatus', 'programada')
            ->where(function ($query) use ($cutoff) {
                $query->where('fecha_cita', '<', $cutoff->toDateString())
                    ->orWhere(function ($sub) use ($cutoff) {
                        $sub->where('fecha_cita', $cutoff->toDateString())
                            ->where('hora_cita', '<=', $cutoff->format('H:i'));
                    });
            })
            ->update(['estatus' => 'no_asistio']);

        $this->info("Citas marcadas como no asistidas: {$affected}");
    }
}
