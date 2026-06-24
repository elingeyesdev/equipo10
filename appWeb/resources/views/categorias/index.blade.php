
@extends('layouts.app')

@section('title', 'Categorías')
@section('page-title', 'Gestión de categorías')

@section('content')

<div class="row mb-4">
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <div class="d-flex align-items-center">
                    <div class="flex-shrink-0">
                        <div class="rounded-circle d-flex align-items-center justify-content-center" style="width:52px;height:52px;background:#3F7AC5;">
                            <i class="bi bi-tags-fill fs-4 text-white"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Total categorías</h6>
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
                        <div class="rounded-circle d-flex align-items-center justify-content-center" style="width:52px;height:52px;background:#16A34A;">
                            <i class="bi bi-check-circle-fill fs-4 text-white"></i>
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
                        <div class="rounded-circle d-flex align-items-center justify-content-center" style="width:52px;height:52px;background:#5388CB;">
                            <i class="bi bi-file-earmark-text-fill fs-4 text-white"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Total reportes</h6>
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
                        <div class="rounded-circle d-flex align-items-center justify-content-center" style="width:52px;height:52px;background:#6796D1;">
                            <i class="bi bi-bar-chart-fill fs-4 text-white"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Promedio/categoría</h6>
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
                    Catálogo de categorías
                </h5>
                <p class="text-muted small mb-0 mt-1">Administra y organiza las categorías del sistema</p>
            </div>
            <div class="col-auto">
                <a href="{{ route('categorias.create') }}" class="btn btn-primary px-4">
                    Nueva categoría
                </a>
            </div>
        </div>
    </div>

    <div class="card-body p-4">
        <div class="row g-4">
            @foreach($categorias as $categoria)
            @php
                $iconosFallback = [
                    'documentos'    => 'file-earmark-text-fill',
                    'electrónicos'  => 'phone-fill',
                    'electronicos'  => 'phone-fill',
                    'llaves'        => 'key-fill',
                    'mascotas'      => 'heart-fill',
                    'otros'         => 'box-fill',
                    'personas'      => 'person-fill',
                    'ropa'          => 'bag-fill',
                    'joyería'       => 'gem',
                    'joyeria'       => 'gem',
                    'vehículos'     => 'car-front-fill',
                    'vehiculos'     => 'car-front-fill',
                    'deportes'      => 'trophy-fill',
                    'libros'        => 'book-fill',
                    'dinero'        => 'cash-coin',
                    'tarjetas'      => 'credit-card-fill',
                ];
                $nombreLower = mb_strtolower($categoria->nombre);
                $iconoCategoria = $categoria->icono ?: ($iconosFallback[$nombreLower] ?? 'tag-fill');
            @endphp
            <div class="col-xl-4 col-lg-6">
                <div class="card border h-100 shadow-sm hover-shadow">
                    <div class="card-body p-4">
                        <div class="d-flex align-items-center mb-3">
                            <div class="rounded-circle d-flex align-items-center justify-content-center me-3 flex-shrink-0" style="width:48px;height:48px;background-color:{{ $categoria->color }};">
                                <i class="bi bi-{{ $iconoCategoria }} fs-5 text-white"></i>
                            </div>
                            <div>
                                <h5 class="mb-1 fw-bold" style="font-size:1.1rem;">{{ $categoria->nombre }}</h5>
                                @if($categoria->activo)
                                    <span class="badge" style="background:#3F7AC5;color:white;">Activo</span>
                                @else
                                    <span class="badge" style="background:#EF4444;color:white;">Inactivo</span>
                                @endif
                            </div>
                        </div>

                        <p class="text-muted mb-3" style="font-size:0.95rem;">{{ $categoria->descripcion }}</p>

                        <div class="d-flex align-items-center justify-content-between">
                            <div class="d-flex align-items-center text-muted small">
                                <i class="bi bi-file-earmark-text me-2"></i>
                                <span class="fw-semibold">{{ $categoria->reportes_count }}</span>
                                <span class="ms-1">{{ $categoria->reportes_count == 1 ? 'reporte' : 'reportes' }}</span>
                            </div>
                            <span class="badge rounded-pill text-white" style="background-color: {{ $categoria->color }}; padding: 0.5rem 0.75rem;">
                                {{ $categoria->reportes_count }}
                            </span>
                        </div>
                    </div>

                    <div class="card-footer bg-light border-0 p-3">
                        <div class="d-flex gap-2">
                            <a href="{{ route('categorias.show', $categoria->id) }}"
                               class="btn flex-fill" style="background:#5388CB;color:white;font-weight:600;">
                                Ver
                            </a>
                            <a href="{{ route('categorias.edit', $categoria->id) }}"
                               class="btn flex-fill" style="background:#E9C978;color:#2B333D;font-weight:600;">
                                Editar
                            </a>
                            <form action="{{ route('categorias.destroy', $categoria->id) }}"
                                  method="POST"
                                  class="flex-fill"
                                  onsubmit="return confirmarEliminacion(this)">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="btn w-100" style="background:#EF4444;color:white;font-weight:600;">
                                    Eliminar
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
                Crear categoría
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
</style>
@endsection
