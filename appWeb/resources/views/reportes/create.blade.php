

@extends('layouts.app')

@section('title', 'Crear Reporte')
@section('page-title', 'Crear Nuevo Reporte')

@section('content')
<div class="row">
    <div class="col-md-10 mx-auto">
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0"><i class="bi bi-plus-circle me-2"></i>Nuevo Reporte</h5>
            </div>
            <div class="card-body">
                <form action="{{ route('reportes.store') }}" method="POST" enctype="multipart/form-data">
                    @csrf
                    
                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Usuario *</label>
                            <select name="usuario_id" class="form-select @error('usuario_id') is-invalid @enderror" required>
                                <option value="">Seleccionar usuario</option>
                                @foreach($usuarios ?? [] as $usuario)
                                    <option value="{{ $usuario->id }}" {{ old('usuario_id') == $usuario->id ? 'selected' : '' }}>
                                        {{ $usuario->nombre }} ({{ $usuario->email }})
                                    </option>
                                @endforeach
                            </select>
                            @error('usuario_id')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>

                        <div class="col-md-6 mb-3">
                            <label class="form-label">Tipo de Reporte *</label>
                            <select name="tipo_reporte" class="form-select @error('tipo_reporte') is-invalid @enderror" required>
                                <option value="">Seleccionar tipo</option>
                                <option value="perdido" {{ old('tipo_reporte') == 'perdido' ? 'selected' : '' }}>Perdido</option>
                                <option value="encontrado" {{ old('tipo_reporte') == 'encontrado' ? 'selected' : '' }}>Encontrado</option>
                            </select>
                            @error('tipo_reporte')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Categoría *</label>
                            <select name="categoria_id" class="form-select @error('categoria_id') is-invalid @enderror" required>
                                <option value="">Seleccionar categoría</option>
                                @foreach($categorias ?? [] as $categoria)
                                    <option value="{{ $categoria->id }}" {{ old('categoria_id') == $categoria->id ? 'selected' : '' }}>
                                        {{ $categoria->nombre }}
                                    </option>
                                @endforeach
                            </select>
                            @error('categoria_id')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>

                        <div class="col-md-6 mb-3">
                            <label class="form-label">Cuadrante *</label>
                            <select name="cuadrante_id" class="form-select @error('cuadrante_id') is-invalid @enderror" required>
                                <option value="">Seleccionar cuadrante</option>
                                @foreach($cuadrantes ?? [] as $cuadrante)
                                    <option value="{{ $cuadrante->id }}" {{ old('cuadrante_id') == $cuadrante->id ? 'selected' : '' }}>
                                        {{ $cuadrante->codigo }} - {{ $cuadrante->nombre }}
                                    </option>
                                @endforeach
                            </select>
                            @error('cuadrante_id')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>
                    </div>

                    <div class="mb-3">
                        <label class="form-label">Título *</label>
                        <input type="text" name="titulo" class="form-control @error('titulo') is-invalid @enderror" 
                               value="{{ old('titulo') }}" required maxlength="200" placeholder="Ej: Perro Labrador perdido - Max">
                        @error('titulo')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="mb-3">
                        <label class="form-label">Descripción Detallada *</label>
                        <textarea name="descripcion" class="form-control @error('descripcion') is-invalid @enderror" 
                                  rows="4" required placeholder="Describe los detalles del objeto o persona">{{ old('descripcion') }}</textarea>
                        @error('descripcion')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Fecha de Pérdida/Hallazgo</label>
                            <input type="datetime-local" name="fecha_perdida" class="form-control" value="{{ old('fecha_perdida') }}">
                        </div>

                        <div class="col-md-6 mb-3">
                            <label class="form-label">Dirección/Referencia</label>
                            <input type="text" name="direccion_referencia" class="form-control" 
                                   value="{{ old('direccion_referencia') }}" placeholder="Ej: Cerca del parque central">
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-4 mb-3">
                            <label class="form-label">Prioridad</label>
                            <select name="prioridad" class="form-select">
                                <option value="baja">Baja</option>
                                <option value="normal" selected>Normal</option>
                                <option value="alta">Alta</option>
                                <option value="urgente">Urgente</option>
                            </select>
                        </div>

                        <div class="col-md-4 mb-3">
                            <label class="form-label">Recompensa (Bs.)</label>
                            <input type="number" name="recompensa" class="form-control" 
                                   value="{{ old('recompensa') }}" min="0" step="0.01" placeholder="0.00">
                        </div>

                        <div class="col-md-4 mb-3">
                            <label class="form-label">Estado</label>
                            <select name="estado" class="form-select">
                                <option value="activo" selected>Activo</option>
                                <option value="inactivo">Inactivo</option>
                            </select>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-4 mb-3">
                            <label class="form-label">Contacto Público</label>
                            <select name="contacto_publico" class="form-select">
                                <option value="1" selected>Sí</option>
                                <option value="0">No</option>
                            </select>
                        </div>

                        <div class="col-md-4 mb-3">
                            <label class="form-label">Teléfono de Contacto</label>
                            <input type="text" name="telefono_contacto" class="form-control" 
                                   value="{{ old('telefono_contacto') }}" placeholder="+591 70123456">
                        </div>

                        <div class="col-md-4 mb-3">
                            <label class="form-label">Email de Contacto</label>
                            <input type="email" name="email_contacto" class="form-control" 
                                   value="{{ old('email_contacto') }}" placeholder="correo@ejemplo.com">
                        </div>
                    </div>

                    <div class="d-flex justify-content-end gap-2 mt-4">
                        <a href="{{ route('reportes.index') }}" class="btn btn-secondary">
                            <i class="bi bi-x-circle me-1"></i> Cancelar
                        </a>
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-check-circle me-1"></i> Crear Reporte
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
@endsection