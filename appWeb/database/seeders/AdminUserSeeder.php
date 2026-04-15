<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Spatie\Permission\Models\Role;

class AdminUserSeeder extends Seeder
{
    
    public function run(): void
    {
        
        if (Role::count() == 0) {
            $this->call(RolePermissionSeeder::class);
        }

        
        $admin = User::firstOrCreate(
            ['email' => 'admin@amigate.com'],
            [
                'name' => 'Administrador',
                'password' => bcrypt('password'), 
            ]
        );

        
        if (!$admin->hasRole('administrador')) {
            $admin->assignRole('administrador');
            $this->command->info('Rol de administrador asignado al usuario admin@amigate.com');
        } else {
            $this->command->info('El usuario ya tiene el rol de administrador');
        }
    }
}
