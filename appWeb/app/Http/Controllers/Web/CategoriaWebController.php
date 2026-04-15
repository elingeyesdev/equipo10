<?php



namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Categoria;
use Illuminate\Http\Request;

class CategoriaWebController extends Controller
{
    public function index()
    {
        $categorias = Categoria::withCount('reportes')
            ->orderBy('nombre')
            ->get();
        
        return view('categorias.index', compact('categorias'));
    }

    public function create()
    {
        return view('categorias.create');
    }

    public function store(Request $request)
    {
        $validatedData = $request->validate([
            'nombre' => 'required|string|max:100|unique:categorias,nombre',
            'icono' => 'nullable|string|max:50',
            'color' => 'nullable|string|max:7|regex:/^#[0-9A-Fa-f]{6}$/',
            'descripcion' => 'nullable|string',
            'activo' => 'nullable|boolean'
        ]);

        Categoria::create($validatedData);

        return redirect()->route('categorias.index')
            ->with('success', 'Categoría creada exitosamente');
    }

    public function show(string $id)
    {
        $categoria = Categoria::withCount('reportes')->findOrFail($id);
        $reportes = $categoria->reportes()->with(['usuario', 'cuadrante'])->get();
        
        return view('categorias.show', compact('categoria', 'reportes'));
    }

    public function edit(string $id)
    {
        $categoria = Categoria::findOrFail($id);
        return view('categorias.edit', compact('categoria'));
    }

    public function update(Request $request, string $id)
    {
        $categoria = Categoria::findOrFail($id);

        $validatedData = $request->validate([
            'nombre' => 'required|string|max:100|unique:categorias,nombre,'.$id,
            'icono' => 'nullable|string|max:50',
            'color' => 'nullable|string|max:7|regex:/^#[0-9A-Fa-f]{6}$/',
            'descripcion' => 'nullable|string',
            'activo' => 'nullable|boolean'
        ]);

        $categoria->update($validatedData);

        return redirect()->route('categorias.index')
            ->with('success', 'Categoría actualizada exitosamente');
    }

    public function destroy(string $id)
    {
        $categoria = Categoria::findOrFail($id);
        
        if ($categoria->reportes()->count() > 0) {
            return redirect()->route('categorias.index')
                ->with('error', 'No se puede eliminar la categoría porque tiene reportes asociados');
        }
        
        $categoria->delete();

        return redirect()->route('categorias.index')
            ->with('success', 'Categoría eliminada exitosamente');
    }
}