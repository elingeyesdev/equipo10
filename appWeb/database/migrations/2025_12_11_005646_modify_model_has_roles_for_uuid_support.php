<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    
    public function up(): void
    {
        $tableNames = config('permission.table_names');
        $columnNames = config('permission.column_names');
        $modelMorphKey = $columnNames['model_morph_key'] ?? 'model_id';

        if (empty($tableNames)) {
            throw new \Exception('Error: config/permission.php not loaded.');
        }

        
        Schema::table($tableNames['model_has_roles'], function (Blueprint $table) use ($modelMorphKey, $tableNames) {
            
            $table->dropIndex('model_has_roles_model_id_model_type_index');
        });
        
        
        DB::statement('ALTER TABLE ' . $tableNames['model_has_roles'] . ' ALTER COLUMN ' . $modelMorphKey . ' TYPE VARCHAR(255) USING ' . $modelMorphKey . '::text');
        
        
        Schema::table($tableNames['model_has_roles'], function (Blueprint $table) use ($modelMorphKey) {
            $table->index([$modelMorphKey, 'model_type'], 'model_has_roles_model_id_model_type_index');
        });

        
        Schema::table($tableNames['model_has_permissions'], function (Blueprint $table) use ($modelMorphKey, $tableNames) {
            
            $table->dropIndex('model_has_permissions_model_id_model_type_index');
        });
        
        
        DB::statement('ALTER TABLE ' . $tableNames['model_has_permissions'] . ' ALTER COLUMN ' . $modelMorphKey . ' TYPE VARCHAR(255) USING ' . $modelMorphKey . '::text');
        
        
        Schema::table($tableNames['model_has_permissions'], function (Blueprint $table) use ($modelMorphKey) {
            $table->index([$modelMorphKey, 'model_type'], 'model_has_permissions_model_id_model_type_index');
        });
    }

    
    public function down(): void
    {
        $tableNames = config('permission.table_names');
        $columnNames = config('permission.column_names');
        $modelMorphKey = $columnNames['model_morph_key'] ?? 'model_id';

        if (empty($tableNames)) {
            throw new \Exception('Error: config/permission.php not loaded.');
        }

        
        Schema::table($tableNames['model_has_roles'], function (Blueprint $table) use ($modelMorphKey, $tableNames) {
            $table->dropIndex('model_has_roles_model_id_model_type_index');
            
            
            DB::statement('ALTER TABLE ' . $tableNames['model_has_roles'] . ' ALTER COLUMN ' . $modelMorphKey . ' TYPE BIGINT USING CASE WHEN ' . $modelMorphKey . ' ~ \'^[0-9]+$\' THEN ' . $modelMorphKey . '::bigint ELSE NULL END');
            
            $table->index([$modelMorphKey, 'model_type'], 'model_has_roles_model_id_model_type_index');
        });

        
        Schema::table($tableNames['model_has_permissions'], function (Blueprint $table) use ($modelMorphKey, $tableNames) {
            $table->dropIndex('model_has_permissions_model_id_model_type_index');
            
            DB::statement('ALTER TABLE ' . $tableNames['model_has_permissions'] . ' ALTER COLUMN ' . $modelMorphKey . ' TYPE BIGINT USING CASE WHEN ' . $modelMorphKey . ' ~ \'^[0-9]+$\' THEN ' . $modelMorphKey . '::bigint ELSE NULL END');
            
            $table->index([$modelMorphKey, 'model_type'], 'model_has_permissions_model_id_model_type_index');
        });
    }
};
