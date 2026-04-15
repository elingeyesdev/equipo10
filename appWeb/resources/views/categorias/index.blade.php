
@extends('layouts.app')

@section('title', 'Categorías')
@section('page-title', 'Gestión de Categorías')

@section('content')

<div class="row mb-4">
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <div class="d-flex align-items-center">
                    <div class="flex-shrink-0">
                        <div class="rounded-circle bg-primary bg-opacity-10 p-3">
                            <i class="bi bi-tags fs-4 text-primary"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Total Categorías</h6>
                        <h3 class="mb-0 fw-bold">{{ $categorias->count() }}</h3>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <div class="d-flex align-items-center">
                    <div class="flex-shrink-0">
                        <div class="rounded-circle bg-success bg-opacity-10 p-3">
                            <i class="bi bi-check-circle fs-4 text-success"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Activas</h6>
                        <h3 class="mb-0 fw-bold">{{ $categorias->where('activo', true)->count() }}</h3>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <div class="d-flex align-items-center">
                    <div class="flex-shrink-0">
                        <div class="rounded-circle bg-warning bg-opacity-10 p-3">
                            <i class="bi bi-file-earmark-text fs-4 text-warning"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Total Reportes</h6>
                        <h3 class="mb-0 fw-bold">{{ $categorias->sum('reportes_count') }}</h3>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <div class="d-flex align-items-center">
                    <div class="flex-shrink-0">
                        <div class="rounded-circle bg-info bg-opacity-10 p-3">
                            <i class="bi bi-bar-chart fs-4 text-info"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Promedio/Categoría</h6>
                        <h3 class="mb-0 fw-bold">{{ $categorias->count() > 0 ? round($categorias->sum('reportes_count') / $categorias->count(), 1) : 0 }}</h3>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>


<div class="card border-0 shadow-sm">
    <div class="card-header bg-white border-0 py-3">
        <div class="row align-items-center">
            <div class="col">
                <h5 class="mb-0 fw-bold">
                    <i class="bi bi-grid-3x3-gap-fill text-primary me-2"></i>
                    Catálogo de Categorías
                </h5>
                <p class="text-muted small mb-0 mt-1">Administra y organiza las categorías del sistema</p>
            </div>
            <div class="col-auto">
                <a href="{{ route('categorias.create') }}" class="btn btn-primary px-4">
                    <i class="bi bi-plus-circle me-2"></i> Nueva Categoría
                </a>
            </div>
        </div>
    </div>
    
    <div class="card-body p-4">
        <div class="row g-4">
            @foreach($categorias as $categoria)
            <div class="col-xl-4 col-lg-6">
                <div class="card border h-100 shadow-sm hover-shadow transition">
                    <div class="card-body p-4">
                        <div class="d-flex justify-content-between align-items-start mb-3">
                            <div class="flex-grow-1">
                                <div class="d-flex align-items-center mb-3">
                                    <div class="rounded p-2 me-3" style="background-color: {{ $categoria->color }}20;">
                                        <i class="bi bi-{{ $categoria->icono }} fs-4" style="color: {{ $categoria->color }}"></i>
                                    </div>
                                    <div>
                                        <h5 class="mb-0 fw-bold">{{ $categoria->nombre }}</h5>
                                        @if($categoria->activo)
                                            <span class="badge bg-success-subtle text-success border border-success mt-1">
                                                <i class="bi bi-check-circle-fill me-1"></i>Activo
                                            </span>
                                        @else
                                            <span class="badge bg-danger-subtle text-danger border border-danger mt-1">
                                                <i class="bi bi-x-circle-fill me-1"></i>Inactivo
                                            </span>
                                        @endif
                                    </div>
                                </div>
                                
                                <p class="text-muted mb-3 small">{{ $categoria->descripcion }}</p>
                                
                                <div class="d-flex align-items-center">
                                    <div class="flex-grow-1">
                                        <div class="d-flex align-items-center text-muted small">
                                            <i class="bi bi-file-earmark-text me-2"></i>
                                            <span class="fw-semibold">{{ $categoria->reportes_count }}</span>
                                            <span class="ms-1">{{ $categoria->reportes_count == 1 ? 'reporte' : 'reportes' }}</span>
                                        </div>
                                    </div>
                                    <div class="text-end">
                                        <span class="badge rounded-pill" style="background-color: {{ $categoria->color }}; padding: 0.5rem 0.75rem;">
                                            {{ $categoria->reportes_count }}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="card-footer bg-light border-0 p-3">
                        <div class="btn-group w-100" role="group">
                            <a href="{{ route('categorias.show', $categoria->id) }}" 
                               class="btn btn-outline-info btn-sm flex-fill">
                                <i class="bi bi-eye me-1"></i> Ver
                            </a>
                            <a href="{{ route('categorias.edit', $categoria->id) }}" 
                               class="btn btn-outline-warning btn-sm flex-fill">
                                <i class="bi bi-pencil me-1"></i> Editar
                            </a>
                            <form action="{{ route('categorias.destroy', $categoria->id) }}" 
                                  method="POST" 
                                  class="d-inline flex-fill" 
                                  onsubmit="return confirmarEliminacion(this)">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="btn btn-outline-danger btn-sm w-100">
                                    <i class="bi bi-trash me-1"></i> Eliminar
                                </button>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
            @endforeach
        </div>
        
        @if($categorias->isEmpty())
        <div class="text-center py-5">
            <div class="mb-3">
                <i class="bi bi-inbox fs-1 text-muted"></i>
            </div>
            <h5 class="text-muted">No hay categorías registradas</h5>
            <p class="text-muted small">Comienza creando tu primera categoría</p>
            <a href="{{ route('categorias.create') }}" class="btn btn-primary mt-2">
                <i class="bi bi-plus-circle me-2"></i> Crear Categoría
            </a>
        </div>
        @endif
    </div>
</div>

<style>
    .hover-shadow {
        transition: all 0.3s ease;
    }
    
    .hover-shadow:hover {
        transform: translateY(-5px);
        box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.15) !important;
    }
    
    .transition {
        transition: all 0.3s ease;
    }
</style>
@endsection