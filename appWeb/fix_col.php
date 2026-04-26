<?php
DB::statement('ALTER TABLE reportes ADD COLUMN primera_imagen VARCHAR(255) NULL;');
echo "Database table 'reportes' fixed! primera_imagen is now added.\n";
