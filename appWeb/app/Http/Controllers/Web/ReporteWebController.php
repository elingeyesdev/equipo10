<?php




namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Reporte;
use App\Models\Usuario;
use App\Models\Categoria;
use App\Models\Cuadrante;
use App\Services\FcmService;
use Illuminate\Http\Request;

class ReporteWebController extends Controller
{
    protected $fcmService;

    public function __construct(FcmService $fcmService)
    {
        $this->fcmService = $fcmService;
    }

    public function index(Request $request)
    {
        $query = Reporte::with(['usuario', 'categoria', 'cuadrante']);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('titulo', 'like', "%{$search}%")
                  ->orWhere('descripcion', 'like', "%{$search}%");
            });
        }

        if ($request->filled('estado')) {
            $query->where('estado', $request->estado);
        }

        if ($request->filled('tipo')) {
            $query->where('tipo_reporte', $request->tipo);
        }

        $reportes = $query->orderBy('created_at', 'desc')->paginate(10);
        
        $categorias = Categoria::where('activo', true)->get();
        
        return view('reportes.index', compact('reportes', 'categorias'));
    }

    public function create()
    {
        $usuarios = Usuario::where('activo', true)->get();
        $categorias = Categoria::where('activo', true)->get();
        $cuadrantes = Cuadrante::where('activo', true)->get();
        
        return view('reportes.create', compact('usuarios', 'categorias', 'cuadrantes'));
    }

    public function store(Request $request)
    {
        $validatedData = $request->validate([
            'usuario_id' => 'required|uuid|exists:usuarios,id',
            'categoria_id' => 'required|uuid|exists:categorias,id',
            'cuadrante_id' => 'required|uuid|exists:cuadrantes,id',
            'tipo_reporte' => 'required|in:perdido,encontrado',
            'titulo' => 'required|string|max:200',
            'descripcion' => 'required|string',
            'fecha_perdida' => 'nullable|date',
            'direccion_referencia' => 'nullable|string',

            'estado' => 'nullable|in:activo,resuelto,inactivo,spam',
            'contacto_publico' => 'nullable|boolean',
            'telefono_contacto' => 'nullable|string|max:20',
            'email_contacto' => 'nullable|email',
            'recompensa' => 'nullable|numeric|min:0'
        ]);

        Reporte::create($validatedData);

        return redirect()->route('reportes.index')
            ->with('success', 'Reporte creado exitosamente');
    }

    public function show(string $id)
    {
        $reporte = Reporte::with(['usuario', 'categoria', 'cuadrante', 'respuestas.usuario', 'expansiones', 'imagenes', 'voluntarios.usuario'])
            ->findOrFail($id);
        
        $reporte->increment('vistas');

        // Construir Cronograma
        $timeline = collect();

        // 1. Evento de inicio (Reporte Creado)
        $timeline->push([
            'tipo' => 'inicio',
            'fecha' => $reporte->created_at,
            'titulo' => 'Reporte Creado',
            'descripcion' => 'El reporte fue publicado inicialmente.',
            'icono' => 'bi-flag',
            'color' => 'primary',
            'usuario' => $reporte->usuario
        ]);

        // 2. Fecha de pérdida (si es diferente a la de reporte y existe)
        if ($reporte->fecha_perdida && $reporte->fecha_perdida->diffInMinutes($reporte->created_at) > 60) {
             $timeline->push([
                'tipo' => 'perdida',
                'fecha' => $reporte->fecha_perdida,
                'titulo' => 'Fecha del Incidente',
                'descripcion' => 'Momento aproximado en que ocurrió el incidente.',
                'icono' => 'bi-calendar-event',
                'color' => 'warning',
                'usuario' => null
            ]);
        }

        // 3. Respuestas / Avistamientos
        foreach ($reporte->respuestas as $respuesta) {
            $timeline->push([
                'tipo' => 'respuesta',
                'fecha' => $respuesta->created_at,
                'titulo' => 'Respuesta Recibida', // Podría ser "Avistamiento" si es de ese tipo
                'descripcion' => $respuesta->mensaje,
                'icono' => 'bi-chat-dots',
                'color' => 'info',
                'usuario' => $respuesta->usuario
            ]);
        }

        // 4. Expansiones de búsqueda (Agrupadas por Nivel)
        $expansionesAgrupadas = $reporte->expansiones->groupBy('nivel');
        foreach ($expansionesAgrupadas as $nivel => $expansiones) {
            $primeraExp = $expansiones->first();
            $nombresCuadrantes = $expansiones->map(function($e) {
                return $e->cuadranteExpandido ? $e->cuadranteExpandido->codigo : 'Desconocido';
            })->filter()->implode(', ');

            $timeline->push([
                'tipo' => 'expansion',
                'fecha' => $primeraExp->fecha_expansion ?? $primeraExp->created_at ?? $reporte->updated_at,
                'titulo' => 'Expansión de Búsqueda (Nivel ' . $nivel . ')',
                'descripcion' => 'Se ha expandido a ' . $expansiones->count() . ' cuadrante(s): ' . $nombresCuadrantes,
                'icono' => 'bi-arrows-expand',
                'color' => 'secondary',
                'usuario' => null
            ]);
        }
        
        // 4.5 Tracking de Voluntarios
        foreach ($reporte->voluntarios as $voluntario) {
            if ($voluntario->inicio_busqueda) {
                $duracionStr = '';
                if ($voluntario->fin_busqueda) {
                    $secs = $voluntario->inicio_busqueda->diffInSeconds($voluntario->fin_busqueda);
                    $mins = floor($secs / 60);
                    $duracionStr = " - Duración: " . ($mins >= 60 ? floor($mins / 60) . 'h ' . ($mins % 60) . 'm' : $mins . 'm');
                } else {
                    $duracionStr = " - (En curso)";
                }

                $timeline->push([
                    'tipo' => 'tracking',
                    'fecha' => $voluntario->inicio_busqueda,
                    'titulo' => 'Tracking ' . ($voluntario->fin_busqueda ? 'Finalizado' : 'Iniciado'),
                    'descripcion' => 'Recorrido de búsqueda registrado' . $duracionStr,
                    'icono' => 'bi-geo-alt',
                    'color' => 'success',
                    'usuario' => $voluntario->usuario
                ]);
            }
        }

        // 5. Resolución (si está resuelto)
        if (in_array($reporte->estado, ['resuelto', 'cerrado'])) {
            $timeline->push([
                'tipo' => 'resolucion',
                'fecha' => $reporte->updated_at,
                'titulo' => 'Caso ' . ucfirst($reporte->estado),
                'descripcion' => 'El reporte ha sido marcado como ' . $reporte->estado . ($reporte->motivo_cierre ? ' por el motivo: ' . $reporte->motivo_cierre : '.'),
                'icono' => 'bi-check-circle-fill',
                'color' => 'success',
                'usuario' => null // O el usuario que lo cerró si guardáramos eso
            ]);
        }

        // Ordenar por fecha cronológicamente
        $timeline = $timeline->sortBy('fecha');

        // Cargar pistas de búsqueda y evidencias con ubicación
        $pistas = $reporte->respuestas()
            ->with('imagenes')
            ->whereNotNull('ubicacion_lat')
            ->whereNotNull('ubicacion_lng')
            ->where(function($q) {
                $q->where('estado_evidencia', 'approved')
                  ->orWhereIn('tipo_respuesta', ['pista', 'informacion']);
            })
            ->orderBy('created_at')
            ->get();

        // Lista de cuadrantes para el selector de reasignación
        $cuadrantes = Cuadrante::orderBy('codigo')->get(['id', 'codigo', 'nombre', 'zona']);

        // ─── Lógica de Foco Dinámico (pista_id) ──────────────────────────────
        $fotoPrincipal      = $reporte->imagenes->count() > 0 ? $reporte->imagenes->first()->url : null;
        $tituloPrincipal    = 'Foto del Reporte';
        $descripcionPrincipal = '';
        $fechaPrincipal     = $reporte->created_at ? $reporte->created_at->format('d/m/Y H:i') : 'Fecha desconocida';
        $foco = null;

        $pistaId = request('pista_id');
        if ($pistaId) {
            $foco = \App\Models\Respuesta::with(['usuario', 'imagenes'])->find($pistaId);
            if ($foco && $foco->reporte_id == $reporte->id) {
                // Configurar foto e info de la vista enfocada
                $imgFoco = null;
                if ($foco->relationLoaded('imagenes') && $foco->getRelation('imagenes')->count() > 0) {
                    $imgFoco = $foco->getRelation('imagenes')->first()->url;
                }
                if (!$imgFoco && is_array($foco->imagenes) && count($foco->imagenes) > 0) {
                    $first = $foco->imagenes[0];
                    $imgFoco = is_string($first) ? $first : ($first['url'] ?? null);
                }

                if ($imgFoco) {
                    $fotoPrincipal = $imgFoco;
                }
                // Si no hay foto en la pista/evidencia, conservamos la foto principal del reporte.

                $esAvistamiento = in_array($foco->tipo_respuesta, ['avistamiento', 'encontrado']);
                $tituloPrincipal = $esAvistamiento ? 'Foto de la Evidencia' : 'Información de la Pista';
                $descripcionPrincipal = $foco->mensaje;
                $fechaPrincipal = $foco->created_at ? $foco->created_at->format('d/m/Y H:i') : '';
            } else {
                $foco = null; // Evitar conflictos si no pertenece
            }
        }

        // ─── Separar Pistas de Evidencias ───────────────────────────────────
        $respuestasAll = $reporte->respuestas()->with(['usuario', 'imagenes'])->orderBy('created_at', 'desc')->get();
        
        $pistasAdmin = $respuestasAll->filter(function($r) {
            return in_array($r->tipo_respuesta, ['pista', 'informacion']);
        });
        
        $evidenciasVoluntarios = $respuestasAll->filter(function($r) {
            return !in_array($r->tipo_respuesta, ['pista', 'informacion']);
        });

        return view('reportes.show', compact(
            'reporte', 'timeline', 'pistas', 'cuadrantes', 
            'pistasAdmin', 'evidenciasVoluntarios', 'foco',
            'fotoPrincipal', 'tituloPrincipal', 'descripcionPrincipal', 'fechaPrincipal'
        ));
    }


    public function edit(string $id)
    {
        $reporte = Reporte::findOrFail($id);
        $usuarios = Usuario::where('activo', true)->get();
        $categorias = Categoria::where('activo', true)->get();
        $cuadrantes = Cuadrante::where('activo', true)->get();
        
        return view('reportes.edit', compact('reporte', 'usuarios', 'categorias', 'cuadrantes'));
    }

    public function update(Request $request, string $id)
    {
        $reporte = Reporte::findOrFail($id);

        $validatedData = $request->validate([
            'titulo' => 'required|string|max:200',
            'descripcion' => 'required|string',
            'estado' => 'nullable|in:activo,resuelto,inactivo,spam',

            'recompensa' => 'nullable|numeric|min:0'
        ]);

        $reporte->update($validatedData);

        return redirect()->route('reportes.index')
            ->with('success', 'Reporte actualizado exitosamente');
    }

    public function cerrar(Request $request, string $id)
    {
        $reporte = Reporte::findOrFail($id);

        $request->validate([
            'motivo_cierre' => 'required|string|max:500'
        ]);

        try {
            // Guardar estado y motivo usando asignación directa para evitar problemas de fillable
            $reporte->estado = 'cerrado';
            $reporte->motivo_cierre = $request->motivo_cierre;
            $reporte->save();

            // Notificar a voluntarios y al creador
            $usuariosANotificar = \App\Models\ReporteVoluntario::where('reporte_id', $reporte->id)
                ->pluck('usuario_id')->toArray();
            if (!in_array($reporte->usuario_id, $usuariosANotificar)) {
                $usuariosANotificar[] = $reporte->usuario_id;
            }

            $adminText = auth()->user()->hasRole('administrador') ? ' por un administrador' : '';
            $titulo  = 'Búsqueda Cerrada';
            $mensaje = 'La búsqueda "' . $reporte->titulo . '" ha sido cerrada' . $adminText . '. Motivo: ' . $request->motivo_cierre;

            $this->notificarGrupo($reporte, $titulo, $mensaje, $usuariosANotificar);

            return redirect()->route('reportes.show', $reporte->id)
                ->with('success', 'Búsqueda cerrada exitosamente.');

        } catch (\Exception $e) {
            \Log::error('[cerrar] Error al cerrar reporte ' . $id . ': ' . $e->getMessage());
            return redirect()->back()
                ->with('error', 'Error al cerrar la búsqueda: ' . $e->getMessage());
        }
    }

    public function pausar(Request $request, string $id)
    {
        $reporte = Reporte::findOrFail($id);

        if (!in_array($reporte->estado, ['activo', 'en_progreso'])) {
            return redirect()->route('reportes.show', $reporte->id)
                ->with('error', 'Solo se puede pausar una búsqueda activa.');
        }

        $reporte->estado = 'pausado';
        $reporte->save();

        $this->notificarGrupo(
            $reporte,
            'Búsqueda Pausada',
            'La búsqueda "' . $reporte->titulo . '" ha sido pausada temporalmente. Te avisaremos cuando se reanude.'
        );

        return redirect()->route('reportes.show', $reporte->id)
            ->with('success', 'Búsqueda pausada. Los voluntarios serán notificados.');
    }

    public function reanudar(Request $request, string $id)
    {
        $reporte = Reporte::findOrFail($id);

        if (!in_array($reporte->estado, ['cerrado', 'pausado'])) {
            return redirect()->route('reportes.show', $reporte->id)
                ->with('error', 'Solo se puede reanudar una búsqueda cerrada o pausada.');
        }

        $reporte->estado = 'activo';
        $reporte->save();

        // Notificar a voluntarios que la búsqueda se reanudó
        $usuariosANotificar = \App\Models\ReporteVoluntario::where('reporte_id', $reporte->id)
            ->pluck('usuario_id')->toArray();
        if (!in_array($reporte->usuario_id, $usuariosANotificar)) {
            $usuariosANotificar[] = $reporte->usuario_id;
        }

        $this->notificarGrupo(
            $reporte,
            'Búsqueda Reanudada',
            'La búsqueda "' . $reporte->titulo . '" ha sido reanudada. ¡Volvemos a buscar!'
        );

        return redirect()->route('reportes.show', $reporte->id)
            ->with('success', 'Búsqueda reanudada exitosamente.');
    }

    public function destroy(Request $request, string $id)
    {
        $reporte = Reporte::findOrFail($id);
        $titulo = $reporte->titulo;
        
        $request->validate([
            'motivo_eliminacion' => 'required|string|max:500'
        ]);
        
        // Notificar a voluntarios y creador antes de eliminar
        $usuariosANotificar = \App\Models\ReporteVoluntario::where('reporte_id', $reporte->id)->pluck('usuario_id')->toArray();
        if (!in_array($reporte->usuario_id, $usuariosANotificar)) {
            $usuariosANotificar[] = $reporte->usuario_id;
        }
        
        $tituloNotif = 'Búsqueda Eliminada';
        $mensajeNotif = 'La búsqueda "' . $titulo . '" ha sido eliminada por un administrador. Motivo: ' . $request->motivo_eliminacion;
        $fcm = new FcmService();

        foreach (array_unique($usuariosANotificar) as $userId) {
            $notif = \App\Models\Notificacion::create([
                'usuario_id' => $userId,
                'tipo' => 'alerta_operativo',
                'titulo' => $tituloNotif,
                'mensaje' => $mensajeNotif,
                'leida' => false,
                'enviada_push' => false,
            ]);

            // Enviar FCM a todos los dispositivos del usuario
            if ($fcm->estaConfigurado()) {
                $resultado = $fcm->enviarAUsuario(
                    $userId,
                    $tituloNotif,
                    $mensajeNotif,
                    ['tipo' => 'alerta_operativo']
                );
                if ($resultado['enviados'] > 0) {
                    $notif->update(['enviada_push' => true]);
                }
            }
        }

        $reporte->delete();

        return redirect()->route('reportes.index')
            ->with('success', 'Reporte eliminado exitosamente');
    }

    /**
     * Guarda un punto de información en el mapa del reporte.
     * Solo permitido para administradores/editores o el creador del reporte.
     */
    public function guardarInformacion(Request $request, string $reporte)
    {
        $rep = Reporte::findOrFail($reporte);

        // ─── Autorización ───────────────────────────────────────────────────
        $user = auth()->user();
        $esAdmin   = $user->hasRole('administrador') || $user->hasRole('editor');
        $esCreador = $user->id === $rep->usuario_id;

        if (!$esAdmin && !$esCreador) {
            return response()->json([
                'error' => 'No tienes permiso para agregar información a este operativo.'
            ], 403);
        }

        // ─── Validación ──────────────────────────────────────────────────────
        $validated = $request->validate([
            'lat'          => 'required|numeric|between:-90,90',
            'lng'          => 'required|numeric|between:-180,180',
            'categoria'    => 'required|string|max:100',
            'titulo'       => 'required|string|max:255',
            'descripcion'  => 'required|string',
            'cuadrante_id' => 'nullable|uuid|exists:cuadrantes,id',
        ]);

        // ─── Crear Respuesta tipo informacion ──────────────────────────────────────
        $info = \App\Models\Respuesta::create([
            'reporte_id'           => $rep->id,
            'usuario_id'           => $user->id,
            'tipo_respuesta'       => 'informacion',
            'titulo'               => $validated['titulo'],
            'categoria_informacion'=> $validated['categoria'],
            'mensaje'              => $validated['descripcion'],
            'ubicacion_lat'        => $validated['lat'],
            'ubicacion_lng'        => $validated['lng'],
            'verificada'           => true,
        ]);

        // ─── Actualizar cuadrante si se indicó uno nuevo ─────────────────────
        if (!empty($validated['cuadrante_id'])) {
            $rep->update(['cuadrante_id' => $validated['cuadrante_id']]);
        }

        return response()->json([
            'success' => true,
            'data'    => $info,
            'message' => 'Información registrada correctamente.',
        ], 201);
    }

    /**
     * Elimina una información o evidencia específica.
     */
    public function eliminarInformacion(Request $request, string $reporte, string $infoId)
    {
        $rep = Reporte::findOrFail($reporte);

        // Autorización
        $user = auth()->user();
        $esAdmin   = $user->hasRole('administrador') || $user->hasRole('editor');
        $esCreador = $user->id === $rep->usuario_id;

        if (!$esAdmin && !$esCreador) {
            return redirect()->back()->with('error', 'No tienes permiso para eliminar evidencias.');
        }

        $respuesta = \App\Models\Respuesta::where('id', $infoId)->where('reporte_id', $reporte)->firstOrFail();
        $respuesta->delete();

        return redirect()->back()->with('success', 'Registro eliminado correctamente.');
    }

    /**
     * Edita el mensaje de una información específica.
     */
    public function editarInformacion(Request $request, string $reporte, string $infoId)
    {
        $rep = Reporte::findOrFail($reporte);

        // Autorización
        $user = auth()->user();
        $esAdmin   = $user->hasRole('administrador') || $user->hasRole('editor');
        $esCreador = $user->id === $rep->usuario_id;

        if (!$esAdmin && !$esCreador) {
            return redirect()->back()->with('error', 'No tienes permiso para editar esta información.');
        }

        $validated = $request->validate([
            'titulo'  => 'required|string|max:255',
            'mensaje' => 'required|string|max:1000',
        ]);

        $respuesta = \App\Models\Respuesta::where('id', $infoId)->where('reporte_id', $reporte)->firstOrFail();
        $respuesta->update([
            'titulo'  => $validated['titulo'],
            'mensaje' => $validated['mensaje']
        ]);

        return redirect()->back()->with('success', 'Información editada correctamente.');
    }

    /**
     * Aprueba una evidencia desde el panel web.
     */
    public function aprobarEvidencia(Request $request, string $reporte, string $infoId)
    {
        $rep = Reporte::findOrFail($reporte);

        // Autorización
        $user = auth()->user();
        $esAdmin   = $user->hasRole('administrador') || $user->hasRole('editor');

        if (!$esAdmin && $user->id !== $rep->usuario_id) {
            return redirect()->back()->with('error', 'No tienes permiso para aprobar evidencias.');
        }

        $respuesta = \App\Models\Respuesta::where('id', $infoId)->where('reporte_id', $reporte)->firstOrFail();
        $respuesta->update(['estado_evidencia' => 'approved']);

        // Opcional: Enviar notificación al voluntario aquí (se puede extraer del API si se desea, por ahora solo actualiza el estado)

        return redirect()->back()->with('success', 'Evidencia aprobada correctamente.');
    }

    /**
     * Rechaza una evidencia desde el panel web.
     */
    public function rechazarEvidencia(Request $request, string $reporte, string $infoId)
    {
        $rep = Reporte::findOrFail($reporte);

        // Autorización
        $user = auth()->user();
        $esAdmin   = $user->hasRole('administrador') || $user->hasRole('editor');

        if (!$esAdmin && $user->id !== $rep->usuario_id) {
            return redirect()->back()->with('error', 'No tienes permiso para rechazar evidencias.');
        }

        $respuesta = \App\Models\Respuesta::where('id', $infoId)->where('reporte_id', $reporte)->firstOrFail();
        $respuesta->update(['estado_evidencia' => 'rejected']);

        return redirect()->back()->with('success', 'Evidencia rechazada correctamente.');
    }

    /**
     * Envia notificaciones a todos los voluntarios + creador de un reporte.
     * Deduplica por FCM token para evitar notificaciones dobles cuando un mismo
     * dispositivo tiene dos cuentas registradas como voluntarios.
     */
    private function notificarGrupo(
        Reporte $reporte,
        string $titulo,
        string $mensaje,
        ?array $usuariosIds = null
    ): void {
        if ($usuariosIds === null) {
            $usuariosIds = \App\Models\ReporteVoluntario::where('reporte_id', $reporte->id)
                ->pluck('usuario_id')->toArray();
            if (!in_array($reporte->usuario_id, $usuariosIds)) {
                $usuariosIds[] = $reporte->usuario_id;
            }
        }

        $fcm = new FcmService();
        $usuariosNotificados = [];

        foreach (array_unique($usuariosIds) as $userId) {
            try {
                $notif = \App\Models\Notificacion::create([
                    'usuario_id'   => $userId,
                    'tipo'         => 'alerta_operativo',
                    'titulo'       => $titulo,
                    'mensaje'      => $mensaje,
                    'leida'        => false,
                    'enviada_push' => false,
                ]);

                if ($fcm->estaConfigurado() && !in_array($userId, $usuariosNotificados)) {
                    $usuariosNotificados[] = $userId;
                    $resultado = $fcm->enviarAUsuario(
                        $userId,
                        $titulo,
                        $mensaje,
                        ['reporte_id' => $reporte->id, 'tipo' => 'alerta_operativo']
                    );
                    if ($resultado['enviados'] > 0) {
                        $notif->update(['enviada_push' => true]);
                    }
                }
            } catch (\Exception $e) {
                \Log::error('[notificarGrupo] Error notificando usuario ' . $userId . ': ' . $e->getMessage());
            }
        }
    }
}
