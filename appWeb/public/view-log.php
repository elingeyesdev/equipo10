<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>Laravel Error Log Reader</h1>";

$logFile = __DIR__ . '/../storage/logs/laravel.log';

if (!file_exists($logFile)) {
    echo "<p style='color:orange;'>Log file does not exist at: $logFile</p>";
    
    // Let's list the directory contents to see what is there
    echo "<h3>Listing storage/logs directory:</h3>";
    $dir = __DIR__ . '/../storage/logs';
    if (is_dir($dir)) {
        $files = scandir($dir);
        echo "<ul>";
        foreach ($files as $file) {
            echo "<li>$file</li>";
        }
        echo "</ul>";
    } else {
        echo "<p style='color:red;'>storage/logs is not a directory</p>";
    }
    exit;
}

echo "<p>Log size: " . filesize($logFile) . " bytes</p>";

// Read last 100 lines
$lines = file($logFile);
$lastLines = array_slice($lines, -150);

echo "<pre style='background:#f4f4f4; padding:10px; border:1px solid #ccc; overflow:auto;'>";
foreach ($lastLines as $line) {
    echo htmlspecialchars($line);
}
echo "</pre>";
