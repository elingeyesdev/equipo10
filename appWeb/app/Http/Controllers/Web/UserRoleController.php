<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Usuario;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Role;

class UserRoleController extends Controller
{
  
    public function index()
    {
        
        $usersWeb = User::all()->map(function ($user) {
            
            $userRoles = DB::table('model_has_roles')
                ->join('roles', 'model_has_roles.role_id', '=', 'roles.id')
                ->where('model_has_roles.model_id', (string) $user->id)
                ->where('model_has_roles.model_type', get_class($user))
                ->select('roles.*')
                ->get()
                ->map(function ($role) {
                    return Role::find($role->id);
                });
            
            return [
                'id' => (string) $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'type' => 'web',
                'roles' => $userRoles,
                'model' => $user
            ];
        });
        
        
        $usersApp = Usuario::with('roles')->get()->map(function ($usuario) {
            return [
                'id' => (string) $usuario->id,
                'name' => $usuario->nombre,
                'email' => $usuario->email,
                'type' => 'app',
                'roles' => $usuario->roles,
                'model' => $usuario
            ];
        });
        
        
        $allUsers = $usersWeb->concat($usersApp)->sortBy('name')->values();
        
        $roles = Role::all();
        
        return view('users.roles.index', compact('allUsers', 'roles'));
    }

    
    public function edit(Request $request, $id)
    {
        $type = $request->query('type', 'web'); 
        
        if ($type === 'app') {
            $user = Usuario::with('roles')->findOrFail($id);
            $user->display_name = $user->nombre;
        } else {
            $user = User::findOrFail($id);
            
            $userRoles = DB::table('model_has_roles')
                ->join('roles', 'model_has_roles.role_id', '=', 'roles.id')
                ->where('model_has_roles.model_id', (string) $user->id)
                ->where('model_has_roles.model_type', get_class($user))
                ->select('roles.*')
                ->get()
                ->map(function ($role) {
                    return Role::find($role->id);
                });
            $user->setRelation('roles', $userRoles);
            $user->display_name = $user->name;
        }
        
        $user->type = $type;
        $roles = Role::all();
        
        return view('users.roles.edit', compact('user', 'roles'));
    }

    
    public function update(Request $request, $id)
    {
        $type = $request->input('type', 'web'); 
        
        if ($type === 'app') {
            $user = Usuario::findOrFail($id);
            $displayName = $user->nombre;
        } else {
            $user = User::findOrFail($id);
            $displayName = $user->name;
        }
        
        $request->validate([
            'roles' => 'nullable|array',
            'roles.*' => 'exists:roles,name'
        ]);

        
        $user->syncRoles($request->roles ?? []);

        return redirect()->route('users.roles.index')
            ->with('success', "Roles actualizados correctamente para {$displayName}");
    }

    
    public function assignRole(Request $request, $id)
    {
        $type = $request->input('type', 'web');
        $user = $type === 'app' ? Usuario::findOrFail($id) : User::findOrFail($id);
        
        $request->validate([
            'role' => 'required|exists:roles,name'
        ]);

        if (!$user->hasRole($request->role)) {
            $user->assignRole($request->role);
            
            return response()->json([
                'success' => true,
                'message' => "Rol '{$request->role}' asignado correctamente"
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => "El usuario ya tiene el rol '{$request->role}'"
        ], 422);
    }

    
    public function removeRole(Request $request, $id)
    {
        $type = $request->input('type', 'web');
        $user = $type === 'app' ? Usuario::findOrFail($id) : User::findOrFail($id);
        
        $request->validate([
            'role' => 'required|exists:roles,name'
        ]);

        if ($user->hasRole($request->role)) {
            
            if ($request->role === 'administrador') {
                $adminCountWeb = User::role('administrador')->count();
                $adminCountApp = Usuario::role('administrador')->count();
                $totalAdmins = $adminCountWeb + $adminCountApp;
                
                if ($totalAdmins <= 1 && $user->hasRole('administrador')) {
                    return response()->json([
                        'success' => false,
                        'message' => 'No se puede remover el último administrador del sistema'
                    ], 422);
                }
            }

            $user->removeRole($request->role);
            
            return response()->json([
                'success' => true,
                'message' => "Rol '{$request->role}' removido correctamente"
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => "El usuario no tiene el rol '{$request->role}'"
        ], 422);
    }
}

