@extends('layouts.app')

@section('title', 'Reportes y Estadísticas')
@section('page-title', 'Reportes y Estadísticas')

@section('content')
<div class="content-wrapper">
    <div class="row">
        
        <div class="col-md-4 mb-4">
            <div class="card h-100 stats-card text-white" style="background-color: #3F7AC5;">
                <div class="card-body text-center p-4">
                    <h3 class="card-title h4 mb-3">Eficacia por cuadrante</h3>
                    <p class="card-text opacity-75 mb-4">Análisis de recuperación y efectividad según zonas del campus.</p>
                    <a href="{{ route('estadisticas.eficacia') }}" class="btn btn-outline-light w-100 stretched-link">Ver reporte</a>
                </div>
            </div>
        </div>

        <div class="col-md-4 mb-4">
            <div class="card h-100 stats-card text-white" style="background-color: #16A34A;">
                <div class="card-body text-center p-4">
                    <h3 class="card-title h4 mb-3">Top usuarios</h3>
                    <p class="card-text opacity-75 mb-4">Ranking de colaboradores y métricas de gamificación.</p>
                    <a href="{{ route('estadisticas.usuarios') }}" class="btn btn-outline-light w-100 stretched-link">Ver reporte</a>
                </div>
            </div>
        </div>

        <div class="col-md-4 mb-4">
            <div class="card h-100 stats-card text-white" style="background-color: #F59E0B;">
                <div class="card-body text-center p-4">
                    <h3 class="card-title h4 mb-3">Tendencias</h3>
                    <p class="card-text opacity-75 mb-4">Mapa de calor temporal y picos de incidentes.</p>
                    <a href="{{ route('estadisticas.tendencias') }}" class="btn btn-outline-light w-100 stretched-link">Ver reporte</a>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection