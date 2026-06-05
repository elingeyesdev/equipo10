<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>Diagnostic Laravel DB & Geolocation Inspect</h1>";

try {
    // Bootstrap Laravel
    require __DIR__.'/../vendor/autoload.php';
    $app = require_once __DIR__.'/../bootstrap/app.php';
    
    // Boot the application kernel
    $kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
    $kernel->bootstrap();

    use App\Models\Cuadrante;

    $cnt = Cuadrante::count();
    echo "<p>Total cuadrantes in DB: <strong>$cnt</strong></p>";

    $cntNullGeo = Cuadrante::whereNull('geometria')->count();
    $cntNotNullGeo = Cuadrante::whereNotNull('geometria')->count();
    echo "<p>Cuadrantes with null geometry: <strong>$cntNullGeo</strong></p>";
    echo "<p>Cuadrantes with NOT null geometry: <strong>$cntNotNullGeo</strong></p>";

    // Test detection for Santa Cruz point
    $lat = -17.7816;
    $lng = -63.1826;
    echo "<h3>Testing detection for point: $lat, $lng</h3>";

    // 1. Raw DB query matching bounding box
    $candidatosRaw = \DB::table('cuadrantes')
        ->where('activo', true)
        ->where(function($q) use ($lat) {
            $q->where(function($sq) use ($lat) {
                $sq->where('lat_min', '<=', $lat)->where('lat_max', '>=', $lat);
            })->orWhere(function($sq) use ($lat) {
                $sq->where('lat_min', '>=', $lat)->where('lat_max', '<=', $lat);
            });
        })
        ->where(function($q) use ($lng) {
            $q->where(function($sq) use ($lng) {
                $sq->where('lng_min', '<=', $lng)->where('lng_max', '>=', $lng);
            })->orWhere(function($sq) use ($lng) {
                $sq->where('lng_min', '>=', $lng)->where('lng_max', '<=', $lng);
            });
        })
        ->get();

    echo "<p>Raw database candidates count (any geometry): <strong>" . count($candidatosRaw) . "</strong></p>";
    if (count($candidatosRaw) > 0) {
        echo "<pre>" . json_encode($candidatosRaw, JSON_PRETTY_PRINT) . "</pre>";
    }

    // 2. Bounding box query restricting to null geometry
    $candidatosNullGeo = \DB::table('cuadrantes')
        ->where('activo', true)
        ->whereNull('geometria')
        ->where(function($q) use ($lat) {
            $q->where(function($sq) use ($lat) {
                $sq->where('lat_min', '<=', $lat)->where('lat_max', '>=', $lat);
            })->orWhere(function($sq) use ($lat) {
                $sq->where('lat_min', '>=', $lat)->where('lat_max', '<=', $lat);
            });
        })
        ->where(function($q) use ($lng) {
            $q->where(function($sq) use ($lng) {
                $sq->where('lng_min', '<=', $lng)->where('lng_max', '>=', $lng);
            })->orWhere(function($sq) use ($lng) {
                $sq->where('lng_min', '>=', $lng)->where('lng_max', '<=', $lng);
            });
        })
        ->get();

    echo "<p>Raw database candidates count (geometria IS NULL): <strong>" . count($candidatosNullGeo) . "</strong></p>";

    // 3. Test Cuadrante::detectByLocation
    $detected = Cuadrante::detectByLocation($lat, $lng);
    echo "<p>Cuadrante::detectByLocation returned: <strong>" . ($detected ? $detected->codigo . " (id: " . $detected->id . ")" : "NULL") . "</strong></p>";

} catch (Exception $e) {
    echo "<p style='color:red;'>ERROR: " . htmlspecialchars($e->getMessage()) . "</p>";
    echo "<pre>" . htmlspecialchars($e->getTraceAsString()) . "</pre>";
}
