<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Usuario;
use App\Models\ConfiguracionNotificacionesUsuario;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    /**
     * Registro de nuevo usuario
     */
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'nombre' => 'required|string|max:100',
            'email' => 'required|string|email|max:255|unique:usuarios',
            'contrasena' => 'required|string|min:6',
            'telefono' => 'nullable|string|max:20'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $usuario = Usuario::create([
                'nombre' => $request->nombre,
                'email' => $request->email,
                'contrasena' => Hash::make($request->contrasena),
                'telefono' => $request->telefono,
                'puntos_ayuda' => 0,
                'activo' => true,
                'rol' => 'cliente'
            ]);

            // Crear configuración de notificaciones por defecto
            // ConfiguracionNotificacionesUsuario::create([
            //     'usuario_id' => $usuario->id,
            //     'push_activo' => true,
            //     'email_activo' => true,
            //     'sms_activo' => false
            // ]);

            // Generar token Sanctum
            $token = $usuario->createToken('auth_token')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => 'Usuario registrado exitosamente',
                'data' => [
                    'usuario' => $usuario,
                    'token' => $token
                ]
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al registrar usuario',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Login de usuario
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'contrasena' => 'required|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $usuario = Usuario::where('email', $request->email)->first();

            if (!$usuario || !Hash::check($request->contrasena, $usuario->contrasena)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Credenciales incorrectas'
                ], 401);
            }

            if (!$usuario->activo) {
                return response()->json([
                    'success' => false,
                    'message' => 'Usuario inactivo'
                ], 403);
            }

            // Generar token Sanctum
            $token = $usuario->createToken('auth_token')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => 'Login exitoso',
                'data' => [
                    'usuario' => $usuario,
                    'token' => $token
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al iniciar sesión',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Actualizar ubicación del usuario
     */
    public function actualizarUbicacion(Request $request, $usuarioId)
    {
        $validator = Validator::make($request->all(), [
            'ubicacion_actual_lat' => 'required|numeric|between:-90,90',
            'ubicacion_actual_lng' => 'required|numeric|between:-180,180'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $usuario = Usuario::findOrFail($usuarioId);

            $usuario->update([
                'ubicacion_actual_lat' => $request->ubicacion_actual_lat,
                'ubicacion_actual_lng' => $request->ubicacion_actual_lng
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Ubicación actualizada',
                'data' => $usuario
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al actualizar ubicación',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtener perfil del usuario
     */
    public function perfil($usuarioId)
    {
        try {
            $usuario = Usuario::with('configuracionNotificaciones')->findOrFail($usuarioId);

            return response()->json([
                'success' => true,
                'data' => $usuario
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Usuario no encontrado',
                'error' => $e->getMessage()
            ], 404);
        }
    }

    /**
     * Actualizar perfil
     */
    public function actualizarPerfil(Request $request, $usuarioId)
    {
        $validator = Validator::make($request->all(), [
            'nombre' => 'sometimes|string|max:100',
            'telefono' => 'sometimes|string|max:20',
            'avatar_url' => 'sometimes|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $usuario = Usuario::findOrFail($usuarioId);
            $usuario->update($request->only(['nombre', 'telefono', 'avatar_url']));

            return response()->json([
                'success' => true,
                'message' => 'Perfil actualizado',
                'data' => $usuario
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al actualizar perfil',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Actualizar configuración de notificaciones
     */
    public function actualizarNotificaciones(Request $request, $usuarioId)
    {
        $validator = Validator::make($request->all(), [
            'push_activo' => 'sometimes|boolean',
            'email_activo' => 'sometimes|boolean',
            'sms_activo' => 'sometimes|boolean'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $config = ConfiguracionNotificacionesUsuario::where('usuario_id', $usuarioId)->first();

            if (!$config) {
                $config = ConfiguracionNotificacionesUsuario::create([
                    'usuario_id' => $usuarioId,
                    'push_activo' => $request->push_activo ?? true,
                    'email_activo' => $request->email_activo ?? true,
                    'sms_activo' => $request->sms_activo ?? false
                ]);
            } else {
                $config->update($request->only(['push_activo', 'email_activo', 'sms_activo']));
            }

            return response()->json([
                'success' => true,
                'message' => 'Configuración actualizada',
                'data' => $config
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al actualizar configuración',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}

