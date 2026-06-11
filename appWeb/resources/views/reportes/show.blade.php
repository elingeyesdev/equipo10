
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
                    <i class="bi bi-clock me-1"></i> Publicado {{ $reporte->created_at ? $reporte->created_at->diffForHumans() : 'Fecha desconocida' }}
                </span>
            </div>
            <h1 class="fw-bold mb-1">{{ $reporte->titulo }}</h1>
            <p class="mb-0 opacity-75">ID de Reporte: #{{ $reporte->id }}</p>
        </div>
        <div class="d-flex gap-2">
            @if(auth()->check() && (auth()->id() == $reporte->usuario_id || auth()->user()->hasRole('administrador')))
                @if($reporte->estado === 'cerrado')
                    <form action="{{ route('reportes.reanudar', $reporte->id) }}" method="POST" class="d-inline" id="form-reanudar-{{ $reporte->id }}">
                        @csrf
                        @method('PUT')
                        <button type="button" class="btn btn-success fw-semibold shadow-sm border-0" onclick="confirmarReanudar('{{ $reporte->id }}')">
                            <i class="bi bi-play-circle me-1"></i> Reanudar Búsqueda
                        </button>
                    </form>
                @else
                    <button type="button" class="btn btn-warning fw-semibold shadow-sm border-0 text-dark" onclick="confirmarCierre('{{ $reporte->id }}')">
                        <i class="bi bi-x-circle me-1"></i> Cerrar Búsqueda
                    </button>
                @endif
            @else
                @if($reporte->estado === 'cerrado')
                    <button type="button" class="btn btn-secondary fw-semibold shadow-sm border-0" disabled title="Solo el creador o un admin puede reanudar la búsqueda">
                        <i class="bi bi-play-circle me-1"></i> Reanudar Búsqueda
                    </button>
                @else
                    <button type="button" class="btn btn-secondary fw-semibold shadow-sm border-0" disabled title="Solo el creador o un admin puede cerrar la búsqueda">
                        <i class="bi bi-x-circle me-1"></i> Cerrar Búsqueda
                    </button>
                @endif
            @endif

            @if(auth()->check() && auth()->user()->hasRole('administrador'))
                <form action="{{ route('reportes.destroy', $reporte->id) }}" method="POST" class="d-inline" id="form-eliminar-{{ $reporte->id }}">
                    @csrf
                    @method('DELETE')
                    <button type="button" class="btn btn-danger fw-semibold shadow-sm border-0" onclick="confirmarEliminacion('{{ $reporte->id }}')">
                        <i class="bi bi-trash me-1"></i> Eliminar
                    </button>
                </form>
            @endif

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
                                <div class="info-value mt-1">{{ $reporte->usuario->nombre ?? 'Desconocido' }}</div>
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
                             style="height: 500px; object-fit: cover;">
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
        </div>
    </div>
</div>

{{-- Mapa reubicado arriba --}}

<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<script>
// ─── Datos del reporte ────────────────────────────────────────────────────────
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
@endphp
const PISTAS_BD = @json($pistasJs);

// ─── Estado ───────────────────────────────────────────────────────────────────
let mapPistas, modoPista = false, pinTemporal = null;
let latSeleccionada = null, lngSeleccionada = null;

// ─── Iconos ───────────────────────────────────────────────────────────────────
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
        background:#7c3aed;border:3px solid white;
        box-shadow:0 0 0 4px rgba(124,58,237,0.4),0 2px 8px rgba(0,0,0,0.4);
        animation:pulsoMorado 1s infinite;
    "></div>`,
    iconSize:[22,22], iconAnchor:[11,11]
});

// ─── Init Mapa ────────────────────────────────────────────────────────────────
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

    // ── Marcador LPP (punto original, siempre visible) ──────────────────────
    const tooltipLPP = buildTooltip('Punto de inicio (LPP)', null, '');
    L.marker([LPP_LAT, LPP_LNG], {icon: iconLPP, zIndexOffset: 1000})
     .bindTooltip(tooltipLPP, {permanent: false, direction:'top', offset:[0,-12], className:'leaflet-tooltip-pista'})
     .bindPopup(`<strong>Ultima ubicacion conocida</strong><br><em>${TITULO}</em>`)
     .addTo(mapPistas);

    // ── Zona de Búsqueda LPP (Desde la BD) ───────────────────────────────
    dibujarZonaBusqueda(LPP_LAT, LPP_LNG, NIVEL_EXPAN);

    // ── Marcadores de pistas existentes (BD) ────────────────────────────────
    PISTAS_BD.forEach(p => agregarMarcadorPista(p.lat, p.lng, p.etiqueta, p.fecha, p.nivel_expansion, p.has_image, p.image_url, p.created_at));

    // ── Clic en el mapa para agregar pista ──────────────────────────────────
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
            `<i class="bi bi-check-circle-fill" style="color:#7c3aed;"></i> &nbsp;${latSeleccionada}, ${lngSeleccionada}`;
        document.getElementById('btn-guardar-pista').disabled = false;
    });
});
@endif

// ─── Construir tooltip bonito con foto ────────────────────────────────────────
function buildTooltip(etiqueta, foto, fecha) {
    const fotoHtml = foto
        ? `<img src="${foto}" style="width:48px;height:48px;border-radius:50%;object-fit:cover;border:2px solid #f59e0b;flex-shrink:0;">`
        : `<div style="width:48px;height:48px;border-radius:50%;background:#f1f5f9;display:flex;align-items:center;justify-content:center;flex-shrink:0;border:2px solid #e2e8f0;"><i class="bi bi-person-fill" style="font-size:1.3rem;color:#94a3b8;"></i></div>`;
    return `<div style="display:flex;align-items:center;gap:10px;padding:4px 2px;min-width:180px;max-width:240px;">
        ${fotoHtml}
        <div>
            <div style="font-weight:700;color:#1e293b;font-size:0.85rem;line-height:1.2;">${etiqueta}</div>
            ${fecha ? `<div style="color:#64748b;font-size:0.75rem;margin-top:2px;"><i class="bi bi-clock"></i> ${fecha}</div>` : ''}
        </div>
    </div>`;
}

// ─── Agregar marcador de pista al mapa ────────────────────────────────────────
function agregarMarcadorPista(lat, lng, etiqueta, fecha, nivel, hasImage, imageUrl, createdAtStr) {
    const tooltipHtml = buildTooltip(etiqueta, imageUrl, fecha);
    const mIcon = hasImage ? iconEvidencia : iconPista;
    L.marker([lat, lng], {icon: mIcon})
     .bindTooltip(tooltipHtml, {
         permanent: false, direction: 'top', offset: [0, -10],
         className: 'leaflet-tooltip-pista',
         opacity: 1
     })
     .bindPopup(`<strong>${etiqueta}</strong><br><small class="text-muted">${fecha}</small>`)
     .addTo(mapPistas);
     
    // Las evidencias no tienen cuadrantes ni nivel de expansión, solo son marcadores en el mapa
}

// ─── Dibujar cuadrado verde de búsqueda ──────────────────────────────────────
function dibujarZonaBusqueda(lat, lng, nivel) {
    const radio = RADIO_BASE * nivel;
    const nLat = parseFloat(lat);
    const nLng = parseFloat(lng);
    const bounds = [
        [nLat - radio, nLng - radio],
        [nLat + radio, nLng + radio]
    ];
    
    L.rectangle(bounds, {
        color: "#059669",
        weight: 2,
        fillColor: "#10B981",
        fillOpacity: 0.25,
        interactive: false
    }).addTo(mapPistas);
}

// ─── Activar/Cancelar modo pista ─────────────────────────────────────────────
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

// ─── Guardar pista vía AJAX ───────────────────────────────────────────────────
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
        inputValidator: (value) => {
            if (!value) return '¡Debes ingresar un motivo para eliminar!';
        },
        showCancelButton: true,
        confirmButtonColor: '#dc3545',
        cancelButtonColor: '#6c757d',
        confirmButtonText: '<i class="bi bi-trash"></i> Sí, eliminar',
        cancelButtonText: 'Cancelar'
    }).then((result) => {
        if (result.isConfirmed) {
            let form = document.getElementById('form-eliminar-' + id);
            let input = document.createElement('input');
            input.type = 'hidden';
            input.name = 'motivo_eliminacion';
            input.value = result.value;
            form.appendChild(input);
            form.submit();
        }
    });
}
</script>

@endsection