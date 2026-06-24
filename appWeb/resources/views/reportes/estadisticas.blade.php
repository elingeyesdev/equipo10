@extends('layouts.app')

@section('title', 'Reportes y estadísticas')
@section('page-title', 'Reportes y estadísticas')

@section('content')
<div class="content-wrapper">
    <div class="row">

        <div class="col-md-4 mb-4">
            <div class="card h-100 stats-card text-white" style="background-color: #3F7AC5;">
                <div class="card-body text-center p-4">
                    <h3 class="card-title h4 mb-3 fw-bold">Eficacia por cuadrante</h3>
                    <p class="card-text opacity-75 mb-4">Análisis de recuperación y efectividad según zonas del campus.</p>
                    <a href="{{ route('estadisticas.eficacia') }}" class="btn w-100 stretched-link" style="background:white;color:#3F7AC5;font-weight:600;">Ver reporte</a>
                </div>
            </div>
        </div>

        <div class="col-md-4 mb-4">
            <div class="card h-100 stats-card text-white" style="background-color: #5388CB;">
                <div class="card-body text-center p-4">
                    <h3 class="card-title h4 mb-3 fw-bold">Top usuarios</h3>
                    <p class="card-text opacity-75 mb-4">Ranking de colaboradores y métricas de gamificación.</p>
                    <a href="{{ route('estadisticas.usuarios') }}" class="btn w-100 stretched-link" style="background:white;color:#5388CB;font-weight:600;">Ver reporte</a>
                </div>
            </div>
        </div>

        <div class="col-md-4 mb-4">
            <div class="card h-100 stats-card" style="background-color: #E9C978;">
                <div class="card-body text-center p-4">
                    <h3 class="card-title h4 mb-3 fw-bold" style="color:#2B333D;">Tendencias</h3>
                    <p class="card-text mb-4" style="color:#2B333D;opacity:0.75;">Mapa de calor temporal y picos de incidentes.</p>
                    <a href="{{ route('estadisticas.tendencias') }}" class="btn w-100 stretched-link" style="background:white;color:#2B333D;font-weight:600;">Ver reporte</a>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection