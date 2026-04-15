@extends('layouts.app')

@section('title', 'Editar Configuración')
@section('page-title', 'Editar Configuración del Sistema')

@section('content')
<div class="row justify-content-center">
    <div class="col-lg-10">
        <form action="{{ route('configuracion.update') }}" method="POST">
            @csrf
            @method('PUT')
            
            <div class="card border-0 shadow-sm mb-4">
                <div class="card-header bg-white border-0 py-3">
                    <div class="d-flex justify-content-between align-items-center">
                        <h5 class="mb-0 fw-bold text-primary">
                            <i class="bi bi-sliders me-2"></i>Ajustes Generales
                        </h5>
                        <a href="{{ route('configuracion.index') }}" class="btn btn-outline-secondary btn-sm">
                            <i class="bi bi-arrow-left me-1"></i>Cancelar
                        </a>
                    </div>
                </div>
                
                <div class="card-body p-4">
                    @if($errors->any())
                        <div class="alert alert-danger mb-4 rounded-3 border-0 shadow-sm">
                            <div class="d-flex">
                                <i class="bi bi-exclamation-triangle-fill fs-4 me-3"></i>
                                <div>
                                    <h6 class="fw-bold mb-1">Hay errores en el formulario</h6>
                                    <ul class="mb-0 ps-3">
                                        @foreach($errors->all() as $error)
                                            <li>{{ $error }}</li>
                                        @endforeach
                                    </ul>
                                </div>
                            </div>
                        </div>
                    @endif

                    <div class="alert alert-info border-0 bg-info-subtle text-info-emphasis mb-4">
                        <i class="bi bi-info-circle-fill me-2"></i>
                        Los cambios realizados afectarán a todo el sistema inmediatamente.
                    </div>

                    <div class="row g-4">
                        @foreach($configuraciones as $config)
                            <div class="col-md-6">
                                <div class="form-group h-100 p-3 rounded-3 bg-light border border-light-subtle transition-hover">
                                    <label for="{{ $config->clave }}" class="form-label fw-bold text-dark d-flex align-items-center mb-2">
                                        @if($config->tipo == 'boolean')
                                            <i class="bi bi-toggle-on text-success me-2"></i>
                                        @elseif($config->tipo == 'integer' || $config->tipo == 'decimal')
                                            <i class="bi bi-123 text-info me-2"></i>
                                        @else
                                            <i class="bi bi-type-text text-primary me-2"></i>
                                        @endif
                                        {{ str_replace('_', ' ', $config->clave) }}
                                    </label>
                                    
                                    @if($config->tipo == 'boolean')
                                        <div class="form-check form-switch mt-2">
                                            <input type="hidden" name="config[{{ $config->clave }}]" value="0">
                                            <input class="form-check-input" type="checkbox" role="switch" 
                                                   id="{{ $config->clave }}" 
                                                   name="config[{{ $config->clave }}]" 
                                                   value="1" 
                                                   {{ old('config.'.$config->clave, $config->valor) ? 'checked' : '' }}
                                                   style="width: 3em; height: 1.5em;">
                                            <label class="form-check-label ms-2 pt-1 text-muted" for="{{ $config->clave }}">
                                                {{ $config->descripcion }}
                                            </label>
                                        </div>
                                    @elseif($config->tipo == 'integer')
                                        <input type="number" class="form-control" 
                                               id="{{ $config->clave }}" 
                                               name="config[{{ $config->clave }}]" 
                                               value="{{ old('config.'.$config->clave, $config->valor) }}">
                                        <div class="form-text text-muted mt-2 small">
                                            {{ $config->descripcion }}
                                        </div>
                                    @elseif($config->tipo == 'json')
                                        <textarea class="form-control font-monospace" 
                                                  id="{{ $config->clave }}" 
                                                  name="config[{{ $config->clave }}]" 
                                                  rows="3">{{ old('config.'.$config->clave, is_array($config->valor) ? json_encode($config->valor) : $config->valor) }}</textarea>
                                        <div class="form-text text-muted mt-2 small">
                                            Formato JSON válido requerido. {{ $config->descripcion }}
                                        </div>
                                    @else
                                        <input type="text" class="form-control" 
                                               id="{{ $config->clave }}" 
                                               name="config[{{ $config->clave }}]" 
                                               value="{{ old('config.'.$config->clave, $config->valor) }}">
                                        <div class="form-text text-muted mt-2 small">
                                            {{ $config->descripcion }}
                                        </div>
                                    @endif
                                </div>
                            </div>
                        @endforeach
                    </div>
                </div>
                
                <div class="card-footer bg-white border-0 py-4 px-4 text-end">
                    <button type="submit" class="btn btn-primary btn-lg rounded-pill px-5 shadow-sm">
                        <i class="bi bi-save me-2"></i>Guardar Cambios
                    </button>
                </div>
            </div>
        </form>
    </div>
</div>

<style>
    .transition-hover {
        transition: all 0.2s ease;
    }
    .transition-hover:hover {
        background-color: #fff !important;
        box-shadow: 0 .5rem 1rem rgba(0,0,0,.05);
        border-color: #dee2e6 !important;
    }
</style>
@endsection
