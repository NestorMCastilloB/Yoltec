<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use App\Models\DiaEspecial;
use Carbon\Carbon;

class CalendarioAdminController extends Controller
{
    public function index(Request $request)
    {
        $request->validate([
            'month' => 'nullable|integer|min:1|max:12',
            'year'  => 'nullable|integer|min:2000|max:2100',
        ]);

        $month = $request->input('month', now()->month);
        $year  = $request->input('year', now()->year);

        $dias = DiaEspecial::whereYear('fecha', $year)
            ->whereMonth('fecha', $month)
            ->orderBy('fecha')
            ->get()
            ->map(function ($d) {
                $d->hora_cierre = $d->hora_cierre ? substr((string) $d->hora_cierre, 0, 5) : null;
                return $d;
            });

        return response()->json(['dias' => $dias, 'month' => $month, 'year' => $year]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'fecha'       => 'required|date|after_or_equal:today',
            'tipo'        => 'required|in:holiday,vacation,reduced',
            'etiqueta'    => 'nullable|string|max:200',
            'hora_cierre' => 'nullable|date_format:H:i|required_if:tipo,reduced|after_or_equal:08:00|before_or_equal:16:45',
        ], [
            'fecha.after_or_equal'        => 'No se pueden registrar días especiales en fechas pasadas.',
            'hora_cierre.required_if'     => 'Especifica la hora de cierre para un día de horario reducido.',
            'hora_cierre.date_format'     => 'La hora de cierre debe tener formato HH:MM.',
            'hora_cierre.after_or_equal'  => 'La hora de cierre no puede ser antes de las 08:00.',
            'hora_cierre.before_or_equal' => 'La hora de cierre no puede ser después de las 16:45.',
        ]);

        $dia = DiaEspecial::updateOrCreate(
            ['fecha' => $data['fecha']],
            [
                'tipo'        => $data['tipo'],
                'etiqueta'    => $data['etiqueta'] ?? null,
                'hora_cierre' => $data['tipo'] === 'reduced' ? $data['hora_cierre'] : null,
            ]
        );

        $this->invalidarCacheDisponibilidad($data['fecha']);

        return response()->json(['message' => 'Día especial guardado.', 'dia' => $dia], 201);
    }

    public function destroy(Request $request, $id)
    {
        $dia = DiaEspecial::findOrFail($id);
        $fecha = $dia->fecha->toDateString();
        $dia->delete();
        $this->invalidarCacheDisponibilidad($fecha);
        return response()->json(['message' => 'Día eliminado del calendario.']);
    }

    // Invalida el cache de disponibilidad del mes/año al que pertenece la fecha
    private function invalidarCacheDisponibilidad(string $fecha): void
    {
        $c = Carbon::parse($fecha);
        Cache::forget("disp_{$c->year}_{$c->month}");
    }
}
