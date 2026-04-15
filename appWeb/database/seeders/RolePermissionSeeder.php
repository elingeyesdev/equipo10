<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use App\Models\User;

class RolePermissionSeeder extends Seeder
{
    
    public function run(): void
    {
        
        if (class_exists(\Spatie\Permission\PermissionRegistrar::class)) {
            app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();
        } else {
            \Illuminate\Support\Facades\Cache::forget('spatie.permission.cache');
        }

        
        
        
        
        
        Permission::firstOrCreate(['name' => 'ver usuarios']);
        Permission::firstOrCreate(['name' => 'crear usuarios']);
        Permission::firstOrCreate(['name' => 'editar usuarios']);
        Permission::firstOrCreate(['name' => 'eliminar usuarios']);

        
        Permission::firstOrCreate(['name' => 'ver reportes']);
        Permission::firstOrCreate(['name' => 'crear reportes']);
        Permission::firstOrCreate(['name' => 'editar reportes']);
        Permission::firstOrCreate(['name' => 'eliminar reportes']);

        
        Permission::firstOrCreate(['name' => 'ver categorias']);
        Permission::firstOrCreate(['name' => 'crear categorias']);
        Permission::firstOrCreate(['name' => 'editar categorias']);
        Permission::firstOrCreate(['name' => 'eliminar categorias']);

        
        Permission::firstOrCreate(['name' => 'ver grupos']);
        Permission::firstOrCreate(['name' => 'crear grupos']);
        Permission::firstOrCreate(['name' => 'editar grupos']);
        Permission::firstOrCreate(['name' => 'eliminar grupos']);

        
        Permission::firstOrCreate(['name' => 'administrar sistema']);
        Permission::firstOrCreate(['name' => 'ver configuracion']);
        Permission::firstOrCreate(['name' => 'editar configuracion']);

        
        
        

        
        $adminRole = Role::firstOrCreate(['name' => 'administrador']);
        $adminRole->givePermissionTo(Permission::all());

        
        $editorRole = Role::firstOrCreate(['name' => 'editor']);
        $editorRole->givePermissionTo([
            'ver reportes',
            'crear reportes',
            'editar reportes',
            'eliminar reportes',
            'ver categorias',
            'crear categorias',
            'editar categorias',
            'eliminar categorias',
            'ver grupos',
            'crear grupos',
            'editar grupos',
        ]);

        
        $userRole = Role::firstOrCreate(['name' => 'usuario']);
        $userRole->givePermissionTo([
           
        ]);

        
        
        
        
        
        $adminUser = User::where('email', 'admin@amigate.com')->first();
        if ($adminUser) {
            $adminUser->assignRole('administrador');
            $this->command->info("Rol 'administrador' asignado a: {$adminUser->email}");
        }

        
        // Fix: Use PHP filtering because whereDoesntHave fails in Postgres causing "operator does not exist: bigint = character varying"
        // This happens because model_has_roles.model_id is a string (for UUIDs) but users.id is an integer.
        $users = User::all();
        foreach ($users as $user) {
            if ($user->roles->isEmpty()) {
                $user->assignRole('usuario');
                $this->command->info("Rol 'usuario' asignado a: {$user->email}");
            }
        }

        $this->command->info('✅ Roles y permisos creados exitosamente!');
    }
}
