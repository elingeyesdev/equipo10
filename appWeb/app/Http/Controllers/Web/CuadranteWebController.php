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

    /**
     * Muestra el editor de dibujo de polígonos (Herramienta de Admin)
     */
    public function editor()
    {
        try {
            $cuadrantes = Cuadrante::all();
            return view('cuadrantes.editor', compact('cuadrantes'));
        } catch (\Exception $e) {
            \Log::error("Error en Editor de Cuadrantes: " . $e->getMessage());
            return redirect()->route('cuadrantes.index')->with('error', 'No se pudo abrir el editor: ' . $e->getMessage());
        }
    }

    /**
     * Guarda la geometría dibujada desde el editor
     */
    public function saveGeometry(Request $request)
    {
        $request->validate([
            'id' => 'nullable|uuid|exists:cuadrantes,id',
            'nombre' => 'required|string|max:100',
            'codigo' => 'required|string|max:20',
            'geometria' => 'required|string', // GeoJSON string
            'centro' => 'required|array',     // [lat, lng]
            'zona' => 'nullable|string|max:100',
            'ciudad' => 'required|string|max:100',
        ]);

        // Calcular Bounding Box para compatibilidad con filtros antiguos
        $geoJson = json_decode($request->geometria, true);
        $lat_min = 90; $lat_max = -90; $lng_min = 180; $lng_max = -180;

        if (isset($geoJson['geometry']['coordinates'][0])) {
            foreach ($geoJson['geometry']['coordinates'][0] as $coord) {
                $lng = $coord[0];
                $lat = $coord[1];
                if ($lat < $lat_min) $lat_min = $lat;
                if ($lat > $lat_max) $lat_max = $lat;
                if ($lng < $lng_min) $lng_min = $lng;
                if ($lng > $lng_max) $lng_max = $lng;
            }
        }

        // Si viene un ID, actualizamos, si no, creamos uno nuevo
        if ($request->id) {
            $cuadrante = Cuadrante::find($request->id);
            $cuadrante->update([
                'nombre' => $request->nombre,
                'codigo' => $request->codigo,
                'geometria' => $request->geometria,
                'lat_min' => $lat_min,
                'lat_max' => $lat_max,
                'lng_min' => $lng_min,
                'lng_max' => $lng_max,
                'centro_lat' => $request->centro['lat'],
                'centro_lng' => $request->centro['lng'],
                'zona' => $request->zona,
                'ciudad' => $request->ciudad,
            ]);
        } else {
            // Verificar si el código ya existe para otro cuadrante
            if (Cuadrante::where('codigo', $request->codigo)->exists()) {
                return response()->json(['error' => 'El código ya existe'], 422);
            }

            // Crear cuadrante con datos reales
            $cuadrante = Cuadrante::create([
                'codigo' => $request->codigo,
                'nombre' => $request->nombre,
                'fila' => 'X',
                'columna' => rand(1000, 9999),
                'geometria' => $request->geometria,
                'lat_min' => $lat_min,
                'lat_max' => $lat_max,
                'lng_min' => $lng_min,
                'lng_max' => $lng_max,
                'centro_lat' => $request->centro['lat'],
                'centro_lng' => $request->centro['lng'],
                'zona' => $request->zona,
                'ciudad' => $request->ciudad,
                'activo' => true
            ]);
        }

        return response()->json($cuadrante, 201);
    }
}