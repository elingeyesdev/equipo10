@extends('layouts.app')

@section('title', 'Gestión de Reportes')
@section('page-title', 'Listado de Reportes')

@section('content')
<div class="content-wrapper">
    
    <div class="card mb-4">
        <div class="card-body">
            <div class="row align-items-center">
                <div class="col-md-8">
                     <form action="{{ route('reportes.index') }}" method="GET" class="row g-2">
                        <div class="col-md-4">
                            <input type="text" name="search" class="form-control" placeholder="Buscar reporte..." value="{{ request('search') }}">
                        </div>
                        <div class="col-md-3">
                            <select name="estado" class="form-select">
                                <option value="">Estado: Todos</option>
                                <option value="activo" {{ request('estado') == 'activo' ? 'selected' : '' }}>Activo</option>
                                <option value="resuelto" {{ request('estado') == 'resuelto' ? 'selected' : '' }}>Resuelto</option>
                                <option value="inactivo" {{ request('estado') == 'inactivo' ? 'selected' : '' }}>Inactivo</option>
                            </select>
                        </div>
                        <div class="col-md-3">
                            <select name="tipo" class="form-select">
                                <option value="">Tipo: Todos</option>
                                <option value="perdido" {{ request('tipo') == 'perdido' ? 'selected' : '' }}>Perdido</option>
                                <option value="encontrado" {{ request('tipo') == 'encontrado' ? 'selected' : '' }}>Encontrado</option>
                            </select>
                        </div>
                        <div class="col-md-2">
                            <button type="submit" class="btn btn-primary w-100">
                                <i class="bi bi-search"></i>
                            </button>
                        </div>
                     </form>
                </div>
                <div class="col-md-4 text-end">
                    <a href="{{ route('reportes.create') }}" class="btn btn-success text-white">
                        <i class="bi bi-plus-lg me-2"></i>Nuevo Reporte
                    </a>
                </div>
            </div>
        </div>
    </div>

    <div class="card">
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light">
                        <tr>
                            <th class="ps-4">Título / Categoría</th>
                            <th>Usuario</th>
                            <th>Ubicación / Cuadrante</th>
                            <th>Estado</th>
                            <th>Fecha</th>
                            <th class="text-end pe-4">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($reportes as $reporte)
                        <tr>
                            <td class="ps-4">
                                <div class="d-flex align-items-center">
                                    <div class="me-3">
                                        @if($reporte->tipo_reporte == 'perdido')
                                            <span class="badge rounded-pill bg-danger"><i class="bi bi-exclamation-triangle"></i></span>
                                        @else
                                            <span class="badge rounded-pill bg-success"><i class="bi bi-check-circle"></i></span>
                                        @endif
                                    </div>
                                    <div>
                                        <h6 class="mb-0 fw-bold">{{ Str::limit($reporte->titulo, 40) }}</h6>
                                        <span class="badge" style="background-color: {{ $reporte->categoria->color ?? '#6c757d' }}; font-size: 0.7rem;">
                                            {{ $reporte->categoria->nombre ?? 'Sin categoría' }}
                                        </span>
                                    </div>
                                </div>
                            </td>
                            <td>
                                <div class="d-flex align-items-center">
                                    <div class="rounded-circle bg-light text-primary d-flex align-items-center justify-content-center me-2" style="width: 32px; height: 32px;">
                                        {{ substr($reporte->usuario->nombre ?? 'A', 0, 1) }}
                                    </div>
                                    <span class="small fw-semibold">{{ $reporte->usuario->nombre ?? 'Anónimo' }}</span>
                                </div>
                            </td>
                            <td>
                                <small class="d-block text-truncate" style="max-width: 150px;">{{ $reporte->direccion_referencia ?? 'Sin dirección' }}</small>
                                <span class="badge bg-light text-dark border">{{ $reporte->cuadrante->codigo ?? 'N/A' }}</span>
                            </td>
                            <td>
                                @switch($reporte->estado)
                                    @case('activo')
                                        <span class="badge bg-primary-subtle text-primary border border-primary">Activo</span>
                                        @break
                                    @case('resuelto')
                                        <span class="badge bg-success-subtle text-success border border-success">Resuelto</span>
                                        @break
                                    @case('inactivo')
                                        <span class="badge bg-secondary-subtle text-secondary border border-secondary">Inactivo</span>
                                        @break
                                    @case('spam')
                                        <span class="badge bg-danger-subtle text-danger border border-danger">Spam</span>
                                        @break
                                @endswitch
                            </td>
                            <td>
                                <small class="text-muted" title="{{ $reporte->created_at }}">
                                    {{ $reporte->created_at->diffForHumans() }}
                                </small>
                            </td>
                            <td class="text-end pe-4">
                                <div class="btn-group">
                                    <a href="{{ route('reportes.show', $reporte->id) }}" class="btn btn-sm btn-outline-secondary" title="Ver detalles">
                                        <i class="bi bi-eye"></i>
                                    </a>
                                    <a href="{{ route('reportes.edit', $reporte->id) }}" class="btn btn-sm btn-outline-primary" title="Editar">
                                        <i class="bi bi-pencil"></i>
                                    </a>
                                    <button type="button" class="btn btn-sm btn-outline-danger" onclick="confirmDelete('{{ $reporte->id }}')" title="Eliminar">
                                        <i class="bi bi-trash"></i>
                                    </button>
                                </div>
                                <form id="delete-form-{{ $reporte->id }}" action="{{ route('reportes.destroy', $reporte->id) }}" method="POST" class="d-none">
                                    @csrf
                                    @method('DELETE')
                                </form>
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="6" class="text-center py-5 text-muted">
                                <i class="bi bi-inbox fs-1 d-block mb-3"></i>
                                No se encontraron reportes
                            </td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
            
            @if($reportes instanceof \Illuminate\Pagination\LengthAwarePaginator && $reportes->hasPages())
            <div class="card-footer bg-white border-top-0 d-flex justify-content-end p-3">
                {{ $reportes->links() }}
            </div>
            @endif
        </div>
    </div>
</div>

<script>
    function confirmDelete(id) {
        if (confirm('¿Estás seguro de que deseas eliminar este reporte?')) {
            document.getElementById('delete-form-' + id).submit();
        }
    }
</script>
@endsection
