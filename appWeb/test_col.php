<?php
try {
    DB::statement('SELECT primera_imagen FROM reportes LIMIT 1');
    echo "Column exists\n";
} catch (\Exception $e) {
    echo "Column does NOT exist: " . $e->getMessage() . "\n";
}
