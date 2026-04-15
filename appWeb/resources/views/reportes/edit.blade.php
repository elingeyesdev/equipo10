@extends('layouts.app')

@section('title', 'Editar Reporte')
@section('page-title', 'Editar Reporte')

@section('content')
<div class="row">
    <div class="col-md-10 mx-auto">
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0"><i class="bi bi-pencil me-2"></i>Editar: {{ $reporte->titulo }}</h5>
            </div>
            <div class="card-body">
                <form action="{{ route('reportes.update', $reporte->id) }}" method="POST">
                    @csrf
                    @method('PUT')
                    
                    <div class="mb-3">
                        <label class="form-label">Título *</label>
                        <input type="text" name="titulo" class="form-control" 
                               value="{{ old('titulo', $reporte->titulo) }}" required>
                    </div>

                    <div class="mb-3">
                        <label class="form-label">Descripción *</label>
                        <textarea name="descripcion" class="form-control" rows="4" required>{{ old('descripcion', $reporte->descripcion) }}</textarea>
                    </div>

                    <div class="row">
                        <div class="col-md-4 mb-3">
                            <label class="form-label">Estado</label>
                            <select name="estado" class="form-select">
                                <option value="activo" {{ $reporte->estado == 'activo' ? 'selected' : '' }}>Activo</option>
                                <option value="resuelto" {{ $reporte->estado == 'resuelto' ? 'selected' : '' }}>Resuelto</option>
                                <option value="inactivo" {{ $reporte->estado == 'inactivo' ? 'selected' : '' }}>Inactivo</option>
                            </select>
                        </div>

                        <div class="col-md-4 mb-3">
                            <label class="form-label">Prioridad</label>
                            <select name="prioridad" class="form-select">
                                <option value="baja" {{ $reporte->prioridad == 'baja' ? 'selected' : '' }}>Baja</option>
                                <option value="normal" {{ $reporte->prioridad == 'normal' ? 'selected' : '' }}>Normal</option>
                                <option value="alta" {{ $reporte->prioridad == 'alta' ? 'selected' : '' }}>Alta</option>
                                <option value="urgente" {{ $reporte->prioridad == 'urgente' ? 'selected' : '' }}>Urgente</option>
                            </select>
                        </div>

                        <div class="col-md-4 mb-3">
                            <label class="form-label">Recompensa (Bs.)</label>
                            <input type="number" name="recompensa" class="form-control" 
                                   value="{{ old('recompensa', $reporte->recompensa) }}" min="0" step="0.01">
                        </div>
                    </div>

                    <div class="d-flex justify-content-end gap-2">
                        <a href="{{ route('reportes.index') }}" class="btn btn-secondary">
                            <i class="bi bi-x-circle me-1"></i> Cancelar
                        </a>
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-check-circle me-1"></i> Actualizar
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
@endsection