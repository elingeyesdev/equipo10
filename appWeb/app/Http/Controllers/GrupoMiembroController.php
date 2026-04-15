<?php
namespace App\Http\Controllers;

use App\Models\GrupoMiembro;
use App\Models\Grupo;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class GrupoMiembroController extends Controller
{
    public function index(Request $request)
    {
        $query = GrupoMiembro::with(['grupo', 'usuario']);

        if ($request->has('grupo_id')) {
            $query->where('grupo_id', $request->grupo_id);
        }

        if ($request->has('usuario_id')) {
            $query->where('usuario_id', $request->usuario_id);
        }

        if ($request->has('rol')) {
            $query->where('rol', $request->rol);
        }

        $miembros = $query->paginate(50);
        
        return response()->json($miembros);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'grupo_id' => 'required|uuid|exists:grupos,id',
            'usuario_id' => 'required|uuid|exists:usuarios,id',
            'rol' => 'sometimes|in:miembro,moderador,admin',
            'notificaciones_activas' => 'sometimes|boolean'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        
        $existe = GrupoMiembro::where('grupo_id', $request->grupo_id)
            ->where('usuario_id', $request->usuario_id)
            ->exists();

        if ($existe) {
            return response()->json(['error' => 'El usuario ya es miembro del grupo'], 422);
        }

        $miembro = GrupoMiembro::create($request->all());

        
        Grupo::find($request->grupo_id)->increment('miembros_count');
        
        return response()->json($miembro->load(['grupo', 'usuario']), 201);
    }

    public function show($id)
    {
        $miembro = GrupoMiembro::with(['grupo', 'usuario'])->findOrFail($id);
        return response()->json($miembro);
    }

    public function update(Request $request, $id)
    {
        $miembro = GrupoMiembro::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'rol' => 'sometimes|in:miembro,moderador,admin',
            'notificaciones_activas' => 'sometimes|boolean'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $miembro->update($request->all());
        
        return response()->json($miembro->load(['grupo', 'usuario']));
    }

    public function destroy($id)
    {
        $miembro = GrupoMiembro::findOrFail($id);
        $grupoId = $miembro->grupo_id;
        $miembro->delete();

        
        Grupo::find($grupoId)->decrement('miembros_count');
        
        return response()->json(['message' => 'Miembro eliminado del grupo'], 200);
    }

    public function cambiarRol(Request $request, $id)
    {
        $miembro = GrupoMiembro::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'rol' => 'required|in:miembro,moderador,admin'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $miembro->update(['rol' => $request->rol]);
        
        return response()->json([
            'message' => 'Rol actualizado correctamente',
            'miembro' => $miembro->load(['grupo', 'usuario'])
        ]);
    }
}
