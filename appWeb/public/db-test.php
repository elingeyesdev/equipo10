<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>PDO Connection Test</h1>";

$host = getenv('DB_HOST') ?: 'dpg-d8h3r1vlk1mc73e0tacg-a';
$port = getenv('DB_PORT') ?: '5432';
$database = getenv('DB_DATABASE') ?: 'amigate';
$username = getenv('DB_USERNAME') ?: 'amigate_user';
$password = getenv('DB_PASSWORD') ?: 'OUhpVrbQZAQKvNjh58AEwtxyyjZVVNIh';

// Also try the full external host if short one fails, or print both
echo "<p>Connecting to: host=$host, port=$port, dbname=$database, user=$username</p>";

try {
    $dsn = "pgsql:host=$host;port=$port;dbname=$database";
    $pdo = new PDO($dsn, $username, $password, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
    echo "<p style='color:green;'>SUCCESS: Connected to database successfully!</p>";
    
    // Check tables
    $stmt = $pdo->query("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema'");
    $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
    echo "<p>Tables found: " . implode(', ', $tables) . "</p>";
} catch (Exception $e) {
    echo "<p style='color:red;'>ERROR: " . htmlspecialchars($e->getMessage()) . "</p>";
    
    // Try external hostname just in case internal DNS is not resolved yet or we are outside Oregon
    $externalHost = $host . ".oregon-postgres.render.com";
    echo "<p>Trying external host: $externalHost...</p>";
    try {
        $dsnExternal = "pgsql:host=$externalHost;port=$port;dbname=$database";
        $pdo = new PDO($dsnExternal, $username, $password, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
        echo "<p style='color:green;'>SUCCESS: Connected to external host successfully!</p>";
    } catch (Exception $e2) {
        echo "<p style='color:red;'>ERROR with external host: " . htmlspecialchars($e2->getMessage()) . "</p>";
    }
}
