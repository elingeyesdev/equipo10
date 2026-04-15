<?php
namespace App\Http\Controllers;

use App\Models\Respuesta;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class RespuestaController extends Controller
{
    public function index(Request $request)
    {
        $query = Respuesta::with(['reporte', 'usuario']);

        if ($request->has('reporte_id')) {
            $query->where('reporte_id', $request->reporte_id);
        }

        $respuestas = $query->orderBy('created_at', 'desc')->paginate(20);
        
        return response()->json($respuestas);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'reporte_id' => 'required|uuid|exists:reportes,id',
            'usuario_id' => 'required|uuid|exists:usuarios,id',
            'tipo_respuesta' => 'required|in:avistamiento,encontrado,informacion,pregunta',
            'mensaje' => 'required|string',
            'imagenes' => 'nullable|array',
            'videos' => 'nullable|array'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $respuesta = Respuesta::create($request->all());

        
        $respuesta->reporte->increment('respuestas_count');
        
        return response()->json($respuesta, 201);
    }

    public function show($id)
    {
        $respuesta = Respuesta::with(['reporte', 'usuario'])->findOrFail($id);
        return response()->json($respuesta);
    }

    public function update(Request $request, $id)
    {
        $respuesta = Respuesta::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'mensaje' => 'sometimes|string',
            'verificada' => 'sometimes|boolean',
            'util' => 'sometimes|boolean'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $respuesta->update($request->all());
        
        return response()->json($respuesta);
    }

    public function destroy($id)
    {
        $respuesta = Respuesta::findOrFail($id);
        $respuesta->reporte->decrement('respuestas_count');
        $respuesta->delete();
        
        return response()->json(['message' => 'Respuesta eliminada correctamente'], 200);
    }
}
