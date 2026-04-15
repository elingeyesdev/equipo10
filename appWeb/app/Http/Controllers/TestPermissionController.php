<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class TestPermissionController extends Controller
{
    
    public function test()
    {
        $user = auth()->user();
        
        if (!$user) {
            return redirect()->route('login')->with('error', 'Debes estar autenticado para ver esta página');
        }

        
        $userRoles = $user->getRoleNames();
        $userPermissions = $user->getAllPermissions()->pluck('name');

        
        $checks = [
            'Tiene rol administrador' => $user->hasRole('administrador'),
            'Tiene rol editor' => $user->hasRole('editor'),
            'Tiene rol usuario' => $user->hasRole('usuario'),
            'Puede ver usuarios' => $user->can('ver usuarios'),
            'Puede crear reportes' => $user->can('crear reportes'),
            'Puede administrar sistema' => $user->can('administrar sistema'),
        ];

        
        $allRoles = Role::all();
        $allPermissions = Permission::all();

        return view('test-permission', compact(
            'user',
            'userRoles',
            'userPermissions',
            'checks',
            'allRoles',
            'allPermissions'
        ));
    }

    
    public function adminOnly()
    {
        return response()->json([
            'message' => 'Esta es una ruta solo para administradores',
            'user' => auth()->user()->name,
            'roles' => auth()->user()->getRoleNames(),
        ]);
    }

    
    public function editorOnly()
    {
        return response()->json([
            'message' => 'Esta es una ruta solo para editores',
            'user' => auth()->user()->name,
            'roles' => auth()->user()->getRoleNames(),
        ]);
    }
}
