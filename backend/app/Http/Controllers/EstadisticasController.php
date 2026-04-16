<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Cita;
use Carbon\Carbon;

class EstadisticasController extends Controller
{
    public function index(Request $request)
    {
        // Solo doctores pueden ver estadísticas
        $user = $request->user();
        if ($user->tipo !== 'doctor') {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        // Citas por mes (últimos 6 meses)
        $citasPorMes = [];
        for ($i = 5; $i >= 0; $i--) {
            $mes = Carbon::now()->subMonths($i)->startOfMonth();
            $fin = $mes->copy()->endOfMonth();

            $citas = Cita::whereBetween('fecha_cita', [$mes->toDateString(), $fin->toDateString()])->get();

            $citasPorMes[] = [
                'mes'        => $mes->format('Y-m'),
                'label'      => ucfirst($mes->locale('es')->isoFormat('MMM YYYY')),
                'total'      => $citas->count(),
                'atendidas'  => $citas->where('estatus', 'atendida')->count(),
                'canceladas' => $citas->where('estatus', 'cancelada')->count(),
                'no_asistio' => $citas->where('estatus', 'no_asistio')->count(),
                'programadas' => $citas->where('estatus', 'programada')->count(),
            ];
        }

        // Resumen total por estado
        $todas = Cita::all();
        $resumenEstados = [
            'programada' => $todas->where('estatus', 'programada')->count(),
            'atendida'   => $todas->where('estatus', 'atendida')->count(),
            'cancelada'  => $todas->where('estatus', 'cancelada')->count(),
            'no_asistio' => $todas->where('estatus', 'no_asistio')->count(),
        ];

        $totalCerradas = $resumenEstados['atendida'] + $resumenEstados['cancelada'] + $resumenEstados['no_asistio'];
        $tasaAsistencia = $totalCerradas > 0
            ? round(($resumenEstados['atendida'] / $totalCerradas) * 100, 1)
            : 0;

        return response()->json([
            'citas_por_mes'   => $citasPorMes,
            'resumen_estados' => $resumenEstados,
            'tasa_asistencia' => $tasaAsistencia,
            'total_citas'     => $todas->count(),
        ]);
    }
}
