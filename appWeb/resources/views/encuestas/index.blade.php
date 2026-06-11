@extends('layouts.app')

@section('title', 'Reseñas y Satisfacción - Amigate')
@section('page-title', 'Reseñas y Satisfacción')

@push('styles')
<style>
    .header-card {
        background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
        border-radius: 16px;
        color: white;
        padding: 30px;
        box-shadow: 0 10px 25px rgba(37, 99, 235, 0.3);
        margin-bottom: 30px;
    }
    
    .rating-big {
        font-size: 4rem;
        font-weight: 800;
        line-height: 1;
        text-shadow: 0 2px 10px rgba(0,0,0,0.2);
    }

    .rating-max {
        font-size: 1.5rem;
        color: rgba(255, 255, 255, 0.7);
    }
    
    .stars-big i {
        font-size: 2rem;
        color: #fbbf24;
        text-shadow: 0 2px 5px rgba(251, 191, 36, 0.4);
    }

    .progress-bar-star {
        background-color: #fbbf24;
    }

    .review-card {
        background: #fff;
        border-radius: 16px;
        border: 1px solid #f1f5f9;
        box-shadow: 0 4px 15px rgba(0,0,0,0.03);
        padding: 24px;
        margin-bottom: 20px;
        transition: transform 0.2s ease, box-shadow 0.2s ease;
    }

    .review-card:hover {
        transform: translateY(-3px);
        box-shadow: 0 10px 25px rgba(0,0,0,0.08);
    }

    .review-avatar {
        width: 48px;
        height: 48px;
        border-radius: 50%;
        background: linear-gradient(135deg, #3b82f6, #60a5fa);
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: bold;
        font-size: 1.2rem;
    }

    .stars-small i {
        color: #fbbf24;
        font-size: 1.1rem;
    }
    .stars-small .empty {
        color: #e2e8f0;
    }

    .badge-rol {
        background: #f1f5f9;
        color: #475569;
        font-weight: 600;
        padding: 6px 12px;
        border-radius: 50px;
        font-size: 0.8rem;
    }

    .badge-reporte {
        background: #e0e7ff;
        color: #3730a3;
        font-weight: 600;
        padding: 6px 12px;
        border-radius: 50px;
        font-size: 0.8rem;
        display: inline-flex;
        align-items: center;
        gap: 6px;
        text-decoration: none;
    }

    .badge-reporte:hover {
        background: #c7d2fe;
        color: #312e81;
    }
</style>
@endpush

@section('content')

<!-- Encabezado de Estadísticas -->
<div class="header-card">
    <div class="row align-items-center">
        <!-- Promedio Global -->
        <div class="col-md-4 text-center border-md-end border-light border-opacity-25 mb-4 mb-md-0">
            <h5 class="text-white-50 fw-semibold text-uppercase tracking-wide mb-3">Satisfacción Global</h5>
            <div class="rating-big mb-2">
                {{ number_format($promedioSatisfaccion, 1) }}<span class="rating-max">/5</span>
            </div>
            <div class="stars-big mb-3">
                @for($i=1; $i<=5; $i++)
                    @if($promedioSatisfaccion >= $i)
                        <i class="bi bi-star-fill"></i>
                    @elseif($promedioSatisfaccion >= $i - 0.5)
                        <i class="bi bi-star-half"></i>
                    @else
                        <i class="bi bi-star"></i>
                    @endif
                @endfor
            </div>
            <p class="mb-0 text-white fw-medium">Basado en {{ $totalEncuestas }} opiniones</p>
        </div>

        <!-- Distribución de Estrellas -->
        <div class="col-md-8 ps-md-5">
            <h5 class="text-white-50 fw-semibold mb-4">Distribución de puntuaciones</h5>
            
            @foreach($distribucionEstrellas as $estrellas => $data)
            <div class="d-flex align-items-center mb-3">
                <div class="d-flex align-items-center me-3" style="width: 60px;">
                    <span class="fw-bold me-1 fs-5">{{ $estrellas }}</span>
                    <i class="bi bi-star-fill text-warning"></i>
                </div>
                <div class="progress flex-grow-1" style="height: 10px; background-color: rgba(255,255,255,0.2); border-radius: 10px;">
                    <div class="progress-bar progress-bar-star rounded-pill" role="progressbar" style="width: {{ $data['porcentaje'] }}%;" aria-valuenow="{{ $data['porcentaje'] }}" aria-valuemin="0" aria-valuemax="100"></div>
                </div>
                <div class="ms-3 text-end fw-medium" style="width: 50px;">
                    {{ $data['porcentaje'] }}%
                </div>
                <div class="ms-2 text-white-50 small" style="width: 30px;">
                    ({{ $data['count'] }})
                </div>
            </div>
            @endforeach
        </div>
    </div>
</div>

<!-- Lista de Reseñas -->
<div class="d-flex justify-content-between align-items-center mb-4">
    <h4 class="fw-bold text-dark mb-0"><i class="bi bi-chat-square-quote-fill text-primary me-2"></i> Opiniones Recientes</h4>
</div>

<div class="row">
    <div class="col-12">
        @forelse($encuestas as $encuesta)
        <div class="review-card">
            <div class="d-flex justify-content-between align-items-start mb-3">
                <div class="d-flex align-items-center">
                    <div class="review-avatar me-3 shadow-sm">
                        {{ strtoupper(substr($encuesta->usuario_nombre, 0, 1)) }}
                    </div>
                    <div>
                        <h6 class="fw-bold mb-1 fs-5">{{ $encuesta->usuario_nombre }}</h6>
                        <div class="d-flex align-items-center gap-2">
                            <span class="badge-rol">{{ $encuesta->rol }}</span>
                            <span class="text-muted small"><i class="bi bi-calendar3 me-1"></i> {{ $encuesta->fecha }}</span>
                        </div>
                    </div>
                </div>
                
                <div class="text-end">
                    <div class="stars-small mb-2">
                        @for($i=1; $i<=5; $i++)
                            @if($encuesta->puntuacion >= $i)
                                <i class="bi bi-star-fill"></i>
                            @else
                                <i class="bi bi-star-fill empty"></i>
                            @endif
                        @endfor
                    </div>
                </div>
            </div>
            
            @if($encuesta->comentario)
                <div class="p-3 bg-light rounded-3 mb-3 border border-light">
                    <p class="mb-0 text-secondary fst-italic">"{{ $encuesta->comentario }}"</p>
                </div>
            @endif
            
            <div class="mt-2 pt-3 border-top border-light d-flex align-items-center">
                <span class="text-muted small fw-semibold me-2">Referente a:</span>
                @if($encuesta->reporte_id)
                    <a href="{{ route('reportes.show', $encuesta->reporte_id) }}" class="badge-reporte">
                        <i class="bi bi-file-earmark-text-fill"></i> {{ Str::limit($encuesta->reporte_titulo, 60) }}
                    </a>
                @else
                    <span class="badge-rol bg-secondary bg-opacity-10 text-secondary">
                        <i class="bi bi-trash-fill me-1"></i> Reporte eliminado
                    </span>
                @endif
            </div>
        </div>
        @empty
        <div class="text-center py-5 bg-white rounded-4 shadow-sm border border-light">
            <i class="bi bi-chat-square-text text-muted mb-3" style="font-size: 4rem; opacity: 0.5;"></i>
            <h5 class="fw-bold text-dark">Aún no hay reseñas</h5>
            <p class="text-muted mb-0">Cuando los voluntarios valoren los operativos, aparecerán aquí.</p>
        </div>
        @endforelse
        
        <!-- Paginación -->
        @if($encuestas->hasPages())
        <div class="d-flex justify-content-center mt-4 mb-5">
            {{ $encuestas->links() }}
        </div>
        @endif
    </div>
</div>

@endsection
