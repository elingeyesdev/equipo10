<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$reporteId = '019dcee1-589d-70e5-b431-27bfb75bc6e2';
$galeria = [];

$respuestas = \App\Models\Respuesta::where('reporte_id', $reporteId)
    ->where('estado_evidencia', 'approved')
    ->with(['imagenes', 'usuario'])
    ->get();

foreach ($respuestas as $respuesta) {
    if ($respuesta->imagenes instanceof \Illuminate\Database\Eloquent\Collection && $respuesta->imagenes->isNotEmpty()) {
        foreach ($respuesta->imagenes as $img) {
            $galeria[] = [
                'id' => $img->id,
                'url' => $img->url
            ];
        }
    } else {
        echo "NO ES COLLECTION o ESTA VACIA\n";
    }
}

echo json_encode($galeria);
