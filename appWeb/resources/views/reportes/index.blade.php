@extends('layouts.app')

@section('title', 'Gestión de reportes')
@section('page-title', 'Listado de reportes')

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
                                <option value="pausado" {{ request('estado') == 'pausado' ? 'selected' : '' }}>Pausado</option>
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
                            <button type="submit" class="btn btn-primary rounded-pill px-4" style="height:38px;">
                                <i class="bi bi-search"></i>
                            </button>
                        </div>
                     </form>
                </div>
                <div class="col-md-4 text-end">
                    <!-- Botón de Nuevo Reporte eliminado -->
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
                                            <span class="d-flex align-items-center justify-content-center rounded-circle" style="width:32px;height:32px;background:#E9C978;color:#2B333D;flex-shrink:0;">
                                                <i class="bi bi-exclamation-triangle-fill" style="font-size:0.85rem;"></i>
                                            </span>
                                        @else
                                            <span class="d-flex align-items-center justify-content-center rounded-circle" style="width:32px;height:32px;background:#16A34A;color:white;flex-shrink:0;">
                                                <i class="bi bi-check-circle-fill" style="font-size:0.85rem;"></i>
                                            </span>
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
                                    <div class="rounded-circle d-flex align-items-center justify-content-center me-2 fw-bold" style="width:32px;height:32px;background:#3F7AC5;color:white;font-size:0.85rem;flex-shrink:0;">
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
                                        <span class="badge" style="background-color:#3F7AC5;color:white;">Activo</span>
                                        @break
                                    @case('pausado')
                                        <span class="badge" style="background-color:#E9C978;color:#2B333D;">Pausado</span>
                                        @break
                                    @case('resuelto')
                                        <span class="badge" style="background-color:#DFDFDF;color:#3F4B5B;">Finalizado</span>
                                        @break
                                    @case('inactivo')
                                        <span class="badge" style="background-color:#ECECEC;color:#3F4B5B;">Inactivo</span>
                                        @break
                                    @case('spam')
                                        <span class="badge" style="background-color:#EF4444;color:white;">Spam</span>
                                        @break
                                    @default
                                        <span class="badge" style="background-color:#ECECEC;color:#3F4B5B;">{{ $reporte->estado }}</span>
                                @endswitch
                            </td>
                            <td>
                                <small class="text-muted" title="{{ $reporte->created_at }}">
                                    {{ $reporte->created_at->locale('es')->diffForHumans() }}
                                </small>
                            </td>
                            <td class="text-end pe-4">
                                <div class="d-flex justify-content-end gap-2">
                                    <a href="{{ route('reportes.show', $reporte->id) }}" class="btn btn-sm d-flex align-items-center justify-content-center" style="background:#5388CB;color:white;width:32px;height:32px;padding:0;" title="Ver detalles">
                                        <i class="bi bi-eye-fill"></i>
                                    </a>
                                    <a href="{{ route('reportes.edit', $reporte->id) }}" class="btn btn-sm d-flex align-items-center justify-content-center" style="background:#3F7AC5;color:white;width:32px;height:32px;padding:0;" title="Editar">
                                        <i class="bi bi-pencil-fill"></i>
                                    </a>
                                    <button type="button" class="btn btn-sm d-flex align-items-center justify-content-center" style="background:#E9C978;color:#2B333D;width:32px;height:32px;padding:0;" onclick="confirmDelete('{{ $reporte->id }}')" title="Eliminar">
                                        <i class="bi bi-trash-fill"></i>
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

<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
<script>
    function confirmDelete(id) {
        Swal.fire({
            title: '¿Eliminar permanentemente?',
            text: "Esta acción no se puede deshacer y eliminará todos los registros asociados. Se notificará a los participantes.",
            icon: 'error',
            input: 'textarea',
            inputLabel: 'Motivo de eliminación',
            inputPlaceholder: 'Ej. Reporte falso, spam, duplicado...',
            inputValidator: (value) => {
                if (!value) return '¡Debes ingresar un motivo para eliminar!';
            },
            showCancelButton: true,
            confirmButtonColor: '#dc3545',
            cancelButtonColor: '#6c757d',
            confirmButtonText: '<i class="bi bi-trash"></i> Sí, eliminar',
            cancelButtonText: 'Cancelar'
        }).then((result) => {
            if (result.isConfirmed) {
                let form = document.getElementById('delete-form-' + id);
                let input = document.createElement('input');
                input.type = 'hidden';
                input.name = 'motivo_eliminacion';
                input.value = result.value;
                form.appendChild(input);
                form.submit();
            }
        });
    }
</script>
@endsection
