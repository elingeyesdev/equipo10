
@extends('layouts.app')

@section('title', 'Ver Reporte')

@section('content')
<style>
    /* Custom "Llamativo" Styles */
    .report-header {
        background-color: #353F4C;
        border-radius: 16px;
        padding: 2rem;
        color: white;
        margin-bottom: 2rem;
        box-shadow: 0 10px 30px rgba(63, 122, 197, 0.2);
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
        color: #2B333D;
    }

    .reward-banner {
        background-color: #16A34A;
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
                <span class="badge rounded-pill px-3 py-2 fw-bold text-uppercase shadow-sm" style="background:{{ $reporte->tipo_reporte == 'perdido' ? '#EF4444' : '#16A34A' }};color:white;">
                    {{ ucfirst($reporte->tipo_reporte) }}
                </span>
                <span class="text-white-50 small">
                    <i class="bi bi-clock me-1"></i> Publicado {{ $reporte->created_at ? $reporte->created_at->diffForHumans() : 'Fecha desconocida' }}
                </span>
            </div>
            <h1 class="fw-bold mb-1">{{ $reporte->titulo }}</h1>
            <p class="mb-0 opacity-75">ID de Reporte: #{{ $reporte->id }}</p>
        </div>
        <div class="d-flex gap-2">
            {{-- Formulario oculto para pausar --}}
            <form action="{{ route('reportes.pausar', $reporte->id) }}" method="POST" class="d-none" id="form-pausar-{{ $reporte->id }}">
                @csrf
                @method('PUT')
            </form>

            @if(auth()->check() && (auth()->id() == $reporte->usuario_id || auth()->user()->hasRole('administrador')))
                @if(in_array($reporte->estado, ['cerrado', 'pausado']))
                    <form action="{{ route('reportes.reanudar', $reporte->id) }}" method="POST" class="d-inline" id="form-reanudar-{{ $reporte->id }}">
                        @csrf
                        @method('PUT')
                        <button type="button" class="btn btn-success fw-semibold shadow-sm border-0" onclick="confirmarReanudar('{{ $reporte->id }}')">
                            Reanudar búsqueda
                        </button>
                    </form>
                @else
                    <button type="button" class="btn btn-info fw-semibold shadow-sm border-0 text-white" onclick="confirmarPausa('{{ $reporte->id }}')">
                        Pausar búsqueda
                    </button>
                    <button type="button" class="btn btn-warning fw-semibold shadow-sm border-0 text-dark" onclick="confirmarCierre('{{ $reporte->id }}')">
                        Cerrar búsqueda
                    </button>
                @endif
            @else
                @if(in_array($reporte->estado, ['cerrado', 'pausado']))
                    <button type="button" class="btn btn-secondary fw-semibold shadow-sm border-0" disabled title="Solo el creador o un admin puede reanudar la búsqueda">
                        Reanudar búsqueda
                    </button>
                @else
                    <button type="button" class="btn btn-secondary fw-semibold shadow-sm border-0" disabled title="Solo el creador o un admin puede gestionar la búsqueda">
                        Pausar búsqueda
                    </button>
                @endif
            @endif

            <a href="{{ route('reportes.edit', $reporte->id) }}" class="btn btn-light bg-white text-primary fw-semibold shadow-sm border-0">
                Editar
            </a>
            <a href="{{ route('reportes.index') }}" class="btn btn-outline-light fw-semibold">
                Volver
            </a>
        </div>
    </div>

    @if($reporte->recompensa)
    <div class="row mb-4">
        <div class="col-12">
            <div class="reward-banner">
                <h5 class="mb-0 text-white fw-bold">Se ofrece recompensa</h5>
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
                        <i class="bi bi-info-circle-fill me-2"></i> Detalles del caso
                    </h5>
                    
                    <div class="row g-4 mb-4">
                        <div class="col-md-6">
                            <div class="info-card p-3">
                                <label class="info-label"><i class="bi bi-tag-fill me-1 text-primary"></i> Categoría</label>
                                <div class="d-flex align-items-center mt-1">
                                    @if($reporte->categoria)
                                        <span class="badge rounded-pill px-3 py-2" style="background-color: {{ $reporte->categoria->color ?? '#6c757d' }}; color: white; text-shadow: 0 1px 2px rgba(0,0,0,0.2);">
                                            {{ $reporte->categoria->nombre }}
                                        </span>
                                    @else
                                        <span class="badge rounded-pill px-3 py-2 bg-secondary text-white">Sin categoría</span>
                                    @endif
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="info-card p-3">
                                <label class="info-label"><i class="bi bi-person-badge-fill me-1 text-primary"></i> Reportado por</label>
                                <div class="info-value mt-1">{{ $reporte->usuario?->nombre ?? 'Desconocido' }}</div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="info-card p-3">
                                <label class="info-label"><i class="bi bi-geo-fill me-1 text-primary"></i> Cuadrante</label>
                                @if($reporte->cuadrante)
                                    <div class="info-value mt-1">{{ $reporte->cuadrante->codigo }}</div>
                                    <small class="text-muted">{{ $reporte->cuadrante->nombre }}</small>
                                    @php $cuadranteSugerido = $reporte->cuadrante_sugerido; @endphp
                                    @if($cuadranteSugerido && $cuadranteSugerido->id !== $reporte->cuadrante->id)
                                        <div class="alert alert-warning mt-2 mb-0 py-2 px-3 small border-0 bg-warning-subtle text-warning-emphasis">
                                            <i class="bi bi-exclamation-triangle-fill me-1"></i>
                                            Sugerido: <strong>{{ $cuadranteSugerido->codigo }}</strong>
                                        </div>
                                    @endif
                                @else
                                    <div class="info-value mt-1 text-muted">Sin cuadrante asignado</div>
                                @endif
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="info-card p-3">
                                <label class="info-label"><i class="bi bi-stoplights-fill me-1 text-primary"></i> Estado</label>
                                <div class="mt-1 d-flex gap-2">
                                    {!! $reporte->badge_estado !!}
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="info-card p-3">
                                <label class="info-label"><i class="bi bi-people-fill me-1 text-primary"></i> Voluntarios Unidos</label>
                                <div class="info-value mt-1">{{ $reporte->voluntarios()->count() }}</div>
                                <small class="text-muted">Resumen estadístico básico</small>
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

                    @if($reporte->ubicacion_exacta_lat && $reporte->ubicacion_exacta_lng)
                    <div class="mb-4 position-relative">
                        <label class="info-label mb-2"><i class="bi bi-map-fill me-1 text-primary"></i> Mapa de Búsqueda y Ubicación</label>
                        
                        <div class="border rounded-4 overflow-hidden shadow-sm" style="position: relative;">
                            <div class="bg-white p-2 border-bottom d-flex justify-content-between align-items-center">
                                <div>
                                    <span class="fw-bold text-primary"><i class="bi bi-pin-map-fill me-1"></i> Puntos de avistamiento</span>
                                </div>
                                <div class="d-flex gap-2">
                                    <!-- Remove Añadir Pista button -->
                                    <button onclick="toggleMapFullscreen()" class="btn btn-light btn-sm border shadow-sm">
                                        <i class="bi bi-arrows-fullscreen"></i>
                                    </button>
                                </div>
                            </div>
                            
                            <!-- Eliminar panel de añadir pista -->
                            
                            <!-- El Mapa -->
                            <div id="mapa-pistas-wrapper" style="position:relative; background: #f8f9fa;">
                                <div id="mapa-pistas" style="height:400px; width:100%;"></div>
                            </div>
                            
                            @if($reporte->direccion_referencia)
                            <div class="bg-white border-top p-3 d-flex align-items-center">
                                <div class="bg-light p-2 rounded-circle me-3 text-primary">
                                    <i class="bi bi-geo-alt fs-5"></i>
                                </div>
                                <span class="fw-medium text-dark">{{ $reporte->direccion_referencia }}</span>
                            </div>
                            @endif
                        </div>
                    </div>
                    @endif
                </div>
            </div>

            <!-- Main Image Section -->
            <div class="card border-0 shadow-sm rounded-4 mb-4 overflow-hidden">
                <div class="position-relative bg-light" style="min-height: 400px;">
                    @if($fotoPrincipal)
                        <img src="{{ $fotoPrincipal }}"
                             alt="{{ $tituloPrincipal }}"
                             class="w-100"
                             style="height: 500px; object-fit: contain; background: #111;">
                    @else
                        <div class="d-flex align-items-center justify-content-center" style="height: 500px;">
                            <div class="text-center text-muted">
                                <i class="bi bi-camera" style="font-size: 3rem;"></i>
                                <p class="mt-2">Sin imagen disponible</p>
                            </div>
                        </div>
                    @endif
                    <div class="position-absolute bottom-0 start-0 w-100 p-4" 
                         style="background: linear-gradient(to top, rgba(0,0,0,0.8), transparent);">
                        <h5 class="text-white fw-bold mb-1">{{ $tituloPrincipal }}</h5>
                        @if($descripcionPrincipal)
                            <p class="text-white-50 mb-1 small">{{ $descripcionPrincipal }}</p>
                        @endif
                        <p class="text-white-50 mb-0 small"><i class="bi bi-clock"></i> {{ $fechaPrincipal }}</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Columna Derecha: Contacto y Timeline o Foco -->
        <div class="col-lg-4 d-flex flex-column">
            @if($foco)
            <!-- â”€â”€â”€ PANEL ENFOCADO â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ -->
            <div class="card border-0 shadow-sm rounded-4 flex-grow-1 d-flex flex-column mb-4 border-top border-4 border-primary">
                <div class="card-header bg-white border-bottom-0 pt-4 pb-0 d-flex justify-content-between align-items-center">
                    <h5 class="fw-bold mb-0 text-primary">
                        <i class="bi bi-search me-2"></i> Detalle Seleccionado
                    </h5>
                    <a href="{{ route('reportes.show', $reporte->id) }}" class="btn btn-sm btn-outline-secondary rounded-pill">
                        <i class="bi bi-arrow-left"></i> Ver Todo
                    </a>
                </div>
                <div class="card-body p-4 d-flex flex-column">
                    <div class="mb-4 text-center">
                        <div class="d-inline-flex align-items-center justify-content-center bg-light text-primary rounded-circle mb-3" style="width: 60px; height: 60px;">
                            <i class="bi {{ in_array($foco->tipo_respuesta, ['avistamiento', 'encontrado']) ? 'bi-camera-video' : 'bi-geo-alt' }} fs-2"></i>
                        </div>
                        <h4 class="fw-bold">{{ in_array($foco->tipo_respuesta, ['avistamiento', 'encontrado']) ? 'Evidencia (Avistamiento)' : 'Pista de Búsqueda' }}</h4>
                        @if(in_array($foco->tipo_respuesta, ['avistamiento', 'encontrado']))
                            @if($foco->estado_evidencia == 'approved')
                                <span class="badge bg-success bg-opacity-10 text-success border border-success border-opacity-25 px-3 py-2 rounded-pill"><i class="bi bi-check-circle-fill me-1"></i>Aprobada</span>
                            @elseif($foco->estado_evidencia == 'rejected')
                                <span class="badge bg-danger bg-opacity-10 text-danger border border-danger border-opacity-25 px-3 py-2 rounded-pill"><i class="bi bi-x-circle-fill me-1"></i>Rechazada</span>
                            @else
                                <span class="badge bg-warning bg-opacity-10 text-warning border border-warning border-opacity-25 px-3 py-2 rounded-pill"><i class="bi bi-hourglass-split me-1"></i>Pendiente</span>
                            @endif
                        @else
                            <span class="badge bg-info bg-opacity-10 text-info border border-info border-opacity-25 px-3 py-2 rounded-pill"><i class="bi bi-info-circle-fill me-1"></i>Información>
                        @endif
                    </div>

                    @if(!in_array($foco->tipo_respuesta, ['avistamiento', 'encontrado']))
                    <div class="bg-light p-3 rounded-4 mb-3">
                        <h6 class="fw-bold text-muted mb-2 text-uppercase" style="font-size: 0.75rem;">Título y Categoría</h6>
                        <p class="fs-5 fw-bold mb-1 text-dark" style="line-height: 1.2;">{{ $foco->titulo }}</p>
                        <span class="badge bg-secondary">{{ $foco->categoria_informacion }}</span>
                    </div>
                    @endif

                    <div class="bg-light p-3 rounded-4 mb-4">
                        <h6 class="fw-bold text-muted mb-2 text-uppercase" style="font-size: 0.75rem;">{{ in_array($foco->tipo_respuesta, ['avistamiento', 'encontrado']) ? 'Mensaje' : 'Descripción' }}</h6>
                        <p class="fs-6 mb-0 text-dark" style="line-height: 1.4;">{{ $foco->mensaje }}</p>
                    </div>

                    <div class="vstack gap-3 mt-auto">
                        <div class="d-flex align-items-center">
                            <div class="bg-white border rounded-circle p-2 me-3 d-flex align-items-center justify-content-center shadow-sm" style="width: 40px; height: 40px;">
                                <i class="bi bi-person text-secondary"></i>
                            </div>
                            <div>
                                <small class="text-muted d-block fw-bold text-uppercase" style="font-size: 0.7rem;">Autor</small>
                                <span class="fw-bold text-dark">{{ $foco->usuario?->nombre ?? 'Anónimo' }}</span>
                            </div>
                        </div>
                        <div class="d-flex align-items-center">
                            <div class="bg-white border rounded-circle p-2 me-3 d-flex align-items-center justify-content-center shadow-sm" style="width: 40px; height: 40px;">
                                <i class="bi bi-calendar3 text-secondary"></i>
                            </div>
                            <div>
                                <small class="text-muted d-block fw-bold text-uppercase" style="font-size: 0.7rem;">Fecha y Hora</small>
                                <span class="fw-bold text-dark">{{ $foco->created_at->format('d/m/Y H:i') }}</span>
                            </div>
                        </div>
                        @if($foco->ubicacion_lat && $foco->ubicacion_lng)
                        <div class="d-flex align-items-center">
                            <div class="bg-white border rounded-circle p-2 me-3 d-flex align-items-center justify-content-center shadow-sm" style="width: 40px; height: 40px;">
                                <i class="bi bi-geo-alt text-secondary"></i>
                            </div>
                            <div>
                                <small class="text-muted d-block fw-bold text-uppercase" style="font-size: 0.7rem;">Ubicación</small>
                                <a href="https://maps.google.com/?q={{ $foco->ubicacion_lat }},{{ $foco->ubicacion_lng }}" target="_blank" class="fw-bold text-primary text-decoration-none">Ver en Google Maps <i class="bi bi-box-arrow-up-right ms-1"></i></a>
                            </div>
                        </div>
                        @endif
                    </div>
                </div>
            </div>
            @else
            <!-- â”€â”€â”€ TIMELINE NORMAL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ -->
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
                                        <span class="text-muted" style="font-size: 0.7rem;">{{ $evento['fecha'] ? $evento['fecha']->diffForHumans() : '' }}</span>
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
            @endif
        </div>
    </div>
</div>

<!-- Nueva Sección: Registro de Evidencias (Voluntarios) -->
<div class="container-fluid px-4 py-2 mt-2">
    <div class="card border-0 shadow-sm rounded-4 mb-4">
        <div class="card-header bg-white border-bottom-0 pt-4 pb-0 d-flex justify-content-between align-items-center">
            <h5 class="fw-bold mb-0 text-primary">
                <i class="bi bi-camera-video me-2"></i> Registro de Evidencias (Voluntarios)
            </h5>
            <span class="badge bg-primary rounded-pill">{{ count($evidenciasVoluntarios) }} registradas</span>
        </div>
        <div class="card-body p-4">
            @if(count($evidenciasVoluntarios) > 0)
                <div class="table-responsive">
                    <table class="table table-hover align-middle">
                        <thead class="table-light">
                            <tr>
                                <th scope="col" class="border-0 rounded-start">Foto</th>
                                <th scope="col" class="border-0">Mensaje</th>
                                <th scope="col" class="border-0">Autor</th>
                                <th scope="col" class="border-0">Estado</th>
                                <th scope="col" class="border-0">Fecha</th>
                                <th scope="col" class="border-0 rounded-end text-end">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($evidenciasVoluntarios as $respuesta)
                                <tr>
                                    <td>
                                        @php
                                            $imgRel = $respuesta->relationLoaded('imagenes') ? $respuesta->getRelation('imagenes') : null;
                                            $imgUrl = $imgRel && $imgRel->count() > 0 ? $imgRel->first()->url : null;
                                            if (!$imgUrl && is_array($respuesta->imagenes) && count($respuesta->imagenes) > 0) {
                                                $first = $respuesta->imagenes[0];
                                                $imgUrl = is_string($first) ? $first : ($first['url'] ?? null);
                                            }
                                        @endphp
                                        @if($imgUrl)
                                            <a href="{{ $imgUrl }}" target="_blank">
                                                <img src="{{ $imgUrl }}" alt="Evidencia" class="rounded object-fit-cover shadow-sm" style="width: 50px; height: 50px; border: 2px solid #e2e8f0;">
                                            </a>
                                        @else
                                            <div class="rounded bg-light d-flex align-items-center justify-content-center text-secondary shadow-sm" style="width: 50px; height: 50px; border: 2px solid #e2e8f0;">
                                                <i class="bi bi-camera-video-off"></i>
                                            </div>
                                        @endif
                                    </td>
                                    <td>
                                        <p class="mb-0 fw-semibold text-dark">{{ Str::limit($respuesta->mensaje, 50) }}</p>
                                        <small class="text-muted text-uppercase" style="font-size: 0.7rem;">{{ $respuesta->tipo_respuesta }}</small>
                                    </td>
                                    <td>
                                        <div class="d-flex align-items-center">
                                            <i class="bi bi-person-circle text-muted me-2 fs-5"></i>
                                            <span class="fw-medium text-dark">{{ $respuesta->usuario?->nombre ?? 'Desconocido' }}</span>
                                        </div>
                                    </td>
                                    <td>
                                        @if($respuesta->estado_evidencia == 'approved')
                                            <span class="badge bg-success bg-opacity-10 text-success border border-success border-opacity-25 px-2 py-1"><i class="bi bi-check-circle-fill me-1"></i>Aprobada</span>
                                        @elseif($respuesta->estado_evidencia == 'rejected')
                                            <span class="badge bg-danger bg-opacity-10 text-danger border border-danger border-opacity-25 px-2 py-1"><i class="bi bi-x-circle-fill me-1"></i>Rechazada</span>
                                        @else
                                            <span class="badge bg-warning bg-opacity-10 text-warning border border-warning border-opacity-25 px-2 py-1"><i class="bi bi-hourglass-split me-1"></i>Pendiente</span>
                                        @endif
                                    </td>
                                    <td>
                                        <small class="text-muted"><i class="bi bi-calendar-event me-1"></i>{{ $respuesta->created_at->format('d/m/Y H:i') }}</small>
                                    </td>
                                    <td class="text-end">
                                        <div class="d-flex gap-1 justify-content-end">
                                            <a href="{{ route('reportes.show', ['reporte' => $reporte->id, 'pista_id' => $respuesta->id]) }}" class="btn btn-sm btn-outline-primary" title="Ver Detalles">
                                                <i class="bi bi-search"></i>
                                            </a>
                                            @if(auth()->user()->hasRole('administrador') || auth()->user()->hasRole('editor') || auth()->user()->id == $reporte->usuario_id)
                                                @if($respuesta->estado_evidencia != 'approved')
                                                <form action="{{ route('reportes.informacion.aprobar', [$reporte->id, $respuesta->id]) }}" method="POST" class="d-inline">
                                                    @csrf
                                                    @method('PUT')
                                                    <button type="submit" class="btn btn-sm btn-outline-success" title="Aprobar Evidencia">
                                                        <i class="bi bi-check-lg"></i>
                                                    </button>
                                                </form>
                                                @endif
                                                @if($respuesta->estado_evidencia != 'rejected')
                                                <form action="{{ route('reportes.informacion.rechazar', [$reporte->id, $respuesta->id]) }}" method="POST" class="d-inline">
                                                    @csrf
                                                    @method('PUT')
                                                    <button type="submit" class="btn btn-sm btn-outline-warning" title="Rechazar Evidencia">
                                                        <i class="bi bi-x-lg"></i>
                                                    </button>
                                                </form>
                                                @endif
                                                <form action="{{ route('reportes.informacion.destroy', [$reporte->id, $respuesta->id]) }}" method="POST" class="d-inline">
                                                    @csrf
                                                    @method('DELETE')
                                                    <button type="button" class="btn btn-sm btn-outline-danger btn-eliminar-informacion" title="Eliminar Evidencia">
                                                        <i class="bi bi-trash-fill"></i>
                                                    </button>
                                                </form>
                                            @endif
                                        </div>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @else
                <div class="text-center py-5 text-muted">
                    <i class="bi bi-inbox fs-1 mb-3 text-light"></i>
                    <h6>No hay evidencias registradas</h6>
                    <p class="small">Las evidencias enviadas por los voluntarios aparecerán aquí.</p>
                </div>
            @endif
        </div>
    </div>
</div>

<!-- Nueva Sección: Registro de Pistas (Admin/Creador) -->
<div class="container-fluid px-4 py-2">
    <div class="card border-0 shadow-sm rounded-4 mb-4">
        <div class="card-header bg-white border-bottom-0 pt-4 pb-0 d-flex justify-content-between align-items-center">
            <h5 class="fw-bold mb-0 text-info">
                <i class="bi bi-geo-alt me-2"></i> Registro de Información (Oficial)
            </h5>
            <span class="badge bg-info rounded-pill">{{ count($pistasAdmin) }} registradas</span>
        </div>
        <div class="card-body p-4">
            @if(count($pistasAdmin) > 0)
                <div class="table-responsive">
                    <table class="table table-hover align-middle">
                        <thead class="table-light">
                            <tr>
                                <th scope="col" class="border-0 rounded-start">Título / Categoría</th>
                                <th scope="col" class="border-0">Descripción</th>
                                <th scope="col" class="border-0">Autor</th>
                                <th scope="col" class="border-0">Fecha</th>
                                <th scope="col" class="border-0 rounded-end text-end">Acciones</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($pistasAdmin as $pista)
                                <tr>
                                    <td>
                                        <p class="mb-0 fw-bold text-dark">{{ Str::limit($pista->titulo, 50) }}</p>
                                        <small class="text-muted text-uppercase" style="font-size: 0.7rem;">{{ $pista->categoria_informacion ?? 'Información' }}</small>
                                    </td>
                                    <td>
                                        <p class="mb-0 text-dark">{{ Str::limit($pista->mensaje, 50) }}</p>
                                    </td>
                                    <td>
                                        <div class="d-flex align-items-center">
                                            <i class="bi bi-person-circle text-muted me-2 fs-5"></i>
                                            <span class="fw-medium text-dark">{{ $pista->usuario?->nombre ?? 'Desconocido' }}</span>
                                        </div>
                                    </td>
                                    <td>
                                        <small class="text-muted"><i class="bi bi-calendar-event me-1"></i>{{ $pista->created_at->format('d/m/Y H:i') }}</small>
                                    </td>
                                    <td class="text-end">
                                        <div class="d-flex gap-1 justify-content-end">
                                            <a href="{{ route('reportes.show', ['reporte' => $reporte->id, 'pista_id' => $pista->id]) }}" class="btn btn-sm btn-outline-info" title="Ver Detalles">
                                                <i class="bi bi-search"></i> Ver
                                            </a>
                                            @if(auth()->user()->hasRole('administrador') || auth()->user()->hasRole('editor') || auth()->user()->id == $reporte->usuario_id)
                                                <!-- Opcional: Modal de editar se puede añadir aquí -->
                                                <button type="button" class="btn btn-sm btn-outline-secondary" title="Editar Información" onclick="editarInformacion('{{ $reporte->id }}', '{{ $pista->id }}', '{{ addslashes($pista->titulo ?? '') }}', '{{ addslashes($pista->mensaje ?? '') }}')">
                                                    <i class="bi bi-pencil-square"></i>
                                                </button>
                                                <form action="{{ route('reportes.informacion.destroy', [$reporte->id, $pista->id]) }}" method="POST" class="d-inline">
                                                    @csrf
                                                    @method('DELETE')
                                                    <button type="button" class="btn btn-sm btn-outline-danger btn-eliminar-informacion" title="Eliminar Información">
                                                        <i class="bi bi-trash-fill"></i>
                                                    </button>
                                                </form>
                                            @endif
                                        </div>
                                    </td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            @else
                <div class="text-center py-5 text-muted">
                    <i class="bi bi-geo fs-1 mb-3 text-light"></i>
                    <h6>No hay pistas oficiales registradas</h6>
                </div>
            @endif
        </div>
    </div>
</div>

{{-- Mapa reubicado arriba --}}

<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<script>
// â”€â”€â”€ Datos del reporte â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const LPP_LAT   = {{ (float) $reporte->ubicacion_exacta_lat }};
const LPP_LNG   = {{ (float) $reporte->ubicacion_exacta_lng }};
const REPORTE_ID = "{{ $reporte->id }}";
const TITULO    = @json($reporte->titulo);
const ESTADO_REPORTE = @json($reporte->estado);
const CREATED_AT = @json($reporte->created_at);
const UPDATED_AT = @json($reporte->updated_at);
const RADIO_BASE = 0.0007; // Mismo radio que en cuadrantes/index

// Calcular nivel dinámico basado en el tiempo (misma fórmula que cuadrantes/index)
function calcularNivelDinamico(fechaStr, fechaFinStr, estado) {
    if (!fechaStr) return 1;
    const fecha = new Date(fechaStr);
    let fin = new Date();
    if ((estado === 'resuelto' || estado === 'encontrado' || estado === 'terminado') && fechaFinStr) {
        fin = new Date(fechaFinStr);
    }
    if (isNaN(fecha) || isNaN(fin)) return 1;
    const diffMinutos = (fin - fecha) / (1000 * 60);
    if (diffMinutos >= 5760) return 10;
    if (diffMinutos >= 4320) return 9;
    if (diffMinutos >= 2880) return 8;
    if (diffMinutos >= 1440) return 7;
    if (diffMinutos >= 720) return 6;
    if (diffMinutos >= 360) return 5;
    if (diffMinutos >= 180) return 4;
    if (diffMinutos >= 60) return 3;
    if (diffMinutos >= 30) return 2;
    return 1;
}
const NIVEL_EXPAN = calcularNivelDinamico(CREATED_AT, UPDATED_AT, ESTADO_REPORTE);
@php
    $pistasJs = $pistas->map(function($p) {
        // Usar relationLoaded para evitar RelationNotFoundException si no se precargó correctamente
        $imagenesRel = $p->relationLoaded('imagenes') ? $p->getRelation('imagenes') : null;
        $img = $imagenesRel && $imagenesRel->count() > 0 ? $imagenesRel->first()->url : null;

        // Fallback: Si no hay en la relación, revisar la columna JSON
        if (!$img && is_array($p->imagenes) && count($p->imagenes) > 0) {
            $firstImg = $p->imagenes[0];
            $img = is_string($firstImg) ? $firstImg : ($firstImg['url'] ?? null);
        }

        return [
            'id'       => $p->id,
            'lat'      => (float) $p->ubicacion_lat,
            'lng'      => (float) $p->ubicacion_lng,
            'etiqueta' => $p->mensaje,
            'fecha'    => $p->created_at ? $p->created_at->format('d/m/Y H:i') : '',
            'nivel_expansion' => $p->nivel_expansion ?? 1,
            'has_image' => $img != null,
            'image_url' => $img,
            'created_at' => $p->created_at ? $p->created_at->toISOString() : null,
        ];
    });

    $tracksJs = [];
    foreach($reporte->voluntarios as $vol) {
        $puntos = $vol->recorrido_puntos;
        
        if (is_string($puntos)) {
            $p = json_decode($puntos, true);
            if (json_last_error() === JSON_ERROR_NONE) $puntos = $p;
        }
        if (is_string($puntos)) {
            $p = json_decode($puntos, true);
            if (json_last_error() === JSON_ERROR_NONE) $puntos = $p;
        }

        if ($puntos && is_array($puntos) && count($puntos) > 0) {
            $tracksJs[] = [
                'nombre' => $vol->usuario?->nombre ?? 'Voluntario',
                'puntos' => $puntos
            ];
        }
    }
@endphp
const PISTAS_BD = @json($pistasJs);
const TRACKING_BD = @json($tracksJs);

// â”€â”€â”€ Estado â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
let mapPistas, modoPista = false, pinTemporal = null;
let latSeleccionada = null, lngSeleccionada = null;

// â”€â”€â”€ Iconos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const iconLPP = L.divIcon({
    className: '',
    html: `<div style="
        width:22px;height:22px;border-radius:50%;
        background:#dc2626;border:3px solid white;
        box-shadow:0 0 0 3px rgba(220,38,38,0.4),0 2px 8px rgba(0,0,0,0.4);
        animation:pulsoRojo 2s infinite;
    "></div>`,
    iconSize:[22,22], iconAnchor:[11,11]
});

const iconPista = L.divIcon({
    className: '',
    html: `<div style="
        width:18px;height:18px;border-radius:50%;
        background:#f59e0b;border:3px solid white;
        box-shadow:0 0 0 3px rgba(245,158,11,0.35),0 2px 8px rgba(0,0,0,0.3);
    "></div>`,
    iconSize:[18,18], iconAnchor:[9,9]
});

const iconEvidencia = L.divIcon({
    className: '',
    html: `<div style="
        width:18px;height:18px;border-radius:50%;
        background:#8B5CF6;border:3px solid white;
        box-shadow:0 0 0 3px rgba(139,92,246,0.35),0 2px 8px rgba(0,0,0,0.3);
    "></div>`,
    iconSize:[18,18], iconAnchor:[9,9]
});

const iconTemporal = L.divIcon({
    className: '',
    html: `<div style="
        width:22px;height:22px;border-radius:50%;
        background:#E9C978;border:3px solid white;
        box-shadow:0 0 0 4px rgba(233,201,120,0.4),0 2px 8px rgba(0,0,0,0.4);
        animation:pulsoMorado 1s infinite;
    "></div>`,
    iconSize:[22,22], iconAnchor:[11,11]
});

// â”€â”€â”€ Init Mapa â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
@if($reporte->ubicacion_exacta_lat && $reporte->ubicacion_exacta_lng)
document.addEventListener('DOMContentLoaded', function() {
    // Inyectar estilos de animación
    const style = document.createElement('style');
    style.textContent = `
        @keyframes pulsoRojo {
            0%   { box-shadow: 0 0 0 0   rgba(220,38,38,0.6), 0 2px 8px rgba(0,0,0,0.4); }
            70%  { box-shadow: 0 0 0 12px rgba(220,38,38,0),   0 2px 8px rgba(0,0,0,0.4); }
            100% { box-shadow: 0 0 0 0   rgba(220,38,38,0),   0 2px 8px rgba(0,0,0,0.4); }
        }
        @keyframes pulsoMorado {
            0%   { box-shadow: 0 0 0 0   rgba(124,58,237,0.7), 0 2px 8px rgba(0,0,0,0.4); }
            70%  { box-shadow: 0 0 0 14px rgba(124,58,237,0),  0 2px 8px rgba(0,0,0,0.4); }
            100% { box-shadow: 0 0 0 0   rgba(124,58,237,0),  0 2px 8px rgba(0,0,0,0.4); }
        }
        #mapa-pistas.modo-pista { cursor: crosshair !important; }
        #mapa-pistas.modo-pista .leaflet-tile-container { filter: brightness(0.92); }
    `;
    document.head.appendChild(style);

    const urlParams = new URLSearchParams(window.location.search);
    const qLat = urlParams.get('lat');
    const qLng = urlParams.get('lng');
    
    let mapCenterLat = LPP_LAT;
    let mapCenterLng = LPP_LNG;
    let mapZoom = 15;

    if (qLat && qLng) {
        mapCenterLat = parseFloat(qLat);
        mapCenterLng = parseFloat(qLng);
        mapZoom = 17;
    }

    mapPistas = L.map('mapa-pistas').setView([mapCenterLat, mapCenterLng], mapZoom);

    // Funciones para Fullscreen
    window.toggleMapFullscreen = function() {
        const wrapper = document.getElementById('mapa-pistas-wrapper');
        const mapDiv = document.getElementById('mapa-pistas');
        
        if (!document.fullscreenElement) {
            if (wrapper.requestFullscreen) {
                wrapper.requestFullscreen();
            } else if (wrapper.webkitRequestFullscreen) {
                wrapper.webkitRequestFullscreen();
            } else if (wrapper.msRequestFullscreen) {
                wrapper.msRequestFullscreen();
            }
            mapDiv.style.height = "100vh";
        } else {
            if (document.exitFullscreen) {
                document.exitFullscreen();
            } else if (document.webkitExitFullscreen) {
                document.webkitExitFullscreen();
            } else if (document.msExitFullscreen) {
                document.msExitFullscreen();
            }
            mapDiv.style.height = "400px";
        }
        setTimeout(() => { mapPistas.invalidateSize(); }, 300);
    }

    document.addEventListener('fullscreenchange', (event) => {
        const mapDiv = document.getElementById('mapa-pistas');
        if (!document.fullscreenElement) {
            mapDiv.style.height = "400px";
        } else {
            mapDiv.style.height = "100vh";
        }
        setTimeout(() => { mapPistas.invalidateSize(); }, 300);
    });

    // Capa satelital por defecto
    const satelital = L.tileLayer(
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
        { attribution: '© Esri' }
    );
    const callejero = L.tileLayer(
        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        { attribution: '© OpenStreetMap' }
    );
    satelital.addTo(mapPistas);
    L.control.layers({'Satelital': satelital, 'Callejero': callejero}).addTo(mapPistas);

    // ——— Marcador LPP (punto original, siempre visible) ————————————————————————————————————
    const tooltipLPP = buildTooltip('Punto de inicio (LPP)', null, '');
    L.marker([LPP_LAT, LPP_LNG], {icon: iconLPP, zIndexOffset: 1000})
     .bindTooltip(tooltipLPP, {permanent: false, direction:'top', offset:[0,-12], className:'leaflet-tooltip-pista'})
     .bindPopup(`<strong>Ultima ubicacion conocida</strong><br><em>${TITULO}</em>`)
     .addTo(mapPistas);

    // ——— Zona de Búsqueda LPP (Desde la BD) —————————————————————————————————————————————————
    dibujarZonaBusqueda(LPP_LAT, LPP_LNG, NIVEL_EXPAN);

    // ——— Marcadores de pistas existentes (BD) —————————————————————————————————————————————————
    PISTAS_BD.forEach(p => {
        // Offset determinista y constante para que no salten
        let hash = p.id ? String(p.id).split('').reduce((a, b) => { a = ((a << 5) - a) + b.charCodeAt(0); return a & a }, 0) : Math.random();
        let latOffset = Math.sin(hash) * 0.0003;
        let lngOffset = Math.cos(hash) * 0.0003;
        agregarMarcadorPista(p.lat + latOffset, p.lng + lngOffset, p.etiqueta, p.fecha, p.nivel_expansion, p.has_image, p.image_url, p.created_at, p.id);
    });

    // ——— Rutas de Tracking de los Voluntarios ————————————————————————————————————————————————
    TRACKING_BD.forEach(track => {
        let pts = track.puntos;
        if (typeof pts === 'string') {
            try { pts = JSON.parse(pts); } catch(e) {}
        }
        if (typeof pts === 'string') {
            try { pts = JSON.parse(pts); } catch(e) {}
        }

        if (Array.isArray(pts) && pts.length > 0) {
            const latlngs = [];
            pts.forEach(pt => {
                if (Array.isArray(pt) && pt.length >= 2) latlngs.push([pt[0], pt[1]]);
                else if (pt && typeof pt === 'object' && pt.lat && pt.lng) latlngs.push([pt.lat, pt.lng]);
            });

            if (latlngs.length > 0) {
                const polyline = L.polyline(latlngs, {
                    color: '#16A34A', // emerald-500
                    weight: 4,
                    opacity: 0.8,
                    dashArray: '10, 10',
                    lineJoin: 'round'
                }).addTo(mapPistas);
                
                polyline.bindTooltip('Ruta: ' + track.nombre, {sticky: true});
            }
        }
    });

    // ——— Clic en el mapa para agregar pista ——————————————————————————————————————————————————
    mapPistas.on('click', function(e) {
        if (!modoPista) return;
        latSeleccionada = e.latlng.lat.toFixed(6);
        lngSeleccionada = e.latlng.lng.toFixed(6);

        // Quitar pin temporal anterior
        if (pinTemporal) mapPistas.removeLayer(pinTemporal);
        pinTemporal = L.marker([latSeleccionada, lngSeleccionada], {icon: iconTemporal}).addTo(mapPistas);

        document.getElementById('coords-status').style.background = '#ede9fe';
        document.getElementById('coords-status').style.borderColor = '#a78bfa';
        document.getElementById('coords-text').innerHTML =
            `<i class="bi bi-check-circle-fill" style="color:#3F7AC5;"></i> &nbsp;${latSeleccionada}, ${lngSeleccionada}`;
        document.getElementById('btn-guardar-pista').disabled = false;
    });
});
@endif

// ——————————————————————————————————————————————————————————————————————————————————————————————————
function buildTooltip(etiqueta, foto, fecha) {
    const fotoHtml = foto
        ? `<img src="${foto}" style="width:48px;height:48px;border-radius:50%;object-fit:cover;border:2px solid #f59e0b;flex-shrink:0;">`
        : `<div style="width:48px;height:48px;border-radius:50%;background:#f1f5f9;display:flex;align-items:center;justify-content:center;flex-shrink:0;border:2px solid #e2e8f0;"><i class="bi bi-person-fill" style="font-size:1.3rem;color:#94a3b8;"></i></div>`;
    return `<div style="display:flex;align-items:center;gap:10px;padding:4px 2px;min-width:180px;max-width:240px;">
        ${fotoHtml}
        <div>
            <div style="font-weight:700;color:#2B333D;font-size:0.85rem;line-height:1.2;">${etiqueta}</div>
            ${fecha ? `<div style="color:#64748b;font-size:0.75rem;margin-top:2px;"><i class="bi bi-clock"></i> ${fecha}</div>` : ''}
        </div>
    </div>`;
}

// ——————————————————————————————————————————————————————————————————————————————————————————————————
function agregarMarcadorPista(lat, lng, etiqueta, fecha, nivel, hasImage, imageUrl, createdAtStr, id) {
    const tooltipHtml = buildTooltip(etiqueta, imageUrl, fecha);
    const mIcon = hasImage ? iconEvidencia : iconPista;
    let popupContent = `<strong>${etiqueta}</strong><br><small class="text-muted">${fecha}</small>`;
    if (id) {
        popupContent += `<br><a href="?pista_id=${id}" class="btn btn-sm btn-outline-primary mt-2 w-100" style="font-size: 10px; padding: 2px 5px;"><i class="bi bi-search"></i> Ver Detalles</a>`;
    }
    L.marker([lat, lng], {icon: mIcon})
     .bindTooltip(tooltipHtml, {
         permanent: false, direction: 'top', offset: [0, -10],
         className: 'leaflet-tooltip-pista',
         opacity: 1
     })
     .bindPopup(popupContent)
     .addTo(mapPistas);
     
    // Las evidencias no tienen cuadrantes ni nivel de expansión, solo son marcadores en el mapa
}

// ——————————————————————————————————————————————————————————————————————————————————————————————————
function dibujarZonaBusqueda(lat, lng, nivel) {
    const radio = RADIO_BASE * nivel;
    const nLat = parseFloat(lat);
    const nLng = parseFloat(lng);
    const bounds = [
        [nLat - radio, nLng - radio],
        [nLat + radio, nLng + radio]
    ];
    
    L.rectangle(bounds, {
        color: "#16A34A",
        weight: 2,
        fillColor: "#10B981",
        fillOpacity: 0.25,
        interactive: false
    }).addTo(mapPistas);
}

// ——————————————————————————————————————————————————————————————————————————————————————————————————
function activarModoPista() {
    modoPista = true;
    document.getElementById('panel-pista').style.display = 'block';
    document.getElementById('mapa-pistas').classList.add('modo-pista');
    document.getElementById('btn-modo-pista').style.display = 'none';
}

function cancelarModoPista() {
    modoPista = false;
    latSeleccionada = null; lngSeleccionada = null;
    document.getElementById('panel-pista').style.display = 'none';
    document.getElementById('mapa-pistas').classList.remove('modo-pista');
    document.getElementById('btn-modo-pista').style.display = 'inline-flex';
    document.getElementById('btn-guardar-pista').disabled = true;
    document.getElementById('coords-text').textContent = 'Haz clic en el mapa para elegir ubicación';
    document.getElementById('coords-status').style.background = '#fef3c7';
    document.getElementById('coords-status').style.borderColor = '#fcd34d';
    if (pinTemporal) { mapPistas.removeLayer(pinTemporal); pinTemporal = null; }
    document.getElementById('pista-msg').innerHTML = '';
}

// ——— Guardar pista vía AJAX ———————————————————————————————————————————————
function guardarPista() {
    if (!latSeleccionada || !lngSeleccionada) return;

    const etiqueta    = document.getElementById('sel-etiqueta').value;
    const cuadranteId = document.getElementById('sel-cuadrante').value;
    const btn         = document.getElementById('btn-guardar-pista');
    const msg         = document.getElementById('pista-msg');

    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Guardando...';

    fetch(`/reportes/${REPORTE_ID}/pistas`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': '{{ csrf_token() }}',
            'Accept': 'application/json'
        },
        body: JSON.stringify({
            lat:          parseFloat(latSeleccionada),
            lng:          parseFloat(lngSeleccionada),
            etiqueta:     etiqueta,
            cuadrante_id: cuadranteId || null
        })
    })
    .then(r => r.json())
    .then(data => {
        if (data.error) {
            msg.innerHTML = `<span class="text-danger"><i class="bi bi-x-circle me-1"></i>${data.error}</span>`;
            btn.disabled = false;
            btn.innerHTML = '<i class="bi bi-cloud-arrow-up-fill me-2"></i>Guardar Pista';
            return;
        }
        // Agregar marcador permanente en el mapa
        const ahora = new Date().toLocaleString('es-BO');
        agregarMarcadorPista(parseFloat(latSeleccionada), parseFloat(lngSeleccionada), etiqueta, ahora);

        // Quitar pin temporal
        if (pinTemporal) { mapPistas.removeLayer(pinTemporal); pinTemporal = null; }

        Swal.fire({
            icon: 'success',
            title: '¡Pista registrada!',
            text: `"${etiqueta}" guardada en el mapa.`,
            timer: 2500,
            showConfirmButton: false,
            toast: true,
            position: 'top-end'
        });

        cancelarModoPista();
    })
    .catch(() => {
        msg.innerHTML = `<span class="text-danger"><i class="bi bi-x-circle me-1"></i>Error de conexión.</span>`;
        btn.disabled = false;
        btn.innerHTML = '<i class="bi bi-cloud-arrow-up-fill me-2"></i>Guardar Pista';
    });
}

// â”€â”€â”€ Confirmar eliminación de pista â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
document.addEventListener('DOMContentLoaded', function() {
    const btnEliminarPista = document.querySelectorAll('.btn-eliminar-informacion');
    btnEliminarPista.forEach(btn => {
        btn.addEventListener('click', function() {
            const form = this.closest('form');
            Swal.fire({
                title: '¿Eliminar evidencia?',
                text: "Esta acción no se puede deshacer y se borrará la foto y el mensaje para siempre.",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#d33',
                cancelButtonColor: '#3085d6',
                confirmButtonText: 'Sí, eliminar',
                cancelButtonText: 'Cancelar'
            }).then((result) => {
                if (result.isConfirmed) {
                    form.submit();
                }
            });
        });
    });
});

function editarInformacion(reporteId, pistaId, tituloActual, mensajeActual) {
    Swal.fire({
        title: 'Editar Información',
        html:
            '<input id="swal-input-titulo" class="swal2-input" placeholder="Título" value="' + tituloActual + '">' +
            '<textarea id="swal-input-mensaje" class="swal2-textarea" placeholder="Descripción">' + mensajeActual + '</textarea>',
        focusConfirm: false,
        showCancelButton: true,
        confirmButtonText: 'Guardar cambios',
        cancelButtonText: 'Cancelar',
        preConfirm: () => {
            const titulo = document.getElementById('swal-input-titulo').value;
            const mensaje = document.getElementById('swal-input-mensaje').value;
            if (!titulo || !mensaje) {
                Swal.showValidationMessage('El título y la descripción son obligatorios');
            }
            return { titulo: titulo, mensaje: mensaje }
        }
    }).then((result) => {
        if (result.isConfirmed) {
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = `/reportes/${reporteId}/informacion/${pistaId}/editar`;
            
            const csrfInput = document.createElement('input');
            csrfInput.type = 'hidden';
            csrfInput.name = '_token';
            csrfInput.value = document.querySelector('input[name="_token"]').value;
            
            const methodInput = document.createElement('input');
            methodInput.type = 'hidden';
            methodInput.name = '_method';
            methodInput.value = 'PUT';

            const tituloInput = document.createElement('input');
            tituloInput.type = 'hidden';
            tituloInput.name = 'titulo';
            tituloInput.value = result.value.titulo;
            
            const msgInput = document.createElement('input');
            msgInput.type = 'hidden';
            msgInput.name = 'mensaje';
            msgInput.value = result.value.mensaje;
            
            form.appendChild(csrfInput);
            form.appendChild(methodInput);
            form.appendChild(tituloInput);
            form.appendChild(msgInput);
            document.body.appendChild(form);
            form.submit();
        }
    });
}
</script>

<style>
.leaflet-tooltip-pista {
    background: white !important;
    border: none !important;
    border-radius: 12px !important;
    box-shadow: 0 4px 20px rgba(0,0,0,0.15) !important;
    padding: 8px 12px !important;
    font-family: 'Segoe UI', system-ui, sans-serif;
}
.leaflet-tooltip-pista::before {
    border-top-color: white !important;
    filter: drop-shadow(0 2px 4px rgba(0,0,0,0.12));
}
</style>
<!-- Formulario oculto para cerrar búsqueda -->
<form id="form-cerrar-{{ $reporte->id }}" action="{{ route('reportes.cerrar', $reporte->id) }}" method="POST" style="display: none;">
    @csrf
    @method('PUT')
    <input type="hidden" name="motivo_cierre" id="input_motivo_cierre_{{ $reporte->id }}">
</form>

<script>
function confirmarPausa(id) {
    Swal.fire({
        title: 'Pausar Búsqueda',
        text: 'La búsqueda quedará suspendida temporalmente. Los voluntarios recibirán una notificación. Puedes reanudarla cuando quieras.',
        icon: 'info',
        showCancelButton: true,
        confirmButtonColor: '#0dcaf0',
        cancelButtonColor: '#6c757d',
        confirmButtonText: '<i class="bi bi-pause-circle"></i> Sí, pausar búsqueda',
        cancelButtonText: 'Cancelar'
    }).then((result) => {
        if (result.isConfirmed) {
            document.getElementById('form-pausar-' + id).submit();
        }
    });
}

function confirmarReanudar(id) {
    Swal.fire({
        title: 'Reanudar Búsqueda',
        text: "Al reanudar esta búsqueda, volverá a estar activa y visible para los voluntarios.",
        icon: 'question',
        showCancelButton: true,
        confirmButtonColor: '#198754',
        cancelButtonColor: '#6c757d',
        confirmButtonText: '<i class="bi bi-play-circle"></i> Confirmar Reanudación',
        cancelButtonText: 'Cancelar'
    }).then((result) => {
        if (result.isConfirmed) {
            document.getElementById('form-reanudar-' + id).submit();
        }
    });
}

function confirmarCierre(id) {
    Swal.fire({
        title: 'Cerrar Búsqueda',
        text: "Al cerrar esta búsqueda, dejará de ser visible para los voluntarios en la app móvil y se les notificará.",
        icon: 'warning',
        input: 'textarea',
        inputLabel: 'Motivo del cierre',
        inputPlaceholder: 'Ej. El operativo fue cancelado por orden superior, o se encontró lo buscado...',
        inputAttributes: {
            'aria-label': 'Motivo del cierre'
        },
        showCancelButton: true,
        confirmButtonColor: '#ffc107',
        cancelButtonColor: '#6c757d',
        confirmButtonText: '<i class="bi bi-check-circle"></i> Confirmar Cierre',
        cancelButtonText: 'Cancelar',
        inputValidator: (value) => {
            if (!value) {
                return '¡Debes ingresar un motivo para el cierre!'
            }
        }
    }).then((result) => {
        if (result.isConfirmed) {
            document.getElementById('input_motivo_cierre_' + id).value = result.value;
            document.getElementById('form-cerrar-' + id).submit();
        }
    });
}
function confirmarEliminacion(id) {
    Swal.fire({
        title: '¿Eliminar permanentemente?',
        text: "Esta acción no se puede deshacer y eliminará todos los registros asociados. Se notificará a los participantes.",
        icon: 'error',
        input: 'textarea',
        inputLabel: 'Motivo de eliminación',
        inputPlaceholder: 'Ej. Reporte falso, spam, duplicado...',
        inputAttributes: {
            'aria-label': 'Motivo de eliminacion'
        },
        showCancelButton: true,
        confirmButtonColor: '#dc3545',
        cancelButtonColor: '#6c757d',
        confirmButtonText: '<i class="bi bi-trash"></i> Sí, eliminar definitivamente',
        cancelButtonText: 'Cancelar',
        inputValidator: (value) => {
            if (!value) {
                return 'Debes ingresar un motivo para la eliminacion';
            }
        }
    }).then((result) => {
        if (result.isConfirmed) {
            const form = document.getElementById('form-eliminar-' + id);
            const motivoInput = document.createElement('input');
            motivoInput.type = 'hidden';
            motivoInput.name = 'motivo_eliminacion';
            motivoInput.value = result.value;
            form.appendChild(motivoInput);
            form.submit();
        }
    });
}
</script>
@endsection
