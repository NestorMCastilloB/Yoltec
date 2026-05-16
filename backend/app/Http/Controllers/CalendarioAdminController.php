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
            ->get();

        return response()->json(['dias' => $dias, 'month' => $month, 'year' => $year]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'fecha'   => 'required|date|after_or_equal:today',
            'tipo'    => 'required|in:holiday,vacation,reduced',
            'etiqueta' => 'nullable|string|max:200',
        ], [
            'fecha.after_or_equal' => 'No se pueden registrar días especiales en fechas pasadas.',
        ]);

        $dia = DiaEspecial::updateOrCreate(
            ['fecha' => $data['fecha']],
            ['tipo' => $data['tipo'], 'etiqueta' => $data['etiqueta'] ?? null]
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
