
@extends('layouts.app')

@section('title', 'Ver Reporte')

@section('content')
<style>
    /* Custom "Llamativo" Styles */
    .report-header {
        background: linear-gradient(135deg, #1e3a8a 0%, #2563eb 100%);
        border-radius: 16px;
        padding: 2rem;
        color: white;
        margin-bottom: 2rem;
        box-shadow: 0 10px 30px rgba(37, 99, 235, 0.2);
        position: relative;
        overflow: hidden;
    }
    
    .report-header::after {
        content: '';
        position: absolute;
        top: 0;
        right: 0;
        width: 300px;
        height: 100%;
        background: radial-gradient(circle, rgba(255,255,255,0.1) 0%, rgba(255,255,255,0) 70%);
        transform: translate(50%, -50%);
    }

    .info-card {
        background: white;
        border-radius: 16px;
        border: 1px solid rgba(0,0,0,0.05);
        box-shadow: 0 4px 20px rgba(0,0,0,0.02);
        height: 100%;
        transition: transform 0.2s ease, box-shadow 0.2s ease;
    }

    .info-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 10px 25px rgba(0,0,0,0.05);
    }

    .info-label {
        color: #64748b;
        font-size: 0.85rem;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        margin-bottom: 0.25rem;
    }

    .info-value {
        font-size: 1.1rem;
        font-weight: 600;
        color: #1e293b;
    }

    .reward-banner {
        background: linear-gradient(135deg, #059669 0%, #10b981 100%);
        color: white;
        border-radius: 12px;
        padding: 1.5rem;
        text-align: center;
        margin-bottom: 2rem;
        box-shadow: 0 10px 20px rgba(16, 185, 129, 0.2);
    }

    /* Custom Scrollbar for Timeline */
    .timeline-container {
        max-height: 500px;
        overflow-y: auto;
        padding-right: 10px;
        scrollbar-width: thin;
        scrollbar-color: #cbd5e1 transparent;
    }
    
    .timeline-container::-webkit-scrollbar {
        width: 6px;
    }
    
    .timeline-container::-webkit-scrollbar-track {
        background: transparent;
    }
    
    .timeline-container::-webkit-scrollbar-thumb {
        background-color: #cbd5e1;
        border-radius: 20px;
        border: 2px solid transparent;
        background-clip: content-box;
    }

    .timeline-container::-webkit-scrollbar-thumb:hover {
        background-color: #94a3b8;
    }

    .timeline-enhanced {
        position: relative;
        padding-left: 1.5rem; /* Reduced padding for tighter look */
        padding-top: 0.5rem;
    }

    .timeline-enhanced::before {
        content: '';
        position: absolute;
        left: 0.85rem; /* Adjusted for tighter layout */
        top: 15px;
        bottom: 0;
        width: 2px;
        background: linear-gradient(to bottom, #cbd5e1 0%, rgba(203, 213, 225, 0.1) 100%); /* Fade out line */
    }

    .timeline-node {
        position: absolute;
        left: 0;
        top: 0;
        width: 28px; /* Slightly smaller nodes */
        height: 28px;
        border-radius: 50%;
        background: white;
        border: 2px solid #e2e8f0;
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 2;
        font-size: 0.8rem; /* Smaller icon */
    }
    
    .timeline-item-content {
        transition: background-color 0.2s;
        border-left: 2px solid transparent; /* Highlight indicator placeholder */
    }
    
    .timeline-item-wrapper:hover .timeline-item-content {
        background-color: #f8fafc;
    }
</style>

<div class="container-fluid px-0">
    <!-- Hero Header -->
    <div class="report-header d-flex justify-content-between align-items-center">
        <div>
            <div class="d-flex align-items-center gap-3 mb-2">
                <span class="badge rounded-pill bg-white text-{{ $reporte->tipo_reporte == 'perdido' ? 'danger' : 'success' }} px-3 py-2 fw-bold text-uppercase shadow-sm">
                    <i class="bi {{ $reporte->tipo_reporte == 'perdido' ? 'bi-exclamation-circle-fill' : 'bi-check-circle-fill' }} me-1"></i>
                    {{ ucfirst($reporte->tipo_reporte) }}
                </span>
                <span class="text-white-50 small">
                    <i class="bi bi-clock me-1"></i> Publicado {{ $reporte->created_at->diffForHumans() }}
                </span>
            </div>
            <h1 class="fw-bold mb-1">{{ $reporte->titulo }}</h1>
            <p class="mb-0 opacity-75">ID de Reporte: #{{ $reporte->id }}</p>
        </div>
        <div class="d-flex gap-2">
            <a href="{{ route('reportes.edit', $reporte->id) }}" class="btn btn-light bg-white text-primary fw-semibold shadow-sm border-0">
                <i class="bi bi-pencil me-2"></i> Editar
            </a>
            <a href="{{ route('reportes.index') }}" class="btn btn-outline-light fw-semibold">
                <i class="bi bi-arrow-left me-2"></i> Volver
            </a>
        </div>
    </div>

    @if($reporte->recompensa)
    <div class="row mb-4">
        <div class="col-12">
            <div class="reward-banner">
                <h5 class="mb-0 text-white fw-bold"><i class="bi bi-cash-coin me-2 fs-4"></i> SE OFRECE RECOMPENSA</h5>
                <h2 class="fw-bold my-2 display-6">Bs. {{ number_format($reporte->recompensa, 2) }}</h2>
                <small class="opacity-90">Si tienes información, contáctanos inmediatamente.</small>
            </div>
        </div>
    </div>
    @endif

    <div class="row g-4 align-items-stretch">
        <!-- Columna Izquierda: Información Principal -->
        <div class="col-lg-8 d-flex flex-column">
            <div class="card border-0 shadow-sm rounded-4 mb-4 flex-grow-1 d-flex flex-column">
                <div class="card-body p-4">
                    <h5 class="fw-bold text-primary mb-4 border-bottom pb-2">
                        <i class="bi bi-info-circle-fill me-2"></i> Detalles del Caso
                    </h5>
                    
                    <div class="row g-4 mb-4">
                        <div class="col-md-6">
                            <div class="info-card p-3">
                                <label class="info-label"><i class="bi bi-tag-fill me-1 text-primary"></i> Categoría</label>
                                <div class="d-flex align-items-center mt-1">
                                    <span class="badge rounded-pill px-3 py-2" style="background-color: {{ $reporte->categoria->color }}; color: white; text-shadow: 0 1px 2px rgba(0,0,0,0.2);">
                                        {{ $reporte->categoria->nombre }}
                                    </span>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="info-card p-3">
                                <label class="info-label"><i class="bi bi-person-badge-fill me-1 text-primary"></i> Reportado por</label>
                                <div class="info-value mt-1">{{ $reporte->usuario->nombre }}</div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="info-card p-3">
                                <label class="info-label"><i class="bi bi-geo-fill me-1 text-primary"></i> Cuadrante</label>
                                <div class="info-value mt-1">{{ $reporte->cuadrante->codigo }}</div>
                                <small class="text-muted">{{ $reporte->cuadrante->nombre }}</small>
                                
                                @if($reporte->cuadrante_sugerido && $reporte->cuadrante_sugerido->id !== $reporte->cuadrante->id)
                                    <div class="alert alert-warning mt-2 mb-0 py-2 px-3 small border-0 bg-warning-subtle text-warning-emphasis">
                                        <i class="bi bi-exclamation-triangle-fill me-1"></i>
                                        Sugerido: <strong>{{ $reporte->cuadrante_sugerido->codigo }}</strong>
                                    </div>
                                @endif
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="info-card p-3">
                                <label class="info-label"><i class="bi bi-stoplights-fill me-1 text-primary"></i> Estado y Prioridad</label>
                                <div class="d-flex gap-2 mt-2">
                                    @switch($reporte->estado)
                                        @case('activo')
                                            <span class="badge bg-primary-subtle text-primary border border-primary-subtle px-3 py-2 rounded-3 text-uppercase fw-bold">Activo</span>
                                            @break
                                        @case('resuelto')
                                            <span class="badge bg-success-subtle text-success border border-success-subtle px-3 py-2 rounded-3 text-uppercase fw-bold">Resuelto</span>
                                            @break
                                        @default
                                            <span class="badge bg-secondary-subtle text-secondary border border-secondary-subtle px-3 py-2 rounded-3 text-uppercase fw-bold">{{ ucfirst($reporte->estado) }}</span>
                                    @endswitch

                                    @switch($reporte->prioridad)
                                        @case('urgente')
                                            <span class="badge bg-danger text-white px-3 py-2 rounded-3 text-uppercase fw-bold shadow-sm d-flex align-items-center">
                                                <i class="bi bi-fire me-1"></i> Urgente
                                            </span>
                                            @break
                                        @case('alta')
                                            <span class="badge bg-warning text-dark px-3 py-2 rounded-3 text-uppercase fw-bold">Alta</span>
                                            @break
                                        @case('normal')
                                            <span class="badge bg-info text-white px-3 py-2 rounded-3 text-uppercase fw-bold">Normal</span>
                                            @break
                                        @default
                                            <span class="badge bg-light text-dark border px-3 py-2 rounded-3 text-uppercase fw-bold">Baja</span>
                                    @endswitch
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="mb-4">
                        <label class="info-label mb-2"><i class="bi bi-file-text-fill me-1 text-primary"></i> Descripción del Hecho</label>
                        <div class="p-4 bg-light rounded-4 border-start border-4 border-primary">
                            <p class="mb-0 text-muted" style="font-size: 1.05rem; line-height: 1.6;">
                                {{ $reporte->descripcion }}
                            </p>
                        </div>
                    </div>

                    @if($reporte->direccion_referencia)
                    <div class="mb-4">
                        <label class="info-label mb-2"><i class="bi bi-map-fill me-1 text-primary"></i> Ubicación Exacta</label>
                        <div class="p-3 bg-white border rounded-3 d-flex align-items-center">
                            <div class="bg-light p-2 rounded-circle me-3 text-primary">
                                <i class="bi bi-geo-alt fs-5"></i>
                            </div>
                            <span class="fw-medium text-dark">{{ $reporte->direccion_referencia }}</span>
                        </div>
                    </div>
                    @endif
                </div>
            </div>

            <!-- Carousel Section -->
            @if($reporte->imagenes->count() > 0)
            <div class="card border-0 shadow-sm rounded-4 mb-4">
                <div class="card-body p-0">
                    <div class="img-carousel-container">
                        <div id="carouselReporteImages" class="carousel slide" data-bs-ride="carousel">
                            <div class="carousel-inner">
                                @foreach($reporte->imagenes as $key => $imagen)
                                    <div class="carousel-item {{ $key == 0 ? 'active' : '' }}">
                                        <img src="{{ $imagen->url }}" class="d-block w-100" style="height: 500px; object-fit: cover;" alt="Evidencia gráfica">
                                        <div class="carousel-caption d-none d-md-block p-4" style="background: linear-gradient(to top, rgba(0,0,0,0.8), transparent);">
                                            <h5 class="fw-bold">Evidencia #{{ $key + 1 }}</h5>
                                        </div>
                                    </div>
                                @endforeach
                            </div>
                            @if($reporte->imagenes->count() > 1)
                                <button class="carousel-control-prev" type="button" data-bs-target="#carouselReporteImages" data-bs-slide="prev">
                                    <span class="carousel-control-prev-icon bg-dark rounded-circle p-3 bg-opacity-50" aria-hidden="true"></span>
                                    <span class="visually-hidden">Anterior</span>
                                </button>
                                <button class="carousel-control-next" type="button" data-bs-target="#carouselReporteImages" data-bs-slide="next">
                                    <span class="carousel-control-next-icon bg-dark rounded-circle p-3 bg-opacity-50" aria-hidden="true"></span>
                                    <span class="visually-hidden">Siguiente</span>
                                </button>
                            @endif
                        </div>
                    </div>
                </div>
            </div>
            @endif
        </div>

        <!-- Columna Derecha: Contacto y Timeline -->
        <div class="col-lg-4 d-flex flex-column">
            @if($reporte->contacto_publico)
            <div class="card border-0 shadow-sm rounded-4 mb-4">
                <div class="card-header bg-white border-bottom-0 pt-4 pb-0">
                    <h5 class="fw-bold mb-0 text-primary">
                        <i class="bi bi-telephone-fill me-2"></i> Contacto
                    </h5>
                </div>
                <div class="card-body p-4">
                    <div class="vstack gap-3">
                        @if($reporte->telefono_contacto)
                        <div class="d-flex align-items-center p-3 bg-light rounded-3">
                            <div class="bg-success text-white rounded-circle p-2 me-3 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                                <i class="bi bi-whatsapp"></i>
                            </div>
                            <div>
                                <small class="text-muted d-block fw-bold text-uppercase" style="font-size: 0.7rem;">Teléfono</small>
                                <a href="tel:{{ $reporte->telefono_contacto }}" class="fw-bold text-dark text-decoration-none fs-5">{{ $reporte->telefono_contacto }}</a>
                            </div>
                        </div>
                        @endif
                        @if($reporte->email_contacto)
                        <div class="d-flex align-items-center p-3 bg-light rounded-3">
                            <div class="bg-primary text-white rounded-circle p-2 me-3 d-flex align-items-center justify-content-center" style="width: 40px; height: 40px;">
                                <i class="bi bi-envelope"></i>
                            </div>
                            <div>
                                <small class="text-muted d-block fw-bold text-uppercase" style="font-size: 0.7rem;">Email</small>
                                <a href="mailto:{{ $reporte->email_contacto }}" class="fw-bold text-dark text-decoration-none">{{ $reporte->email_contacto }}</a>
                            </div>
                        </div>
                        @endif
                    </div>
                </div>
            </div>
            @endif

            <div class="card border-0 shadow-sm rounded-4 flex-grow-1 d-flex flex-column">
                <div class="card-header bg-white border-bottom-0 pt-4 pb-0 d-flex justify-content-between align-items-end">
                    <h5 class="fw-bold mb-0 text-primary">
                        <i class="bi bi-hourglass-split me-2"></i> Seguimiento
                    </h5>
                    @if(count($timeline) > 5)
                        <small class="text-muted" style="font-size: 0.75rem;">Desliza para ver más</small>
                    @endif
                </div>
                <div class="card-body p-4 flex-grow-1 d-flex flex-column">
                    <div class="timeline-container">
                        <div class="timeline-enhanced">
                            @foreach($timeline as $evento)
                            <div class="mb-3 position-relative timeline-item-wrapper" style="min-height: 40px;"> <!-- Ensure min-height -->
                                <div class="timeline-node border-{{ $evento['color'] }} shadow-sm">
                                    <i class="bi {{ $evento['icono'] }} text-{{ $evento['color'] }}"></i>
                                </div>
                                <div class="ps-4 ms-3"> <!-- Increased spacing: ps-3 ms-2 -> ps-4 ms-3 -->
                                    <div class="d-flex justify-content-between align-items-center mb-1">
                                        <h6 class="fw-bold mb-0 text-dark small">{{ $evento['titulo'] }}</h6>
                                        <span class="text-muted" style="font-size: 0.7rem;">{{ $evento['fecha']->diffForHumans() }}</span>
                                    </div>
                                    <div class="timeline-item-content p-2 rounded bg-light border-start border-3 border-{{ $evento['color'] }}">
                                        <p class="text-secondary small mb-1" style="line-height: 1.3;">
                                            {{ $evento['descripcion'] }}
                                        </p>
                                        @if($evento['usuario'])
                                            <div class="d-flex align-items-center mt-1">
                                                <i class="bi bi-person-circle me-1 text-muted" style="font-size: 0.7rem;"></i>
                                                <small class="text-muted fst-italic" style="font-size: 0.7rem;">
                                                    {{ $evento['usuario']->nombre }}
                                                </small>
                                            </div>
                                        @endif
                                    </div>
                                </div>
                            </div>
                            @endforeach
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection