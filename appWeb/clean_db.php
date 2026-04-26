<?php 
require __DIR__.'/vendor/autoload.php'; 
$app = require_once __DIR__.'/bootstrap/app.php'; 
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class); 
$kernel->bootstrap(); 

$reportes = \App\Models\Reporte::all(); 
foreach($reportes as $r) { 
    if ($r->primera_imagen === 'http://localhost:8081/storage/' || $r->primera_imagen === 'http://localhost:8081/storage') { 
        $r->primera_imagen = null; 
        $r->save(); 
    } 
} 
echo 'Database cleaned';
?>
