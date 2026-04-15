
@extends('layouts.app')

@section('title', 'Grupos')
@section('page-title', 'Grupos de Comunidad')

@section('content')
<div class="container-fluid">
    
    <div class="row mb-4">
        <div class="col-md-8">
            <div class="input-group">
                <span class="input-group-text"><i class="bi bi-search"></i></span>
                <input type="text" class="form-control" id="searchGrupos" placeholder="Buscar grupos por nombre o cuadrante...">
            </div>
        </div>
        <div class="col-md-4">
            <select class="form-select" id="filterTipo">
                <option value="todos">Todos los grupos</option>
                <option value="publicos">Públicos</option>
                <option value="privados">Privados</option>
            </select>
        </div>
    </div>

    
    <div class="row" id="gruposGrid">
        @forelse($grupos as $grupo)
        <div class="col-xl-3 col-lg-4 col-md-6 mb-4 grupo-card" data-tipo="{{ $grupo->publico ? 'publicos' : 'privados' }}">
            <a href="{{ route('grupos.show', $grupo->id) }}" class="text-decoration-none">
                <div class="card h-100 shadow-sm hover-card">
                    
                    <div class="position-relative">
                        @if($grupo->imagen_url)
                            <img src="{{ $grupo->imagen_url }}" class="card-img-top" alt="{{ $grupo->nombre }}" style="height: 180px; object-fit: cover;">
                        @else
                            <div class="card-img-top bg-gradient-primary d-flex align-items-center justify-content-center" style="height: 180px;">
                                <div class="text-white" style="font-size: 60px; font-weight: bold;">
                                    {{ substr($grupo->nombre, 0, 2) }}
                                </div>
                            </div>
                        @endif
                        
                        
                        <div class="position-absolute top-0 end-0 m-2">
                            @if($grupo->publico)
                                <span class="badge bg-success"><i class="bi bi-unlock"></i> Público</span>
                            @else
                                <span class="badge bg-warning text-dark"><i class="bi bi-lock"></i> Privado</span>
                            @endif
                        </div>

                        
                        <div class="position-absolute bottom-0 start-0 m-2">
                            <span class="badge bg-dark bg-opacity-75">
                                <i class="bi bi-people"></i> {{ $grupo->miembros_count }} miembros
                            </span>
                        </div>
                    </div>

                    <div class="card-body">
                        
                        <h5 class="card-title mb-2 text-dark">{{ Str::limit($grupo->nombre, 40) }}</h5>
                        
                        
                        <p class="text-muted mb-2 small">
                            <i class="bi bi-geo-alt"></i> {{ $grupo->cuadrante->codigo }} - {{ Str::limit($grupo->cuadrante->nombre, 30) }}
                        </p>

                        
                        @if($grupo->descripcion)
                        <p class="card-text text-muted small mb-3">
                            {{ Str::limit($grupo->descripcion, 80) }}
                        </p>
                        @endif

                        
                        <div class="d-flex justify-content-between align-items-center mb-2">
                            <div>
                                <span class="badge bg-warning text-dark">
                                    <i class="bi bi-exclamation-circle"></i> {{ $grupo->reportes_activos_count }}
                                </span>
                                <span class="badge bg-success">
                                    <i class="bi bi-check-circle"></i> {{ $grupo->reportes_resueltos_count }}
                                </span>
                            </div>
                            <small class="text-muted">
                                {{ $grupo->created_at->diffForHumans() }}
                            </small>
                        </div>

                        
                        <div class="d-flex align-items-center mt-3">
                            <div class="d-flex">
                                @foreach($grupo->miembros->take(4) as $miembro)
                                <div class="avatar-stack" style="margin-left: {{ $loop->first ? '0' : '-8px' }}; z-index: {{ 4 - $loop->index }};">
                                    @if($miembro->avatar_url)
                                        <img src="{{ $miembro->avatar_url }}" alt="{{ $miembro->nombre }}" class="rounded-circle border border-2 border-white" style="width: 30px; height: 30px; object-fit: cover;" title="{{ $miembro->nombre }}">
                                    @else
                                        <div class="bg-secondary text-white rounded-circle border border-2 border-white d-flex align-items-center justify-content-center" style="width: 30px; height: 30px; font-size: 12px;" title="{{ $miembro->nombre }}">
                                            {{ substr($miembro->nombre, 0, 1) }}
                                        </div>
                                    @endif
                                </div>
                                @endforeach
                                
                                @if($grupo->miembros_count > 4)
                                <div class="avatar-stack bg-light text-muted rounded-circle border border-2 border-white d-flex align-items-center justify-content-center" style="margin-left: -8px; width: 30px; height: 30px; font-size: 10px;">
                                    +{{ $grupo->miembros_count - 4 }}
                                </div>
                                @endif
                            </div>
                        </div>
                    </div>

                    
                    <div class="card-footer bg-transparent border-top-0">
                        <div class="d-grid">
                            <button class="btn btn-primary btn-sm">
                                <i class="bi bi-arrow-right-circle"></i> Ver Grupo
                            </button>
                        </div>
                    </div>
                </div>
            </a>
        </div>
        @empty
        <div class="col-12">
            <div class="text-center py-5">
                <i class="bi bi-people display-1 text-muted"></i>
                <h4 class="text-muted mt-3">No hay grupos disponibles</h4>
                <p class="text-muted">Crea el primer grupo de tu comunidad</p>
            </div>
        </div>
        @endforelse
    </div>

    
    @if($grupos->hasPages())
    <div class="row mt-4">
        <div class="col-12">
            <div class="d-flex justify-content-center align-items-center gap-2">
                
                @if($grupos->onFirstPage())
                    <span class="btn btn-outline-secondary disabled">Anterior</span>
                @else
                    <a href="{{ $grupos->previousPageUrl() }}" class="btn btn-outline-primary">Anterior</a>
                @endif
                
                
                <span class="text-muted">
                    Página {{ $grupos->currentPage() }} de {{ $grupos->lastPage() }}
                </span>
                
                
                @if($grupos->hasMorePages())
                    <a href="{{ $grupos->nextPageUrl() }}" class="btn btn-outline-primary">Siguiente</a>
                @else
                    <span class="btn btn-outline-secondary disabled">Siguiente</span>
                @endif
            </div>
        </div>
    </div>
    @endif
</div>
@endsection

@push('styles')
<style>
.hover-card {
    transition: all 0.3s ease;
    cursor: pointer;
}

.hover-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.15) !important;
}

.bg-gradient-primary {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.avatar-stack {
    position: relative;
    display: inline-block;
}

.grupo-card {
    transition: opacity 0.3s ease;
}

/* Estilos para las cards al hacer hover */
.card {
    overflow: hidden;
}

.card-img-top {
    transition: transform 0.3s ease;
}

.hover-card:hover .card-img-top {
    transform: scale(1.05);
}

/* Estilos para la paginación personalizada */
.pagination-custom {
    display: flex;
    align-items: center;
    gap: 1rem;
}

.pagination-custom .btn {
    min-width: 100px;
    font-weight: 500;
}

.pagination-custom .btn:disabled,
.pagination-custom .btn.disabled {
    opacity: 0.5;
    cursor: not-allowed;
}

/* Responsive */
@media (max-width: 768px) {
    .col-md-6 {
        padding-left: 10px;
        padding-right: 10px;
    }
    
    .pagination .page-link {
        padding: 0.25rem 0.5rem;
        font-size: 0.75rem;
    }
    
    .pagination .page-link i,
    .pagination .page-link svg {
        font-size: 0.75rem;
        width: 0.75rem;
        height: 0.75rem;
    }
    
    .pagination .page-item .page-link {
        min-width: 32px;
        height: 32px;
    }
}
</style>
@endpush

@push('scripts')
<script>
document.addEventListener('DOMContentLoaded', function() {
    // Búsqueda de grupos
    const searchInput = document.getElementById('searchGrupos');
    const filterSelect = document.getElementById('filterTipo');
    const grupoCards = document.querySelectorAll('.grupo-card');

    function filterGrupos() {
        const searchTerm = searchInput.value.toLowerCase();
        const filterValue = filterSelect.value;

        grupoCards.forEach(card => {
            const cardText = card.textContent.toLowerCase();
            const cardTipo = card.dataset.tipo;
            
            const matchesSearch = cardText.includes(searchTerm);
            const matchesFilter = filterValue === 'todos' || cardTipo === filterValue;

            if (matchesSearch && matchesFilter) {
                card.style.display = 'block';
                card.style.opacity = '1';
            } else {
                card.style.display = 'none';
                card.style.opacity = '0';
            }
        });
    }

    searchInput.addEventListener('input', filterGrupos);
    filterSelect.addEventListener('change', filterGrupos);
});
</script>
@endpush