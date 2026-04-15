<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Usuario;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class ApiAuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'nombre' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:usuarios',
            'password' => 'required|string|min:6', // app sends password
        ]);

        $usuario = Usuario::create([
            'nombre' => $request->nombre,
            'email' => $request->email,
            'contrasena' => Hash::make($request->password),
            'rol' => 'editor',
            'activo' => true
        ]);

        // Asegurar que Spatie use el guard correcto
        $usuario->guard_name = 'web'; 
        $usuario->assignRole('administrador');

        return response()->json([
            'success' => true,
            'message' => 'Usuario registrado correctamente',
            'data' => [
                'usuario' => $usuario,
                // 'token' => $usuario->createToken('auth_token')->plainTextToken // If using Sanctum
            ]
        ], 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $usuario = Usuario::where('email', $request->email)->first();

        if (! $usuario || ! Hash::check($request->password, $usuario->contrasena)) {
            return response()->json([
                'success' => false,
                'message' => 'Credenciales incorrectas'
            ], 401);
        }

        return response()->json([
            'success' => true,
            'message' => 'Login exitoso',
            'data' => [
                'usuario' => $usuario,
                // 'token' => $usuario->createToken('auth_token')->plainTextToken
            ]
        ]);
    }

    public function perfil($usuarioId)
    {
        $usuario = Usuario::find($usuarioId);
        
        if (!$usuario) {
            return response()->json(['success' => false, 'message' => 'Usuario no encontrado'], 404);
        }

        return response()->json(['success' => true, 'data' => $usuario]);
    }

    public function actualizarPerfil(Request $request, $usuarioId)
    {
        $usuario = Usuario::find($usuarioId);
        
        if (!$usuario) {
            return response()->json(['success' => false, 'message' => 'Usuario no encontrado'], 404);
        }

        $usuario->update($request->all());

        return response()->json(['success' => true, 'message' => 'Perfil actualizado', 'data' => $usuario]);
    }

    public function actualizarUbicacion(Request $request, $usuarioId)
    {
        $usuario = Usuario::find($usuarioId);
        
        if (!$usuario) {
            return response()->json(['success' => false, 'message' => 'Usuario no encontrado'], 404);
        }

        $request->validate([
            'lat' => 'required|numeric',
            'lng' => 'required|numeric',
        ]);

        $usuario->update([
            'ubicacion_actual_lat' => $request->lat,
            'ubicacion_actual_lng' => $request->lng
        ]);

        return response()->json(['success' => true, 'message' => 'Ubicación actualizada']);
    }

    public function actualizarNotificaciones(Request $request, $usuarioId)
    {
        // Placeholder implementation
        return response()->json(['success' => true, 'message' => 'Configuración actualizada']);
    }
}
