<?php
DB::statement('ALTER TABLE reportes ALTER COLUMN cuadrante_id DROP NOT NULL;');
echo "Database table 'reportes' fixed! cuadrante_id is now nullable.\n";
