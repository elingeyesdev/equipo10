<?php
namespace App\Http\Controllers;

use App\Models\Grupo;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;

class GrupoController extends Controller
{
    
    public function index()
    {
        $grupos = Grupo::with(['cuadrante', 'miembros'])
            ->withCount([
                'miembros',
                'reportes as reportes_activos_count' => function ($query) {
                    $query->where('estado', 'activo');
                },
                'reportes as reportes_resueltos_count' => function ($query) {
                    $query->where('estado', 'resuelto');
                }
            ])
            ->orderBy('created_at', 'desc')
            ->paginate(20);
        
        return view('grupos.index', compact('grupos'));
    }

    
    public function show($id)
    {
        $grupo = Grupo::with([
                'cuadrante',
                'miembros' => function ($query) {
                    $query->orderBy('grupo_miembros.rol', 'desc'); 
                }
            ])
            ->withCount([
                'miembros',
                'reportes as reportes_activos_count' => function ($query) {
                    $query->where('estado', 'activo');
                },
                'reportes as reportes_resueltos_count' => function ($query) {
                    $query->where('estado', 'resuelto');
                }
            ])
            ->findOrFail($id);

        
        $reportes = $grupo->reportes()
            ->with([
                'usuario',
                'categoria',
                'respuestas'
            ])
            ->withCount('respuestas')
            ->orderBy('created_at', 'desc')
            ->paginate(15);

        return view('grupos.show', compact('grupo', 'reportes'));
    }

    
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'cuadrante_id' => 'required|uuid|exists:cuadrantes,id',
            'nombre' => 'required|string|max:200',
            'descripcion' => 'nullable|string',
            'imagen_url' => 'nullable|url',
            'publico' => 'sometimes|boolean',
            'requiere_aprobacion' => 'sometimes|boolean'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $grupo = Grupo::create($request->all());
        
        
        if (Auth::check()) {
            $grupo->miembros()->attach(Auth::id(), [
                'rol' => 'admin',
                'joined_at' => now()
            ]);
            $grupo->increment('miembros_count');
        }
        
        return response()->json($grupo->load('miembros', 'cuadrante'), 201);
    }

    
    public function update(Request $request, $id)
    {
        $grupo = Grupo::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'nombre' => 'sometimes|string|max:200',
            'descripcion' => 'nullable|string',
            'imagen_url' => 'nullable|url',
            'publico' => 'sometimes|boolean',
            'requiere_aprobacion' => 'sometimes|boolean'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $grupo->update($request->all());
        
        return response()->json($grupo->load('miembros', 'cuadrante'));
    }

    
    public function destroy($id)
    {
        $grupo = Grupo::findOrFail($id);
        $grupo->delete();
        
        return response()->json(['message' => 'Grupo eliminado correctamente'], 200);
    }

    
    public function join($id)
    {
        $grupo = Grupo::findOrFail($id);
        
        if (!Auth::check()) {
            return redirect()->route('login');
        }

        $usuario = Auth::user();

        
        if ($grupo->miembros()->where('usuario_id', $usuario->id)->exists()) {
            return redirect()->route('grupos.show', $id)
                ->with('info', 'Ya eres miembro de este grupo');
        }

        
        if ($grupo->requiere_aprobacion) {
            
            return redirect()->route('grupos.show', $id)
                ->with('success', 'Solicitud enviada. Espera la aprobación del administrador.');
        }

        
        $grupo->miembros()->attach($usuario->id, [
            'rol' => 'miembro',
            'joined_at' => now(),
            'notificaciones_activas' => true
        ]);
        
        
        $grupo->increment('miembros_count');

        return redirect()->route('grupos.show', $id)
            ->with('success', 'Te has unido al grupo exitosamente');
    }

    
    public function leave($id)
    {
        $grupo = Grupo::findOrFail($id);
        
        if (!Auth::check()) {
            return redirect()->route('login');
        }

        $usuario = Auth::user();
        
        
        $esAdmin = $grupo->miembros()
            ->where('usuario_id', $usuario->id)
            ->wherePivot('rol', 'admin')
            ->exists();
            
        if ($esAdmin) {
            $cantidadAdmins = $grupo->miembros()
                ->wherePivot('rol', 'admin')
                ->count();
                
            if ($cantidadAdmins <= 1) {
                return redirect()->route('grupos.show', $id)
                    ->with('error', 'No puedes salir siendo el único administrador. Asigna otro admin primero.');
            }
        }
        
        $grupo->miembros()->detach($usuario->id);
        
        
        $grupo->decrement('miembros_count');

        return redirect()->route('grupos.index')
            ->with('success', 'Has salido del grupo');
    }
    
    
    public function updateMemberRole(Request $request, $grupoId, $usuarioId)
    {
        $validator = Validator::make($request->all(), [
            'rol' => 'required|in:miembro,moderador,admin'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $grupo = Grupo::findOrFail($grupoId);
        
        
        if (!Auth::check() || !$grupo->esAdmin(Auth::id())) {
            return response()->json(['error' => 'No tienes permisos para realizar esta acción'], 403);
        }

        
        $grupo->miembros()->updateExistingPivot($usuarioId, [
            'rol' => $request->rol
        ]);

        return response()->json([
            'message' => 'Rol actualizado correctamente',
            'miembro' => $grupo->miembros()->find($usuarioId)
        ]);
    }
    
    
    public function removeMember($grupoId, $usuarioId)
    {
        $grupo = Grupo::findOrFail($grupoId);
        
        
        if (!Auth::check() || !$grupo->esAdmin(Auth::id())) {
            return response()->json(['error' => 'No tienes permisos para realizar esta acción'], 403);
        }

        
        $miembro = $grupo->miembros()->find($usuarioId);
        if ($miembro && $miembro->pivot->rol === 'admin') {
            $cantidadAdmins = $grupo->miembros()
                ->wherePivot('rol', 'admin')
                ->count();
                
            if ($cantidadAdmins <= 1) {
                return response()->json([
                    'error' => 'No se puede remover al único administrador del grupo'
                ], 422);
            }
        }

        $grupo->miembros()->detach($usuarioId);
        $grupo->decrement('miembros_count');

        return response()->json(['message' => 'Miembro removido correctamente']);
    }
}