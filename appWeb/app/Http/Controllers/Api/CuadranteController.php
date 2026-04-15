<?php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Cuadrante;
use App\Models\CuadranteBarrio;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class CuadranteController extends Controller
{
    /**
     * Crear cuadrante (desde HTML)
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'codigo' => 'required|string|max:20|unique:cuadrantes',
            'fila' => 'required|string|max:5',
            'columna' => 'required|integer',
            'nombre' => 'required|string|max:100',
            'lat_min' => 'required|numeric',
            'lat_max' => 'required|numeric',
            'lng_min' => 'required|numeric',
            'lng_max' => 'required|numeric',
            'centro_lat' => 'required|numeric',
            'centro_lng' => 'required|numeric',
            'ciudad' => 'required|string|max:100',
            'zona' => 'nullable|string|max:100',
            'activo' => 'boolean'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $cuadrante = Cuadrante::create($request->all());

            return response()->json([
                'success' => true,
                'message' => 'Cuadrante creado exitosamente',
                'data' => $cuadrante
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al crear cuadrante',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Agregar barrio a un cuadrante
     */
    public function agregarBarrio(Request $request, $cuadranteId)
    {
        $validator = Validator::make($request->all(), [
            'nombre_barrio' => 'required|string|max:200'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $cuadrante = Cuadrante::findOrFail($cuadranteId);

            $barrio = CuadranteBarrio::create([
                'cuadrante_id' => $cuadranteId,
                'nombre_barrio' => $request->nombre_barrio
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Barrio agregado exitosamente',
                'data' => $barrio
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al agregar barrio',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Detectar cuadrante según ubicación
     */
    public function detectarCuadrante(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $lat = $request->lat;
            $lng = $request->lng;

            $cuadrante = Cuadrante::where('activo', true)
                ->where('lat_min', '<=', $lat)
                ->where('lat_max', '>=', $lat)
                ->where('lng_min', '<=', $lng)
                ->where('lng_max', '>=', $lng)
                ->with(['barrios', 'grupos'])
                ->first();

            if (!$cuadrante) {
                return response()->json([
                    'success' => false,
                    'message' => 'No se encontró un cuadrante para esta ubicación'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $cuadrante
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al detectar cuadrante',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtener 25 cuadrantes cercanos a una ubicación
     */
    public function cuadrantesCercanos(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $lat = $request->lat;
            $lng = $request->lng;

            // Usar fórmula de Haversine para calcular distancia
            $cuadrantes = Cuadrante::select('*')
                ->selectRaw(
                    '(6371 * acos(cos(radians(?)) * cos(radians(centro_lat)) * cos(radians(centro_lng) - radians(?)) + sin(radians(?)) * sin(radians(centro_lat)))) AS distancia',
                    [$lat, $lng, $lat]
                )
                ->where('activo', true)
                ->orderBy('distancia')
                ->limit(25)
                ->with(['grupos', 'barrios'])
                ->get();

            return response()->json([
                'success' => true,
                'data' => $cuadrantes
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener cuadrantes cercanos',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtener 8 cuadrantes adyacentes para expansión
     */
    public function cuadrantesAdyacentes($cuadranteId)
    {
        try {
            $cuadrante = Cuadrante::findOrFail($cuadranteId);

            $fila = $cuadrante->fila;
            $columna = $cuadrante->columna;

            // Calcular filas y columnas adyacentes
            $filaAnterior = chr(ord($fila) - 1);
            $filaSiguiente = chr(ord($fila) + 1);
            $columnaAnterior = $columna - 1;
            $columnaSiguiente = $columna + 1;

            // Buscar los 8 cuadrantes adyacentes
            $adyacentes = Cuadrante::where('activo', true)
                ->where(function($query) use ($fila, $filaAnterior, $filaSiguiente, $columna, $columnaAnterior, $columnaSiguiente) {
                    // Arriba izquierda
                    $query->orWhere(function($q) use ($filaAnterior, $columnaAnterior) {
                        $q->where('fila', $filaAnterior)->where('columna', $columnaAnterior);
                    })
                    // Arriba
                    ->orWhere(function($q) use ($filaAnterior, $columna) {
                        $q->where('fila', $filaAnterior)->where('columna', $columna);
                    })
                    // Arriba derecha
                    ->orWhere(function($q) use ($filaAnterior, $columnaSiguiente) {
                        $q->where('fila', $filaAnterior)->where('columna', $columnaSiguiente);
                    })
                    // Izquierda
                    ->orWhere(function($q) use ($fila, $columnaAnterior) {
                        $q->where('fila', $fila)->where('columna', $columnaAnterior);
                    })
                    // Derecha
                    ->orWhere(function($q) use ($fila, $columnaSiguiente) {
                        $q->where('fila', $fila)->where('columna', $columnaSiguiente);
                    })
                    // Abajo izquierda
                    ->orWhere(function($q) use ($filaSiguiente, $columnaAnterior) {
                        $q->where('fila', $filaSiguiente)->where('columna', $columnaAnterior);
                    })
                    // Abajo
                    ->orWhere(function($q) use ($filaSiguiente, $columna) {
                        $q->where('fila', $filaSiguiente)->where('columna', $columna);
                    })
                    // Abajo derecha
                    ->orWhere(function($q) use ($filaSiguiente, $columnaSiguiente) {
                        $q->where('fila', $filaSiguiente)->where('columna', $columnaSiguiente);
                    });
                })
                ->with('grupos')
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'cuadrante_origen' => $cuadrante,
                    'cuadrantes_adyacentes' => $adyacentes,
                    'total' => $adyacentes->count()
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener cuadrantes adyacentes',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Listar todos los cuadrantes
     */
    public function index()
    {
        try {
            $cuadrantes = Cuadrante::with(['barrios', 'grupos'])
                ->where('activo', true)
                ->orderBy('fila')
                ->orderBy('columna')
                ->get();

            return response()->json([
                'success' => true,
                'data' => $cuadrantes
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al listar cuadrantes',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtener un cuadrante específico
     */
    public function show($id)
    {
        try {
            $cuadrante = Cuadrante::with(['barrios', 'grupos'])->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => $cuadrante
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Cuadrante no encontrado',
                'error' => $e->getMessage()
            ], 404);
        }
    }
}

