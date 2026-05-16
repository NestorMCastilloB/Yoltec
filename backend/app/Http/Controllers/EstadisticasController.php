<?php

namespace App\Http\Controllers;

use App\Models\Cita;
use App\Models\Bitacora;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;

class EstadisticasController extends Controller
{
    // Solo doctor — protegido por role:doctor middleware
    public function index()
    {
        $data = Cache::remember('estadisticas', 1800, fn () => $this->calcular());

        return response()->json($data);
    }

    private function calcular(): array
    {
        $desde = Carbon::now()->subMonths(5)->startOfMonth()->toDateString();

        // 1 query: citas de los últimos 6 meses por mes y estatus
        $rawCitas = Cita::where('fecha_cita', '>=', $desde)
            ->selectRaw("to_char(fecha_cita, 'YYYY-MM') as mes, estatus, COUNT(*) as total")
            ->groupBy('mes', 'estatus')
            ->get()
            ->groupBy('mes');

        // 1 query: resumen histórico total por estatus
        $resumenRaw = Cita::selectRaw("estatus, COUNT(*) as total")
            ->groupBy('estatus')
            ->pluck('total', 'estatus');

        $resumenEstados = [
            'programada' => (int) ($resumenRaw['programada'] ?? 0),
            'atendida'   => (int) ($resumenRaw['atendida'] ?? 0),
            'cancelada'  => (int) ($resumenRaw['cancelada'] ?? 0),
            'no_asistio' => (int) ($resumenRaw['no_asistio'] ?? 0),
        ];

        $totalCerradas = $resumenEstados['atendida'] + $resumenEstados['cancelada'] + $resumenEstados['no_asistio'];
        $tasaAsistencia = $totalCerradas > 0
            ? round(($resumenEstados['atendida'] / $totalCerradas) * 100, 1)
            : 0;

        $citasPorMes = [];
        for ($i = 5; $i >= 0; $i--) {
            $mes = Carbon::now()->subMonths($i)->startOfMonth();
            $mesKey = $mes->format('Y-m');
            $mesCitas = $rawCitas->get($mesKey, collect());
            $desglose  = $mesCitas->pluck('total', 'estatus');

            $citasPorMes[] = [
                'mes'         => $mesKey,
                'label'       => ucfirst($mes->locale('es')->isoFormat('MMM YYYY')),
                'total'       => (int) $mesCitas->sum('total'),
                'atendidas'   => (int) ($desglose['atendida'] ?? 0),
                'canceladas'  => (int) ($desglose['cancelada'] ?? 0),
                'no_asistio'  => (int) ($desglose['no_asistio'] ?? 0),
                'programadas' => (int) ($desglose['programada'] ?? 0),
            ];
        }

        // 1 query: top 5 diagnósticos + total general via window function
        $dxRows = Bitacora::whereNotNull('diagnostico')
            ->where('diagnostico', '!=', '')
            ->selectRaw("diagnostico, COUNT(*) as total, SUM(COUNT(*)) OVER () as grand_total")
            ->groupBy('diagnostico')
            ->orderByDesc('total')
            ->limit(5)
            ->get();

        $totalBitacoras = (int) ($dxRows->first()?->grand_total ?? 0);
        $diagnosticosFrecuentes = $dxRows->map(fn ($d) => [
            'diagnostico' => $d->diagnostico,
            'total'       => (int) $d->total,
            'pct'         => $totalBitacoras > 0 ? (int) round($d->total / $totalBitacoras * 100) : 0,
        ]);

        return [
            'citas_por_mes'           => $citasPorMes,
            'resumen_estados'         => $resumenEstados,
            'tasa_asistencia'         => $tasaAsistencia,
            'total_citas'             => (int) $resumenRaw->sum(),
            'diagnosticos_frecuentes' => $diagnosticosFrecuentes,
        ];
    }
}
