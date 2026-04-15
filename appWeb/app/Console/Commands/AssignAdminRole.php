<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;

class AssignAdminRole extends Command
{
    
    protected $signature = 'user:assign-admin {email}';

    
    protected $description = 'Asignar rol de administrador a un usuario por email';

    
    public function handle()
    {
        $email = $this->argument('email');
        
        $user = User::where('email', $email)->first();
        
        if (!$user) {
            $this->error("Usuario con email '{$email}' no encontrado.");
            return 1;
        }
        
        if ($user->hasRole('administrador')) {
            $this->warn("El usuario '{$email}' ya tiene el rol de administrador.");
            return 0;
        }
        
        $user->assignRole('administrador');
        
        $this->info("✅ Rol 'administrador' asignado correctamente a: {$email}");
        
        return 0;
    }
}



