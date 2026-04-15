<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Cuadrante;
use Illuminate\Http\Request;

class CuadranteWebController extends Controller
{
    public function index()
    {
        $cuadrantes = Cuadrante::withCount('reportes')
            ->with('grupos')
            ->orderBy('fila')
            ->orderBy('columna')
            ->get();
            
        $grupos = \App\Models\Grupo::count();

        // Obtener reportes activos con ubicación para el mapa
        // Obtener TODOS los reportes con ubicación para el mapa "Amber Alert"
        $reportes = \App\Models\Reporte::with(['categoria', 'imagenes', 'respuestas'])
            ->whereNotNull('ubicacion_exacta_lat')
            ->whereNotNull('ubicacion_exacta_lng')
            ->get(); // Traemos todos los atributos para el detalle completo
        
        return view('cuadrantes.index', compact('cuadrantes', 'grupos', 'reportes'));
    }

    public function create()
    {
        return view('cuadrantes.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'codigo' => 'required|string|max:20|unique:cuadrantes,codigo',
            'fila' => 'required|string|max:5',
            'columna' => 'required|integer',
            'nombre' => 'nullable|string|max:100',
            'lat_min' => 'required|numeric',
            'lat_max' => 'required|numeric',
            'lng_min' => 'required|numeric',
            'lng_max' => 'required|numeric',
            'ciudad' => 'required|string|max:100',
            'zona' => 'nullable|string|max:100',
            'activo' => 'nullable|boolean',
            'barrios' => 'nullable|array'
        ]);

        $cuadrante = Cuadrante::create($validated);

        
        if ($request->wantsJson() || $request->ajax()) {
            return response()->json($cuadrante, 201);
        }

        return redirect()->route('cuadrantes.index')
            ->with('success', 'Cuadrante creado exitosamente');
    }

    public function show(Cuadrante $cuadrante)
    {
        $cuadrante->load(['reportes', 'grupos']);
        
        return view('cuadrantes.show', compact('cuadrante'));
    }

    public function edit(Cuadrante $cuadrante)
    {
        return view('cuadrantes.edit', compact('cuadrante'));
    }

    public function update(Request $request, Cuadrante $cuadrante)
    {
        $validated = $request->validate([
            'nombre' => 'sometimes|string|max:100',
            'zona' => 'sometimes|string|max:100',
            'activo' => 'sometimes|boolean',
        ]);

        $cuadrante->update($validated);

        return redirect()->route('cuadrantes.show', $cuadrante)
            ->with('success', 'Cuadrante actualizado exitosamente');
    }

    public function destroy(Cuadrante $cuadrante)
    {
        $cuadrante->delete();

        return redirect()->route('cuadrantes.index')
            ->with('success', 'Cuadrante eliminado exitosamente');
    }
}