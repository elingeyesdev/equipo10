<?php

namespace App\Observers;

use App\Models\GrupoMiembro;

class GrupoMiembroObserver
{
    public function created(GrupoMiembro $miembro): void
    {
        $miembro->grupo()->increment('miembros_count');
    }

    public function deleted(GrupoMiembro $miembro): void
    {
        $miembro->grupo()->decrement('miembros_count');
    }
}
