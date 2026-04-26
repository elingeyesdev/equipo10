<?php
$reporte = \App\Models\Reporte::first();
if (!$reporte) {
    echo "No reports found\n";
    exit;
}

$id = $reporte->id;
echo "Editing Reporte: $id\n";

// Update using controller
$request = \Illuminate\Http\Request::create('/api/reportes/' . $id, 'PUT', [
    'titulo' => 'Test',
    'descripcion' => 'Test Desc'
]);

$controller = new \App\Http\Controllers\Api\ReporteController();
$response = $controller->update($request, $id);
echo "RESPONSE FROM API:\n";
echo $response->getContent() . "\n";
