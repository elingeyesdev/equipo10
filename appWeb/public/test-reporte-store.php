<?php
// Trigger deploy comment
error_reporting(E_ALL);
ini_set('display_errors', 1);

use App\Models\Cuadrante;
use App\Models\Reporte;
use Illuminate\Http\Request;
use App\Http\Controllers\Api\ReporteController;

echo "<h1>Testing Reporte Store Logic</h1>";

try {
    // Bootstrap Laravel
    require __DIR__.'/../vendor/autoload.php';
    $app = require_once __DIR__.'/../bootstrap/app.php';
    
    // Boot the application kernel
    $kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
    $kernel->bootstrap();

    // We can simulate a request
    $requestData = [
        'usuario_id' => '019dcb54-b88a-7127-9017-15cc823ec1fd',
        'categoria_id' => '4c067a7b-0237-4582-99ee-12020e0ec2aa',
        'tipo_reporte' => 'perdido',
        'titulo' => 'Test Titulo',
        'descripcion' => 'Test Descripcion',
        'ubicacion_exacta_lat' => -17.7816,
        'ubicacion_exacta_lng' => -63.1826,
        'contacto_publico' => true,
    ];

    // Case 1: cuadrante_id is not passed
    echo "<h3>Case 1: No cuadrante_id passed</h3>";
    $req1 = Request::create('/api/reportes', 'POST', $requestData);
    $controller = new ReporteController();
    
    // We run it inside a transaction to prevent actual database write
    \DB::beginTransaction();
    try {
        $resp1 = $controller->store($req1);
        echo "<p>Status Code: " . $resp1->getStatusCode() . "</p>";
        echo "<pre>" . json_encode(json_decode($resp1->getContent()), JSON_PRETTY_PRINT) . "</pre>";
    } catch (Exception $e1) {
        echo "<p style='color:red;'>Exception in Case 1: " . $e1->getMessage() . "</p>";
        echo "<pre>" . $e1->getTraceAsString() . "</pre>";
    } finally {
        \DB::rollBack();
    }

    // Case 2: cuadrante_id is string "null"
    echo "<h3>Case 2: cuadrante_id passed as string 'null'</h3>";
    $requestData['cuadrante_id'] = 'null';
    $req2 = Request::create('/api/reportes', 'POST', $requestData);
    
    \DB::beginTransaction();
    try {
        $resp2 = $controller->store($req2);
        echo "<p>Status Code: " . $resp2->getStatusCode() . "</p>";
        echo "<pre>" . json_encode(json_decode($resp2->getContent()), JSON_PRETTY_PRINT) . "</pre>";
    } catch (Exception $e2) {
        echo "<p style='color:red;'>Exception in Case 2: " . $e2->getMessage() . "</p>";
        echo "<pre>" . $e2->getTraceAsString() . "</pre>";
    } finally {
        \DB::rollBack();
    }

} catch (Exception $e) {
    echo "<p style='color:red;'>Bootstrap Error: " . htmlspecialchars($e->getMessage()) . "</p>";
}
