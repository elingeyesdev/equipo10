<?php
namespace App\Http\Controllers;

use App\Models\Usuario;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class UsuarioController extends Controller
{
    
    public function index()
    {
        $usuarios = Usuario::with(['reportes', 'grupos'])
            ->paginate(15);
        
        return response()->json($usuarios);
    }

    
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'nombre' => 'required|string|max:100',
            'email' => 'required|email|unique:usuarios,email',
            'telefono' => 'nullable|string|max:20',
            'avatar_url' => 'nullable|url',
            'ubicacion_actual' => 'nullable|json'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $usuario = Usuario::create($request->all());
        
        return response()->json($usuario, 201);
    }

    
    public function show($id)
    {
        $usuario = Usuario::with(['reportes', 'respuestas', 'grupos', 'notificaciones'])
            ->findOrFail($id);
        
        return response()->json($usuario);
    }

    
    public function update(Request $request, $id)
    {
        $usuario = Usuario::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'nombre' => 'sometimes|string|max:100',
            'email' => 'sometimes|email|unique:usuarios,email,' . $id,
            'telefono' => 'nullable|string|max:20',
            'avatar_url' => 'nullable|url',
            'activo' => 'sometimes|boolean'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $usuario->update($request->all());
        
        return response()->json($usuario);
    }

    
    public function destroy($id)
    {
        $usuario = Usuario::findOrFail($id);
        $usuario->delete();
        
        return response()->json(['message' => 'Usuario eliminado correctamente'], 200);
    }
}