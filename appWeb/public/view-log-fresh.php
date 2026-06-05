<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>Laravel Error Log Reader</h1>";

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
