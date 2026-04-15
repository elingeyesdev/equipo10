@extends('layouts.app')

@section('title', 'Eficacia por Cuadrante')
@section('page-title', 'Eficacia de Recuperación')

@section('content')
<div class="content-wrapper">
    
    <div class="card mb-4">
        <div class="card-body">
            <div class="row align-items-end g-3">
                <div class="col-lg-8">
                    <form action="{{ route('estadisticas.eficacia') }}" method="GET" class="row g-3">
                        <div class="col-md-4">
                            <label class="form-label text-muted small fw-bold">Fecha Inicio</label>
                            <input type="date" name="fecha_inicio" value="{{ $fechaInicio ?? '' }}" class="form-control">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label text-muted small fw-bold">Fecha Fin</label>
                            <input type="date" name="fecha_fin" value="{{ $fechaFin ?? '' }}" class="form-control">
                        </div>
                        <div class="col-md-4 d-flex align-items-end">
                            <button type="submit" class="btn btn-primary w-100">
                                <i class="bi bi-filter me-2"></i>Filtrar
                            </button>
                        </div>
                    </form>
                </div>
                <div class="col-lg-4 text-lg-end">
                    <div class="btn-group" role="group">
                        <a href="{{ route('estadisticas.exportar.pdf', ['reporte' => 'eficacia']) }}" class="btn btn-danger text-white">
                            <i class="bi bi-file-earmark-pdf me-2"></i>PDF
                        </a>
                        <a href="{{ route('estadisticas.exportar.excel', ['reporte' => 'eficacia']) }}" class="btn btn-success text-white">
                            <i class="bi bi-file-earmark-excel me-2"></i>Excel
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        
        <div class="col-lg-12 mb-4">
            <div class="card h-100">
                <div class="card-header bg-white py-3">
                    <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-bar-chart-fill me-2"></i>Gráfico de Eficacia</h5>
                </div>
                <div class="card-body">
                    <div style="height: 300px;">
                        <canvas id="eficaciaChart"></canvas>
                    </div>
                </div>
            </div>
        </div>

        
        <div class="col-lg-12">
            <div class="card">
                <div class="card-header bg-white py-3">
                    <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-table me-2"></i>Detalle por Cuadrante</h5>
                </div>
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th>Cuadrante</th>
                                <th class="text-center">Total Reportes</th>
                                <th class="text-center">Recuperados</th>
                                <th class="text-center">Barra de Éxito</th>
                                <th class="text-end">Tasa Éxito</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($datos as $d)
                            <tr>
                                <td class="fw-bold">{{ $d->cuadrante }}</td>
                                <td class="text-center">{{ $d->total_reportes }}</td>
                                <td class="text-center">{{ $d->recuperados }}</td>
                                <td style="width: 30%;">
                                    <div class="progress" style="height: 8px;">
                                        <div class="progress-bar {{ $d->tasa_exito > 50 ? 'bg-success' : 'bg-warning' }}" 
                                             role="progressbar" 
                                             style="width: {{ $d->tasa_exito }}%" 
                                             aria-valuenow="{{ $d->tasa_exito }}" 
                                             aria-valuemin="0" 
                                             aria-valuemax="100"></div>
                                    </div>
                                </td>
                                <td class="text-end">
                                    <span class="badge {{ $d->tasa_exito > 50 ? 'bg-success-subtle text-success border border-success' : 'bg-warning-subtle text-warning border border-warning' }}">
                                        {{ $d->tasa_exito }}%
                                    </span>
                                </td>
                            </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        const ctx = document.getElementById('eficaciaChart').getContext('2d');
        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: {!! json_encode($chartData['labels']) !!},
                datasets: [{
                    label: 'Tasa de Éxito (%)',
                    data: {!! json_encode($chartData['data']) !!},
                    backgroundColor: 'rgba(37, 99, 235, 0.6)',
                    borderColor: 'rgb(37, 99, 235)',
                    borderWidth: 1,
                    borderRadius: 5
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100,
                        grid: { borderDash: [2, 4] }
                    },
                    x: {
                        grid: { display: false }
                    }
                },
                plugins: {
                    legend: { display: false }
                }
            }
        });
    });
</script>
@endsection
