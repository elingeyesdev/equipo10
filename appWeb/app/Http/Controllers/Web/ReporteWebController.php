<?php




namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Reporte;
use App\Models\Usuario;
use App\Models\Categoria;
use App\Models\Cuadrante;
use Illuminate\Http\Request;

class ReporteWebController extends Controller
{
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
            'prioridad' => 'nullable|in:baja,normal,alta,urgente',
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
        $reporte = Reporte::with(['usuario', 'categoria', 'cuadrante', 'respuestas.usuario', 'expansiones'])
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

        // 4. Expansiones de búsqueda
        foreach ($reporte->expansiones as $expansion) {
            $timeline->push([
                'tipo' => 'expansion',
                'fecha' => $expansion->created_at ?? $reporte->updated_at, // Fallback si no tiene created_at
                'titulo' => 'Expansión de Búsqueda (Nivel ' . $expansion->nivel . ')',
                'descripcion' => 'El área de búsqueda se ha expandido a nuevos cuadrantes.',
                'icono' => 'bi-arrows-expand',
                'color' => 'secondary',
                'usuario' => null
            ]);
        }

        // 5. Resolución (si está resuelto)
        if ($reporte->estado === 'resuelto') {
            $timeline->push([
                'tipo' => 'resolucion',
                'fecha' => $reporte->updated_at,
                'titulo' => 'Caso Resuelto',
                'descripcion' => 'El reporte ha sido marcado como resuelto.',
                'icono' => 'bi-check-circle-fill',
                'color' => 'success',
                'usuario' => null // O el usuario que lo cerró si guardáramos eso
            ]);
        }

        // Ordenar por fecha cronológicamente
        $timeline = $timeline->sortBy('fecha');
        
        return view('reportes.show', compact('reporte', 'timeline'));
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
            'prioridad' => 'nullable|in:baja,normal,alta,urgente',
            'recompensa' => 'nullable|numeric|min:0'
        ]);

        $reporte->update($validatedData);

        return redirect()->route('reportes.index')
            ->with('success', 'Reporte actualizado exitosamente');
    }

    public function destroy(string $id)
    {
        $reporte = Reporte::findOrFail($id);
        $reporte->delete();

        return redirect()->route('reportes.index')
            ->with('success', 'Reporte eliminado exitosamente');
    }
}