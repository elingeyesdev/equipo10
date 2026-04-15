@extends('layouts.app')

@section('title', 'Ver Categoría')
@section('page-title', 'Detalle de Categoría')

@section('content')
<div class="row">
    <div class="col-md-8 mx-auto">
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0">
                    <span class="badge" style="background-color: {{ $categoria->color }}">
                        <i class="bi bi-{{ $categoria->icono }}"></i> {{ $categoria->nombre }}
                    </span>
                </h5>
            </div>
            <div class="card-body">
                <p><strong>Descripción:</strong> {{ $categoria->descripcion }}</p>
                <p><strong>Total Reportes:</strong> <span class="badge bg-info">{{ $categoria->reportes_count }}</span></p>
                
                <hr>
                
                <h6>Reportes en esta categoría:</h6>
                <div class="table-responsive">
                    <table class="table table-sm">
                        <thead>
                            <tr>
                                <th>Título</th>
                                <th>Tipo</th>
                                <th>Estado</th>
                                <th>Fecha</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($reportes as $reporte)
                            <tr>
                                <td>{{ $reporte->titulo }}</td>
                                <td><span class="badge bg-{{ $reporte->tipo_reporte == 'perdido' ? 'danger' : 'success' }}">{{ $reporte->tipo_reporte }}</span></td>
                                <td><span class="badge bg-primary">{{ $reporte->estado }}</span></td>
                                <td>{{ $reporte->created_at->format('d/m/Y') }}</td>
                            </tr>
                            @empty
                            <tr>
                                <td colspan="4" class="text-center text-muted">No hay reportes</td>
                            </tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection