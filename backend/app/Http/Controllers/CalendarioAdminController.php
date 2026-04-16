<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\DiaEspecial;
use Carbon\Carbon;

class CalendarioAdminController extends Controller
{
    private function checkAdmin(Request $request)
    {
        if ($request->user()?->tipo !== 'admin') {
            abort(403, 'No autorizado');
        }
    }

    public function index(Request $request)
    {
        $this->checkAdmin($request);
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
        $this->checkAdmin($request);
        $data = $request->validate([
            'fecha'   => 'required|date',
            'tipo'    => 'required|in:holiday,vacation,reduced',
            'etiqueta' => 'nullable|string|max:200',
        ]);

        $dia = DiaEspecial::updateOrCreate(
            ['fecha' => $data['fecha']],
            ['tipo' => $data['tipo'], 'etiqueta' => $data['etiqueta'] ?? null]
        );

        return response()->json(['message' => 'Día especial guardado.', 'dia' => $dia], 201);
    }

    public function destroy(Request $request, $id)
    {
        $this->checkAdmin($request);
        $dia = DiaEspecial::findOrFail($id);
        $dia->delete();
        return response()->json(['message' => 'Día eliminado del calendario.']);
    }
}
