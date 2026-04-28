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
        $now = Carbon::now();

        $affected = Cita::where('estatus', 'programada')
            ->where(function ($query) use ($now) {
                $query->where('fecha_cita', '<', $now->toDateString())
                    ->orWhere(function ($sub) use ($now) {
                        $sub->where('fecha_cita', $now->toDateString())
                            ->where('hora_cita', '<=', $now->format('H:i'));
                    });
            })
            ->update(['estatus' => 'no_asistio']);

        $this->info("Citas marcadas como no asistidas: {$affected}");
    }
}
