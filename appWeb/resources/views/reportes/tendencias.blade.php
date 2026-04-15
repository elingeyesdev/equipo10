@extends('layouts.app')

@section('title', 'Tendencias Temporales')
@section('page-title', 'Mapa de Calor de Incidentes')

@section('content')
<div class="content-wrapper">
    
    <div class="card mb-4">
        <div class="card-body">
            <div class="row align-items-end g-3">
                <div class="col-lg-8">
                    <form action="{{ route('estadisticas.tendencias') }}" method="GET" class="row g-3 align-items-end">
                        <div class="col-md-4">
                            <label class="form-label text-muted small fw-bold">Año de Análisis</label>
                            <input type="number" name="year" value="{{ $year }}" min="2020" max="{{ date('Y') }}" class="form-control">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label text-muted small fw-bold">Categoría</label>
                            <select name="categoria_id" class="form-select">
                                <option value="">Todas las categorías</option>
                                @foreach($categorias as $cat)
                                    <option value="{{ $cat->id }}" {{ (isset($categoriaId) && $categoriaId == $cat->id) ? 'selected' : '' }}>
                                        {{ $cat->nombre }}
                                    </option>
                                @endforeach
                            </select>
                        </div>
                        <div class="col-md-4">
                            <button type="submit" class="btn btn-primary w-100">
                                <i class="bi bi-graph-up me-2"></i>Analizar
                            </button>
                        </div>
                    </form>
                </div>
                <div class="col-lg-4 text-lg-end">
                    <div class="btn-group" role="group">
                        <a href="{{ route('estadisticas.exportar.pdf', ['reporte' => 'tendencias']) }}" class="btn btn-danger text-white">
                            <i class="bi bi-file-earmark-pdf me-2"></i>PDF
                        </a>
                        <a href="{{ route('estadisticas.exportar.excel', ['reporte' => 'tendencias']) }}" class="btn btn-success text-white">
                            <i class="bi bi-file-earmark-excel me-2"></i>Excel
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        
        <div class="col-12">
            <div class="card shadow-sm">
                <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center">
                    <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-calendar-range me-2"></i>Evolución Mensual (Perdidos vs Resueltos)</h5>
                    <span class="badge bg-secondary">{{ $year }}</span>
                </div>
                <div class="card-body">
                    <div style="height: 400px; width: 100%;">
                        <canvas id="tendenciasChart"></canvas>
                    </div>
                </div>
            </div>
        </div>
        
        
        <div class="col-md-6 mt-4">
             <div class="alert alert-danger d-flex align-items-center mb-0 border-0 shadow-sm text-white" style="background-color: #EF4444;">
                 <i class="bi bi-exclamation-circle-fill fs-2 me-3"></i>
                 <div>
                     <strong>Total Perdidos</strong>
                     <div class="fs-4 fw-bold">{{ array_sum($chartData['perdidos']) }} incidentes</div>
                 </div>
             </div>
        </div>
        <div class="col-md-6 mt-4">
             <div class="alert alert-primary d-flex align-items-center mb-0 border-0 shadow-sm text-white" style="background-color: #2563eb;">
                 <i class="bi bi-check-circle-fill fs-2 me-3"></i>
                 <div>
                     <strong>Total Resueltos</strong>
                     <div class="fs-4 fw-bold">{{ array_sum($chartData['resueltos']) }} casos</div>
                 </div>
             </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        const ctx = document.getElementById('tendenciasChart').getContext('2d');
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: {!! json_encode($chartData['labels']) !!},
                datasets: [
                    {
                        label: 'Objetos Perdidos',
                        data: {!! json_encode($chartData['perdidos']) !!},
                        borderColor: '#EF4444', 
                        backgroundColor: 'rgba(239, 68, 68, 0.1)',
                        pointBackgroundColor: '#EF4444',
                        fill: true,
                        tension: 0.4,
                        borderWidth: 2
                    },
                    {
                        label: 'Casos Resueltos',
                        data: {!! json_encode($chartData['resueltos']) !!},
                        borderColor: '#2563eb', 
                        backgroundColor: 'rgba(37, 99, 235, 0.1)',
                        pointBackgroundColor: '#2563eb',
                        fill: true,
                        tension: 0.4,
                        borderWidth: 2
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: { borderDash: [2, 4] }
                    },
                    x: {
                        grid: { display: false }
                    }
                },
                plugins: {
                    legend: {
                        position: 'top',
                        labels: { usePointStyle: true }
                    }
                }
            }
        });
    });
</script>
@endsection
