<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Database\Eloquent\Builder as EloquentBuilder;
use Illuminate\Database\Query\Builder as QueryBuilder;

class PermissionServiceProvider extends ServiceProvider
{
    
    public function register(): void
    {
        
    }

    
    public function boot(): void
    {
        
        $reflection = new \ReflectionClass(QueryBuilder::class);
        $originalMethod = $reflection->getMethod('whereIn');
        $originalMethod->setAccessible(true);
        
        QueryBuilder::macro('whereIn', function ($column, $values) use ($originalMethod) {
            
            $normalizedColumn = trim($column, '"\'');
            
            
            if (str_contains($normalizedColumn, 'model_id')) {
                $values = array_map(function ($value) {
                    return (string) $value;
                }, is_array($values) ? $values : (is_iterable($values) ? iterator_to_array($values) : [$values]));
                
                $placeholders = implode(',', array_fill(0, count($values), '?'));
                return $this->whereRaw("CAST({$column} AS VARCHAR) IN ({$placeholders})", $values);
            }
            
            return $originalMethod->invoke($this, $column, $values);
        });
        
        
        \Illuminate\Support\Facades\DB::listen(function ($query) {
            $sql = $query->sql;
            
            
            if (str_contains($sql, 'model_has_roles') && 
                str_contains($sql, 'model_id') && 
                preg_match('/"model_has_roles"\."model_id"\s+in\s*\(/i', $sql)) {
                
                
                $query->sql = preg_replace(
                    '/"model_has_roles"\."model_id"\s+in\s*\(/i',
                    'CAST("model_has_roles"."model_id" AS VARCHAR) IN (',
                    $sql
                );
                
                
                $query->bindings = array_map(function ($binding) {
                    if (is_numeric($binding)) {
                        return (string) $binding;
                    }
                    if (is_array($binding)) {
                        return array_map(function ($b) {
                            return is_numeric($b) ? (string) $b : $b;
                        }, $binding);
                    }
                    return $binding;
                }, $query->bindings);
            }
        });
    }
}
