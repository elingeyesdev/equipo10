<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>Laravel Error Log Reader</h1>";

// Intenta encontrar el archivo temporal de logs que creamos en ReporteController
$lastErrorFile = __DIR__ . '/last_error.txt';
if (file_exists($lastErrorFile)) {
    echo "<h3>Contenido de last_error.txt:</h3>";
    echo "<pre style='background:#fee; padding:10px; border:1px solid #faa; overflow:auto;'>";
    echo htmlspecialchars(file_get_contents($lastErrorFile));
    echo "</pre>";
} else {
    echo "<p>No last_error.txt file found.</p>";
}

$lastErrorPutFile = __DIR__ . '/last_error_put.txt';
if (file_exists($lastErrorPutFile)) {
    echo "<h3>Contenido de last_error_put.txt:</h3>";
    echo "<pre style='background:#efe; padding:10px; border:1px solid #afa; overflow:auto;'>";
    echo htmlspecialchars(file_get_contents($lastErrorPutFile));
    echo "</pre>";
} else {
    echo "<p>No last_error_put.txt file found.</p>";
}

$logFile = __DIR__ . '/../storage/logs/laravel.log';

if (!file_exists($logFile)) {
    echo "<p style='color:orange;'>Log file does not exist at: $logFile</p>";
    exit;
}

echo "<p>Log size: " . filesize($logFile) . " bytes</p>";

$lines = file($logFile);
$lastLines = array_slice($lines, -150);

echo "<pre style='background:#f4f4f4; padding:10px; border:1px solid #ccc; overflow:auto;'>";
foreach ($lastLines as $line) {
    echo htmlspecialchars($line);
}
echo "</pre>";
