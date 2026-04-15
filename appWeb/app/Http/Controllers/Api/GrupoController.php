<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Grupo;
use App\Models\GrupoMiembro;
use App\Models\Usuario;
use App\Models\Cuadrante;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class GrupoController extends Controller
{
    /**
     * Crear grupo (desde HTML)
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'cuadrante_id' => 'required|exists:cuadrantes,id',
            'nombre' => 'required|string|max:200',
            'descripcion' => 'nullable|string',
            'imagen_url' => 'nullable|string',
            'publico' => 'boolean',
            'requiere_aprobacion' => 'boolean'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $grupo = Grupo::create($request->all());

            return response()->json([
                'success' => true,
                'message' => 'Grupo creado exitosamente',
                'data' => $grupo
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al crear grupo',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Unir usuario a grupo automáticamente (cambia de grupo si entra a otro cuadrante)
     */
    public function unirUsuarioAutomatico(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'usuario_id' => 'required|exists:usuarios,id',
            'cuadrante_id' => 'required|exists:cuadrantes,id'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            DB::beginTransaction();

            // Buscar grupo del nuevo cuadrante
            $grupoNuevo = Grupo::where('cuadrante_id', $request->cuadrante_id)->first();

            if (!$grupoNuevo) {
                return response()->json([
                    'success' => false,
                    'message' => 'No existe grupo para este cuadrante'
                ], 404);
            }

            // Verificar si el usuario ya está en este grupo
            $miembroExistente = GrupoMiembro::where('grupo_id', $grupoNuevo->id)
                ->where('usuario_id', $request->usuario_id)
                ->first();

            if ($miembroExistente) {
                DB::commit();
                return response()->json([
                    'success' => true,
                    'message' => 'El usuario ya es miembro de este grupo',
                    'data' => [
                        'grupo' => $grupoNuevo,
                        'miembro' => $miembroExistente,
                        'cambio_grupo' => false
                    ]
                ], 200);
            }

            // CRÍTICO: Salir de TODOS los grupos anteriores
            $gruposAnteriores = GrupoMiembro::where('usuario_id', $request->usuario_id)->get();
            
            $grupoAnteriorInfo = null;
            if ($gruposAnteriores->isNotEmpty()) {
                // Guardar info del grupo anterior para el mensaje
                $grupoAnteriorInfo = $gruposAnteriores->first()->grupo;
                
                // Eliminar de todos los grupos
                GrupoMiembro::where('usuario_id', $request->usuario_id)->delete();
            }

            // Unir al nuevo grupo
            $miembro = GrupoMiembro::create([
                'grupo_id' => $grupoNuevo->id,
                'usuario_id' => $request->usuario_id,
                'rol' => 'miembro',
                'notificaciones_activas' => true,
                'joined_at' => now()
            ]);

            DB::commit();

            $mensaje = $grupoAnteriorInfo 
                ? "Usuario cambió del grupo '{$grupoAnteriorInfo->nombre}' al grupo '{$grupoNuevo->nombre}'"
                : "Usuario unido al grupo '{$grupoNuevo->nombre}' exitosamente";

            return response()->json([
                'success' => true,
                'message' => $mensaje,
                'data' => [
                    'grupo_nuevo' => $grupoNuevo,
                    'grupo_anterior' => $grupoAnteriorInfo,
                    'miembro' => $miembro,
                    'cambio_grupo' => $grupoAnteriorInfo !== null
                ]
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al unir usuario al grupo',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtener grupos del usuario
     */
    public function gruposDelUsuario($usuarioId)
    {
        try {
            $usuario = Usuario::findOrFail($usuarioId);

            // No usar withTimestamps() ya que la tabla no tiene created_at/updated_at
            $grupos = $usuario->grupos()
                ->with(['cuadrante'])
                ->get();

            return response()->json([
                'success' => true,
                'data' => $grupos
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener grupos del usuario',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtener miembros de un grupo
     */
    public function miembrosDelGrupo($grupoId)
    {
        try {
            $grupo = Grupo::findOrFail($grupoId);

            $miembros = $grupo->usuarios()
                ->select('usuarios.*', 'grupo_miembros.rol', 'grupo_miembros.joined_at')
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'grupo' => $grupo,
                    'miembros' => $miembros,
                    'total_miembros' => $miembros->count()
                ]
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener miembros del grupo',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtener grupos de cuadrantes específicos
     */
    public function gruposPorCuadrantes(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'cuadrante_ids' => 'required|array',
            'cuadrante_ids.*' => 'exists:cuadrantes,id'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $grupos = Grupo::whereIn('cuadrante_id', $request->cuadrante_ids)
                ->with(['cuadrante', 'miembros'])
                ->get();

            return response()->json([
                'success' => true,
                'data' => $grupos
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al obtener grupos',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Verificar y actualizar grupo del usuario según ubicación actual
     */
    public function verificarCambioGrupo(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'usuario_id' => 'required|exists:usuarios,id',
            'lat' => 'required|numeric|between:-90,90',
            'lng' => 'required|numeric|between:-180,180'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            DB::beginTransaction();

            $lat = $request->lat;
            $lng = $request->lng;

            // Detectar cuadrante actual según ubicación
            $cuadranteActual = Cuadrante::where('activo', true)
                ->where('lat_min', '<=', $lat)
                ->where('lat_max', '>=', $lat)
                ->where('lng_min', '<=', $lng)
                ->where('lng_max', '>=', $lng)
                ->first();

            if (!$cuadranteActual) {
                DB::rollBack();
                return response()->json([
                    'success' => false,
                    'message' => 'No se encontró un cuadrante para esta ubicación'
                ], 404);
            }

            // Obtener grupo actual del usuario
            $miembroActual = GrupoMiembro::where('usuario_id', $request->usuario_id)
                ->with('grupo.cuadrante')
                ->first();

            // Si no está en ningún grupo, unirlo al grupo del cuadrante actual
            if (!$miembroActual) {
                $grupoNuevo = Grupo::where('cuadrante_id', $cuadranteActual->id)->first();
                
                if (!$grupoNuevo) {
                    DB::rollBack();
                    return response()->json([
                        'success' => false,
                        'message' => 'No existe grupo para este cuadrante'
                    ], 404);
                }

                $miembro = GrupoMiembro::create([
                    'grupo_id' => $grupoNuevo->id,
                    'usuario_id' => $request->usuario_id,
                    'rol' => 'miembro',
                    'notificaciones_activas' => true,
                    'joined_at' => now()
                ]);

                DB::commit();

                return response()->json([
                    'success' => true,
                    'message' => 'Usuario unido al grupo',
                    'data' => [
                        'cuadrante_actual' => $cuadranteActual,
                        'grupo_actual' => $grupoNuevo,
                        'cambio_detectado' => false,
                        'primer_ingreso' => true
                    ]
                ], 200);
            }

            // Verificar si el cuadrante cambió
            $cuadranteAnterior = $miembroActual->grupo->cuadrante;

            if ($cuadranteAnterior->id === $cuadranteActual->id) {
                // Usuario sigue en el mismo cuadrante
                DB::commit();
                return response()->json([
                    'success' => true,
                    'message' => 'Usuario permanece en el mismo grupo',
                    'data' => [
                        'cuadrante_actual' => $cuadranteActual,
                        'grupo_actual' => $miembroActual->grupo,
                        'cambio_detectado' => false,
                        'primer_ingreso' => false
                    ]
                ], 200);
            }

            // Usuario cambió de cuadrante - cambiar de grupo
            $grupoNuevo = Grupo::where('cuadrante_id', $cuadranteActual->id)->first();

            if (!$grupoNuevo) {
                DB::rollBack();
                return response()->json([
                    'success' => false,
                    'message' => 'No existe grupo para el nuevo cuadrante'
                ], 404);
            }

            // Salir del grupo anterior
            GrupoMiembro::where('usuario_id', $request->usuario_id)->delete();

            // Unir al nuevo grupo
            $miembroNuevo = GrupoMiembro::create([
                'grupo_id' => $grupoNuevo->id,
                'usuario_id' => $request->usuario_id,
                'rol' => 'miembro',
                'notificaciones_activas' => true,
                'joined_at' => now()
            ]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => "Usuario cambió del cuadrante {$cuadranteAnterior->codigo} al cuadrante {$cuadranteActual->codigo}",
                'data' => [
                    'cuadrante_anterior' => $cuadranteAnterior,
                    'cuadrante_actual' => $cuadranteActual,
                    'grupo_anterior' => $miembroActual->grupo,
                    'grupo_actual' => $grupoNuevo,
                    'cambio_detectado' => true,
                    'primer_ingreso' => false
                ]
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Error al verificar cambio de grupo',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Salir de un grupo
     */
    public function salirDelGrupo(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'usuario_id' => 'required|exists:usuarios,id',
            'grupo_id' => 'required|exists:grupos,id'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $miembro = GrupoMiembro::where('grupo_id', $request->grupo_id)
                ->where('usuario_id', $request->usuario_id)
                ->first();

            if (!$miembro) {
                return response()->json([
                    'success' => false,
                    'message' => 'El usuario no es miembro de este grupo'
                ], 404);
            }

            $miembro->delete();

            return response()->json([
                'success' => true,
                'message' => 'Usuario salió del grupo exitosamente'
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al salir del grupo',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Listar todos los grupos
     */
    public function index()
    {
        try {
            $grupos = Grupo::with(['cuadrante'])
                ->withCount('miembros')
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => $grupos
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error al listar grupos',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Obtener un grupo específico
     */
    public function show($id)
    {
        try {
            $grupo = Grupo::with(['cuadrante', 'miembros'])
                ->withCount('miembros')
                ->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => $grupo
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Grupo no encontrado',
                'error' => $e->getMessage()
            ], 404);
        }
    }
}

