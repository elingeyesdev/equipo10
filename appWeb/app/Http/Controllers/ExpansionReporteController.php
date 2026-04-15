<?php
namespace App\Http\Controllers;

use App\Models\ExpansionReporte;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ExpansionReporteController extends Controller
{
    public function index(Request $request)
    {
        $query = ExpansionReporte::with([
            'reporte',
            'cuadranteOriginal',
            'cuadranteExpandido'
        ]);

        if ($request->has('reporte_id')) {
            $query->where('reporte_id', $request->reporte_id);
        }

        if ($request->has('nivel')) {
            $query->where('nivel', $request->nivel);
        }

        $expansiones = $query->orderBy('fecha_expansion', 'desc')->paginate(50);
        
        return response()->json($expansiones);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'reporte_id' => 'required|uuid|exists:reportes,id',
            'cuadrante_original_id' => 'required|uuid|exists:cuadrantes,id',
            'cuadrante_expandido_id' => 'required|uuid|exists:cuadrantes,id',
            'nivel' => 'required|integer|min:1|max:10'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        
        $existe = ExpansionReporte::where('reporte_id', $request->reporte_id)
            ->where('cuadrante_expandido_id', $request->cuadrante_expandido_id)
            ->exists();

        if ($existe) {
            return response()->json(['error' => 'Esta expansión ya existe'], 422);
        }

        $expansion = ExpansionReporte::create($request->all());
        
        return response()->json($expansion->load([
            'reporte',
            'cuadranteOriginal',
            'cuadranteExpandido'
        ]), 201);
    }

    public function show($id)
    {
        $expansion = ExpansionReporte::with([
            'reporte',
            'cuadranteOriginal',
            'cuadranteExpandido'
        ])->findOrFail($id);
        
        return response()->json($expansion);
    }

    public function destroy($id)
    {
        $expansion = ExpansionReporte::findOrFail($id);
        $expansion->delete();
        
        return response()->json(['message' => 'Expansión eliminada correctamente'], 200);
    }

    public function porReporte($reporteId)
    {
        $expansiones = ExpansionReporte::where('reporte_id', $reporteId)
            ->with(['cuadranteOriginal', 'cuadranteExpandido'])
            ->orderBy('nivel', 'asc')
            ->get();
        
        return response()->json($expansiones);
    }
}