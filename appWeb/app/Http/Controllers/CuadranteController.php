<?php

namespace App\Http\Controllers;

use App\Models\Cuadrante;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CuadranteController extends Controller
{
    public function index(Request $request)
    {
        $query = Cuadrante::query();

        
        if ($request->has('ciudad')) {
            $query->where('ciudad', $request->ciudad);
        }
        
        if ($request->has('zona')) {
            $query->where('zona', $request->zona);
        }
        
        if ($request->has('fila')) {
            $query->where('fila', $request->fila);
        }
        
        if ($request->has('columna')) {
            $query->where('columna', $request->columna);
        }

        if ($request->has('activo')) {
            $query->where('activo', $request->boolean('activo'));
        }

        $cuadrantes = $query->orderBy('fila')->orderBy('columna')->get();
        
        return response()->json($cuadrantes);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
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
            'barrios' => 'nullable|array',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $cuadrante = Cuadrante::create($request->all());
        
        return response()->json($cuadrante, 201);
    }

    public function show($id)
    {
        $cuadrante = Cuadrante::with(['reportes', 'grupos'])->findOrFail($id);
        
        return response()->json($cuadrante);
    }

    public function update(Request $request, $id)
    {
        $cuadrante = Cuadrante::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'codigo' => 'sometimes|string|max:20|unique:cuadrantes,codigo,' . $id,
            'nombre' => 'sometimes|string|max:100',
            'zona' => 'sometimes|string|max:100',
            'activo' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $cuadrante->update($request->all());
        
        return response()->json($cuadrante);
    }

    public function destroy($id)
    {
        $cuadrante = Cuadrante::findOrFail($id);
        $cuadrante->delete();
        
        return response()->json(['message' => 'Cuadrante eliminado correctamente'], 200);
    }

    
    public function adyacentes($id)
    {
        $cuadrante = Cuadrante::findOrFail($id);
        $adyacentes = $cuadrante->getCuadrantesAdyacentes();
        
        return response()->json($adyacentes);
    }

    public function buscarPorUbicacion(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'lat' => 'required|numeric',
            'lng' => 'required|numeric',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $cuadrante = Cuadrante::where('lat_min', '<=', $request->lat)
            ->where('lat_max', '>=', $request->lat)
            ->where('lng_min', '<=', $request->lng)
            ->where('lng_max', '>=', $request->lng)
            ->first();

        if (!$cuadrante) {
            return response()->json(['message' => 'No se encontró un cuadrante para esta ubicación'], 404);
        }
        
        return response()->json($cuadrante);
    }

    public function estadisticas($id)
    {
        $cuadrante = Cuadrante::findOrFail($id);
        
        $stats = [
            'cuadrante' => $cuadrante,
            'reportes_activos' => $cuadrante->reportesActivos(),
            'reportes_resueltos' => $cuadrante->reportesResueltos(),
            'total_reportes' => $cuadrante->reportes()->count(),
            'grupos_count' => $cuadrante->grupos()->count(),
        ];
        
        return response()->json($stats);
    }
}