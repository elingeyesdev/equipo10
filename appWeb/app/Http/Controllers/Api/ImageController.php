<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ImagenAlmacenada;
use Illuminate\Http\Request;

class ImageController extends Controller
{
    /**
     * Servir imagen almacenada en la base de datos.
     */
    public function servirImagen($id)
    {
        $imagen = ImagenAlmacenada::find($id);

        if (!$imagen) {
            abort(404);
        }

        $data = base64_decode($imagen->base64_data);

        return response($data, 200)
            ->header('Content-Type', $imagen->mime_type)
            ->header('Cache-Control', 'public, max-age=2592000')
            ->header('Content-Length', strlen($data));
    }
}
