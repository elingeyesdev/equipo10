@extends('layouts.app')

@section('title', 'Top Colaboradores')
@section('page-title', 'Ranking de Usuarios')

@section('content')
<div class="content-wrapper">
    
    <div class="card mb-4">
        <div class="card-body">
            <div class="row align-items-end g-3">
                <div class="col-lg-8">
                    <form action="{{ route('estadisticas.usuarios') }}" method="GET" class="row g-3 align-items-end">
                        <div class="col-md-4">
                            <label class="form-label text-muted small fw-bold">Mostrar Top</label>
                            <select name="limit" class="form-select">
                                <option value="5" {{ $limit == 5 ? 'selected' : '' }}>Top 5</option>
                                <option value="10" {{ $limit == 10 ? 'selected' : '' }}>Top 10</option>
                                <option value="20" {{ $limit == 20 ? 'selected' : '' }}>Top 20</option>
                            </select>
                        </div>
                        <div class="col-md-4">
                            <button type="submit" class="btn btn-primary w-100">
                                <i class="bi bi-arrow-repeat me-2"></i>Actualizar
                            </button>
                        </div>
                    </form>
                </div>
                <div class="col-lg-4 text-lg-end">
                    <div class="btn-group" role="group">
                        <a href="{{ route('estadisticas.exportar.pdf', ['reporte' => 'usuarios']) }}" class="btn btn-danger text-white">
                            <i class="bi bi-file-earmark-pdf me-2"></i>PDF
                        </a>
                        <a href="{{ route('estadisticas.exportar.excel', ['reporte' => 'usuarios']) }}" class="btn btn-success text-white">
                            <i class="bi bi-file-earmark-excel me-2"></i>Excel
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        
        <div class="col-lg-8 mb-4">
            <div class="card h-100">
                <div class="card-header bg-white py-3">
                    <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-people-fill me-2"></i>Tabla de Posiciones</h5>
                </div>
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="text-center" style="width: 50px;">#</th>
                                <th>Usuario</th>
                                <th class="text-center">Puntos</th>
                                <th>Actividad</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($usuarios as $index => $u)
                            <tr>
                                <td class="text-center">
                                    @if($index == 0) <i class="bi bi-trophy-fill text-warning fs-5"></i>
                                    @elseif($index == 1) <i class="bi bi-trophy-fill text-secondary fs-5"></i>
                                    @elseif($index == 2) <i class="bi bi-trophy-fill text-danger fs-5" style="color: #cd7f32 !important"></i>
                                    @else <span class="fw-bold text-muted">{{ $index + 1 }}</span>
                                    @endif
                                </td>
                                <td>
                                    <div class="d-flex align-items-center">
                                        @if($u->avatar_url)
                                            <img src="{{ $u->avatar_url }}" class="rounded-circle me-3 border" width="40" height="40" alt="Avatar">
                                        @else
                                            <div class="rounded-circle me-3 bg-secondary d-flex align-items-center justify-content-center text-white" style="width: 40px; height: 40px;">
                                                {{ substr($u->nombre, 0, 1) }}
                                            </div>
                                        @endif
                                        <div>
                                            <h6 class="mb-0 fw-bold">{{ $u->nombre }}</h6>
                                            <small class="text-muted">Miembro activo</small>
                                        </div>
                                    </div>
                                </td>
                                <td class="text-center">
                                    <span class="badge bg-primary-subtle text-primary border border-primary fs-6">{{ $u->puntos_ayuda }}</span>
                                </td>
                                <td>
                                    <div class="small">
                                        <span class="d-block"><i class="bi bi-file-text me-1"></i> {{ $u->reportes_creados }} reportes</span>
                                        <span class="d-block text-success"><i class="bi bi-check-circle me-1"></i> {{ $u->ayudas_brindadas }} ayudas</span>
                                    </div>
                                </td>
                            </tr>
                            @endforeach
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        
        <div class="col-lg-4 mb-4">
            <div class="card h-100">
                <div class="card-header bg-white py-3">
                    <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-pie-chart-fill me-2"></i>Distribución</h5>
                </div>
                <div class="card-body d-flex align-items-center justify-content-center">
                    <div style="width: 100%; max-width: 300px;">
                        <canvas id="usuariosChart"></canvas>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        const ctx = document.getElementById('usuariosChart').getContext('2d');
        new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: {!! json_encode($chartData['labels']) !!},
                datasets: [{
                    data: {!! json_encode($chartData['data']) !!},
                    backgroundColor: [
                        '#2563eb', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6', '#9CA3AF'
                    ],
                    borderWidth: 0,
                    hoverOffset: 4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            usePointStyle: true,
                            padding: 20
                        }
                    }
                }
            }
        });
    });
</script>
@endsection
