<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Illuminate\Support\Facades\Auth;

class CheckSiteAccess
{
    
    public function handle(Request $request, Closure $next): Response
    {
        if (Auth::check()) {
            $user = Auth::user();
            
            
            if ($user->hasRole(['administrador', 'editor'])) {
                return $next($request);
            }
            
            
            if ($user->hasRole('usuario') || $user->roles->count() == 0) {
                 
                if ($request->routeIs('restricted')) {
                    return $next($request);
                }
                
                return redirect()->route('restricted');
            }
        }

        return $next($request);
    }
}
