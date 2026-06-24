@extends('layouts.app')

@section('title', 'Eficacia por cuadrante')
@section('page-title', 'Eficacia de recuperación')

@section('content')
<div class="content-wrapper">

    <div class="card mb-4">
        <div class="card-body">
            <form action="{{ route('estadisticas.eficacia') }}" method="GET">
                <div class="row align-items-end g-3">
                    <div class="col-lg-3 col-md-6">
                        <label class="form-label text-muted small fw-bold">Fecha inicio</label>
                        <input type="date" name="fecha_inicio" value="{{ $fechaInicio ?? '' }}" class="form-control">
                    </div>
                    <div class="col-lg-3 col-md-6">
                        <label class="form-label text-muted small fw-bold">Fecha fin</label>
                        <input type="date" name="fecha_fin" value="{{ $fechaFin ?? '' }}" class="form-control">
                    </div>
                    <div class="col-lg-2 col-md-4 col-sm-6">
                        <button type="submit" class="btn btn-primary w-100" style="height:38px;padding-top:0;padding-bottom:0;">Filtrar</button>
                    </div>
                    <div class="col-lg-4 col-md-8 col-sm-6 d-flex gap-2 justify-content-lg-end">
                        <a href="{{ route('estadisticas.exportar.pdf', ['reporte' => 'eficacia']) }}" class="btn btn-danger text-white" style="height:38px;display:flex;align-items:center;">
                            PDF
                        </a>
                        <a href="{{ route('estadisticas.exportar.excel', ['reporte' => 'eficacia']) }}" class="btn btn-success text-white" style="height:38px;display:flex;align-items:center;">
                            Excel
                        </a>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <div class="row">

        <div class="col-lg-12 mb-4">
            <div class="card h-100">
                <div class="card-header bg-white py-3">
                    <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-bar-chart-fill me-2"></i>Gráfico de eficacia</h5>
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
                    <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-table me-2"></i>Detalle por cuadrante</h5>
                </div>
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th>Cuadrante</th>
                                <th class="text-center">Total reportes</th>
                                <th class="text-center">Recuperados</th>
                                <th class="text-center">Barra de éxito</th>
                                <th class="text-end">Tasa de éxito</th>
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
                                    @if($d->tasa_exito > 50)
                                        <span class="badge" style="background:#16A34A;color:white;">{{ $d->tasa_exito }}%</span>
                                    @else
                                        <span class="badge" style="background:#E9C978;color:#2B333D;">{{ $d->tasa_exito }}%</span>
                                    @endif
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
                    label: 'Tasa de éxito (%)',
                    data: {!! json_encode($chartData['data']) !!},
                    backgroundColor: 'rgba(63, 122, 197, 0.6)',
                    borderColor: 'rgb(63, 122, 197)',
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
