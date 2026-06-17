<?php

namespace App\Providers;

use App\Models\GrupoMiembro;
use App\Observers\GrupoMiembroObserver;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\URL;

class AppServiceProvider extends ServiceProvider
{
    
    public function register(): void
    {
        
    }

    
    public function boot(): void
    {
        if (env('APP_ENV') !== 'local') {
            URL::forceScheme('https');
        }

        GrupoMiembro::observe(GrupoMiembroObserver::class);
    }
}
