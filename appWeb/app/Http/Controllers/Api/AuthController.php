<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Usuario;
use App\Models\ConfiguracionNotificacionesUsuario;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use App\Models\ImagenAlmacenada;

class AuthController extends Controller
{
    /**
     * Registro de nuevo usuario
     */
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'nombre' => 'required|string|max:100',
            'email' => 'required|string|email|max:255',
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
            // Verificar si ya existe un usuario con ese correo
            $usuarioExistente = Usuario::where('email', $request->email)->first();

            if ($usuarioExistente) {
                // Si ya tiene contraseña configurada, es un registro duplicado real
                if ($usuarioExistente->contrasena_set) {
                    return response()->json([
                        'success' => false,
                        'errors' => [
                            'email' => ['Este correo ya está registrado. Intenta iniciar sesión.']
                        ]
                    ], 422);
                }

                // Si NO tiene contraseña (fue creado por admin), completamos su cuenta
                $usuarioExistente->contrasena = Hash::make($request->contrasena);
                $usuarioExistente->contrasena_set = true;
                $usuarioExistente->nombre = $request->nombre;
                if ($request->telefono) {
                    $usuarioExistente->telefono = $request->telefono;
                }
                $usuarioExistente->activo = true;
                $usuarioExistente->save();

                $token = $usuarioExistente->createToken('auth_token')->plainTextToken;

                return response()->json([
                    'success' => true,
                    'message' => 'Cuenta completada exitosamente. ¡Bienvenido!',
                    'data' => [
                        'usuario' => $usuarioExistente,
                        'token' => $token
                    ]
                ], 201);
            }

            // Usuario completamente nuevo → flujo normal
            $usuario = Usuario::create([
                'nombre' => $request->nombre,
                'email' => $request->email,
                'contrasena' => Hash::make($request->contrasena),
                'contrasena_set' => true,
                'telefono' => $request->telefono,
                'puntos_ayuda' => 0,
                'activo' => true,
                'rol' => 'cliente'
            ]);

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

            // Calcular estadísticas
            $operativosParticipados = \App\Models\ReporteVoluntario::where('usuario_id', $usuarioId)->count();
            $reportesCreados = \App\Models\Reporte::where('usuario_id', $usuarioId)->count();
            
            // Casos resueltos: donde el reporte fue creado por este usuario y está resuelto
            // o el usuario participó en un reporte que ahora está resuelto.
            $casosExitosos = \App\Models\Reporte::where('estado', 'resuelto')
                ->where(function($q) use ($usuarioId) {
                    $q->where('usuario_id', $usuarioId)
                      ->orWhereIn('id', function($subquery) use ($usuarioId) {
                          $subquery->select('reporte_id')
                                   ->from('reporte_voluntarios')
                                   ->where('usuario_id', $usuarioId);
                      });
                })->count();

            // Formar respuesta con el usuario y las estadísticas añadidas artificialmente
            $datosRespuesta = $usuario->toArray();
            $datosRespuesta['estadisticas'] = [
                'operativos_participados' => $operativosParticipados,
                'reportes_creados' => $reportesCreados,
                'casos_exitosos' => $casosExitosos,
                'puntos_ayuda' => $usuario->puntos_ayuda
            ];

            return response()->json([
                'success' => true,
                'data' => $datosRespuesta
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
     * Actualizar contraseña
     */
    public function actualizarContrasena(Request $request, $usuarioId)
    {
        $validator = Validator::make($request->all(), [
            'contrasena_actual' => 'required|string',
            'nueva_contrasena' => 'required|string|min:6'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $usuario = Usuario::findOrFail($usuarioId);

            if (!Hash::check($request->contrasena_actual, $usuario->contrasena)) {
                return response()->json([
                    'success' => false,
                    'message' => 'La contraseña actual es incorrecta'
                ], 401);
            }

            $usuario->update([
                'contrasena' => Hash::make($request->nueva_contrasena)
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Contraseña actualizada correctamente'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al actualizar contraseña',
                'error' => $e->getMessage()
            ], 500);
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
            'avatar_url' => 'sometimes|string',
            'habilidades' => 'sometimes|array',
            'habilidades.*' => 'string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $usuario = Usuario::findOrFail($usuarioId);
            $usuario->update($request->only(['nombre', 'telefono', 'avatar_url', 'habilidades']));

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

    /**
     * Subir avatar directamente para el usuario
     */
    public function subirAvatarDirecto(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|exists:usuarios,id',
            'avatar' => 'required|image|max:5120', // Max 5MB
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $usuario = Usuario::findOrFail($request->id);
            $file = $request->file('avatar');
            $mimeType = $file->getMimeType();
            $base64 = base64_encode(file_get_contents($file->getRealPath()));

            $imagen = ImagenAlmacenada::create([
                'mime_type' => $mimeType,
                'base64_data' => $base64,
            ]);

            $avatarUrl = url('/api/img/' . $imagen->id);
            $usuario->avatar_url = $avatarUrl;
            $usuario->save();

            return response()->json([
                'success' => true,
                'message' => 'Avatar actualizado correctamente',
                'avatar_url' => $avatarUrl
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al procesar el avatar',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Eliminar cuenta del usuario
     */
    public function eliminarCuenta($usuarioId)
    {
        try {
            $usuario = Usuario::findOrFail($usuarioId);
            
            // Eliminar tokens de acceso (Sanctum) si existen
            if (method_exists($usuario, 'tokens')) {
                $usuario->tokens()->delete();
            }

            // Eliminar cuenta
            $usuario->delete();

            return response()->json([
                'success' => true,
                'message' => 'Cuenta eliminada exitosamente'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al eliminar cuenta',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}

