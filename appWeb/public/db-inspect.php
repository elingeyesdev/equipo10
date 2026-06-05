<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>Detailed Database Table Inspection</h1>";

$host = getenv('DB_HOST') ?: 'dpg-d8h3r1vlk1mc73e0tacg-a';
$port = getenv('DB_PORT') ?: '5432';
$database = getenv('DB_DATABASE') ?: 'amigate';
$username = getenv('DB_USERNAME') ?: 'amigate_user';
$password = getenv('DB_PASSWORD') ?: 'OUhpVrbQZAQKvNjh58AEwtxyyjZVVNIh';

try {
    $dsn = "pgsql:host=$host;port=$port;dbname=$database";
    $pdo = new PDO($dsn, $username, $password, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
    echo "<p style='color:green;'>Connected successfully.</p>";
    
    // Check tables
    $stmt = $pdo->query("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public'");
    $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
    echo "<h3>Tables:</h3><ul>";
    foreach ($tables as $table) {
        echo "<li><strong>$table</strong>";
        try {
            // Get columns and types
            $q = $pdo->query("SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = '$table'");
            $cols = $q->fetchAll(PDO::FETCH_ASSOC);
            echo "<ul>";
            foreach ($cols as $col) {
                echo "<li>{$col['column_name']} ({$col['data_type']}) - Nullable: {$col['is_nullable']}</li>";
            }
            echo "</ul>";
        } catch (Exception $eCol) {
            echo " (Error reading columns: " . htmlspecialchars($eCol->getMessage()) . ")";
        }
        echo "</li>";
    }
    echo "</ul>";
} catch (Exception $e) {
    echo "<p style='color:red;'>ERROR: " . htmlspecialchars($e->getMessage()) . "</p>";
}
