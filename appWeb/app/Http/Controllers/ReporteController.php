<?php
namespace App\Http\Controllers;

use App\Models\Reporte;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ReporteController extends Controller
{
    public function index(Request $request)
    {
        $query = Reporte::with(['usuario', 'categoria', 'cuadrante', 'respuestas']);

        
        if ($request->has('tipo_reporte')) {
            $query->where('tipo_reporte', $request->tipo_reporte);
        }
        
        if ($request->has('estado')) {
            $query->where('estado', $request->estado);
        }
        
        if ($request->has('categoria_id')) {
            $query->where('categoria_id', $request->categoria_id);
        }
        
        if ($request->has('cuadrante_id')) {
            $query->where('cuadrante_id', $request->cuadrante_id);
        }

        $reportes = $query->orderBy('created_at', 'desc')->paginate(20);
        
        return response()->json($reportes);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'usuario_id' => 'required|uuid|exists:usuarios,id',
            'categoria_id' => 'required|uuid|exists:categorias,id',
            'cuadrante_id' => 'required|uuid|exists:cuadrantes,id',
            'tipo_reporte' => 'required|in:perdido,encontrado',
            'titulo' => 'required|string|max:200',
            'descripcion' => 'required|string',
            'fecha_perdida' => 'nullable|date',
            'imagenes' => 'nullable|array',
            'videos' => 'nullable|array',
            'recompensa' => 'nullable|numeric|min:0'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $reporte = Reporte::create($request->all());
        
        return response()->json($reporte, 201);
    }

    public function show($id)
    {
        $reporte = Reporte::with([
            'respuestas.usuario',
            'expansiones',
            'imagenes'
        ])->findOrFail($id);

        
        $reporte->increment('vistas');
        
        return response()->json($reporte);
    }

    public function update(Request $request, $id)
    {
        $reporte = Reporte::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'titulo' => 'sometimes|string|max:200',
            'descripcion' => 'sometimes|string',
            'estado' => 'sometimes|in:activo,resuelto,inactivo,spam',
            'prioridad' => 'sometimes|in:baja,normal,alta,urgente'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $reporte->update($request->all());
        
        return response()->json($reporte);
    }

    public function destroy($id)
    {
        $reporte = Reporte::findOrFail($id);
        $reporte->delete();
        
        return response()->json(['message' => 'Reporte eliminado correctamente'], 200);
    }
}