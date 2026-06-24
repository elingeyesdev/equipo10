

@extends('layouts.app')

@section('title', 'Crear usuario')
@section('page-title', 'Crear nuevo usuario')

@section('content')
<div class="row">
    <div class="col-md-8 mx-auto">
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0">Nuevo usuario</h5>
            </div>
            <div class="card-body">
                <form action="{{ route('usuarios.store') }}" method="POST">
                    @csrf

                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Nombre completo *</label>
                            <input type="text" name="nombre" class="form-control @error('nombre') is-invalid @enderror" 
                                   value="{{ old('nombre') }}" required>
                            @error('nombre')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>

                        <div class="col-md-6 mb-3">
                            <label class="form-label">Email *</label>
                            <input type="email" name="email" class="form-control @error('email') is-invalid @enderror" 
                                   value="{{ old('email') }}" required>
                            @error('email')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Teléfono</label>
                            <input type="text" name="telefono" class="form-control @error('telefono') is-invalid @enderror" 
                                   value="{{ old('telefono') }}" placeholder="+591 70123456">
                            @error('telefono')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>

                        <div class="col-md-6 mb-3">
                            <label class="form-label">Avatar URL</label>
                            <input type="url" name="avatar_url" class="form-control @error('avatar_url') is-invalid @enderror" 
                                   value="{{ old('avatar_url') }}" placeholder="https://...">
                            @error('avatar_url')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6 mb-3">
                            <label class="form-label">Puntos de ayuda</label>
                            <input type="number" name="puntos_ayuda" class="form-control" value="{{ old('puntos_ayuda', 0) }}" min="0">
                        </div>

                        <div class="col-md-6 mb-3">
                            <label class="form-label">Estado</label>
                            <select name="activo" class="form-select">
                                <option value="1" {{ old('activo', 1) == 1 ? 'selected' : '' }}>Activo</option>
                                <option value="0" {{ old('activo') == 0 ? 'selected' : '' }}>Inactivo</option>
                            </select>
                        </div>
                    </div>

                    <div class="d-flex justify-content-end align-items-center gap-2 mt-2">
                        <a href="{{ route('usuarios.index') }}" class="btn btn-secondary">Cancelar</a>
                        <button type="submit" class="btn btn-primary">Guardar usuario</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
@endsection