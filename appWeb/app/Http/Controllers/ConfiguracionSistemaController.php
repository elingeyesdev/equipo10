<?php
namespace App\Http\Controllers;

use App\Models\ConfiguracionSistema;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ConfiguracionSistemaController extends Controller
{
    public function index()
    {
        $configuraciones = ConfiguracionSistema::orderBy('clave')->get();
        return response()->json($configuraciones);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'clave' => 'required|string|max:100|unique:configuracion_sistema,clave',
            'valor' => 'required|string',
            'descripcion' => 'nullable|string',
            'tipo' => 'required|in:string,number,boolean,json'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $config = ConfiguracionSistema::create($request->all());
        
        return response()->json($config, 201);
    }

    public function show($clave)
    {
        $config = ConfiguracionSistema::findOrFail($clave);
        return response()->json($config);
    }

    public function update(Request $request, $clave)
    {
        $config = ConfiguracionSistema::findOrFail($clave);

        $validator = Validator::make($request->all(), [
            'valor' => 'sometimes|string',
            'descripcion' => 'nullable|string',
            'tipo' => 'sometimes|in:string,number,boolean,json'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $config->update($request->all());
        
        return response()->json($config);
    }

    public function destroy($clave)
    {
        $config = ConfiguracionSistema::findOrFail($clave);
        $config->delete();
        
        return response()->json(['message' => 'Configuración eliminada correctamente'], 200);
    }

    public function porClave($clave)
    {
        $config = ConfiguracionSistema::where('clave', $clave)->firstOrFail();
        
        return response()->json([
            'clave' => $config->clave,
            'valor' => $config->valor, 
            'tipo' => $config->tipo
        ]);
    }
}