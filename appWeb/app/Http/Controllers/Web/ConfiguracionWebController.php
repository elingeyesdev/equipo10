<?php



namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\ConfiguracionSistema;
use Illuminate\Http\Request;

class ConfiguracionWebController extends Controller
{
    public function index()
    {
        $configuraciones = ConfiguracionSistema::orderBy('clave')->get();
        return view('configuracion.index', compact('configuraciones'));
    }

    public function edit()
    {
        $configuraciones = ConfiguracionSistema::orderBy('clave')->get();
        return view('configuracion.edit', compact('configuraciones'));
    }

    public function update(Request $request)
    {
        $data = $request->input('config', []);

        foreach ($data as $clave => $valor) {
            $config = ConfiguracionSistema::find($clave);
            if ($config) {
                // Validación básica según tipo
                if ($config->tipo == 'json' && !is_array($valor)) {
                    // Intentar decodificar para validar, pero guardar como string si el modelo lo maneja
                    // En este caso, el modelo casteará al leer, pero al escribir espera el valor crudo o array
                    // Si el input es texto JSON, lo guardamos tal cual
                }
                
                $config->valor = $valor;
                $config->save();
            }
        }

        return redirect()->route('configuracion.index')
            ->with('success', 'Configuración actualizada correctamente');
    }
}