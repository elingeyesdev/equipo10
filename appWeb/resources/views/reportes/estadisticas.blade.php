@extends('layouts.app')

@section('title', 'Reportes y Estadísticas')
@section('page-title', 'Reportes y Estadísticas')

@section('content')
<div class="content-wrapper">
    <div class="row">
        
        <div class="col-md-4 mb-4">
            <div class="card h-100 stats-card bg-primary text-white" style="background: linear-gradient(135deg, #2563eb 0%, #1e40af 100%);">
                <div class="card-body text-center p-4">
                    <i class="bi bi-crosshair mb-3 d-block" style="font-size: 3rem;"></i>
                    <h3 class="card-title h4 mb-3">Eficacia por Cuadrante</h3>
                    <p class="card-text opacity-75 mb-4">Análisis de recuperación y efectividad según zonas del campus.</p>
                    <a href="{{ route('estadisticas.eficacia') }}" class="btn btn-outline-light w-100 stretched-link">Ver Reporte</a>
                </div>
            </div>
        </div>

        
        <div class="col-md-4 mb-4">
            <div class="card h-100 stats-card text-white" style="background: linear-gradient(135deg, #10B981 0%, #059669 100%);">
                <div class="card-body text-center p-4">
                    <i class="bi bi-trophy mb-3 d-block" style="font-size: 3rem;"></i>
                    <h3 class="card-title h4 mb-3">Top Usuarios</h3>
                    <p class="card-text opacity-75 mb-4">Ranking de colaboradores y métricas de gamificación.</p>
                    <a href="{{ route('estadisticas.usuarios') }}" class="btn btn-outline-light w-100 stretched-link">Ver Reporte</a>
                </div>
            </div>
        </div>

        
        <div class="col-md-4 mb-4">
            <div class="card h-100 stats-card text-white" style="background: linear-gradient(135deg, #F59E0B 0%, #D97706 100%);">
                <div class="card-body text-center p-4">
                    <i class="bi bi-graph-up-arrow mb-3 d-block" style="font-size: 3rem;"></i>
                    <h3 class="card-title h4 mb-3">Tendencias</h3>
                    <p class="card-text opacity-75 mb-4">Mapa de calor temporal y picos de incidentes.</p>
                    <a href="{{ route('estadisticas.tendencias') }}" class="btn btn-outline-light w-100 stretched-link">Ver Reporte</a>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection