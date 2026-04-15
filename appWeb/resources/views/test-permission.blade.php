@extends('layouts.app')

@section('title', 'Prueba de Permisos')

@section('content')
<div class="container-fluid py-4">
    <div class="row">
        <div class="col-12">
            <div class="card shadow-sm">
                <div class="card-header bg-primary text-white">
                    <h4 class="mb-0">
                        <i class="bi bi-shield-check"></i> Prueba de Roles y Permisos - Spatie Permission
                    </h4>
                </div>
                <div class="card-body">
                    
                    <div class="mb-4">
                        <h5 class="text-primary">
                            <i class="bi bi-person-circle"></i> Usuario Actual
                        </h5>
                        <div class="alert alert-info">
                            <strong>Nombre:</strong> {{ $user->name }}<br>
                            <strong>Email:</strong> {{ $user->email }}<br>
                            <strong>ID:</strong> {{ $user->id }}
                        </div>
                    </div>

                    
                    <div class="mb-4">
                        <h5 class="text-success">
                            <i class="bi bi-tags"></i> Roles Asignados
                        </h5>
                        @if($userRoles->count() > 0)
                            <div class="d-flex flex-wrap gap-2">
                                @foreach($userRoles as $role)
                                    <span class="badge bg-success fs-6">{{ $role }}</span>
                                @endforeach
                            </div>
                        @else
                            <div class="alert alert-warning">
                                <i class="bi bi-exclamation-triangle"></i> Este usuario no tiene roles asignados.
                            </div>
                        @endif
                    </div>

                    
                    <div class="mb-4">
                        <h5 class="text-info">
                            <i class="bi bi-key"></i> Permisos del Usuario
                        </h5>
                        @if($userPermissions->count() > 0)
                            <div class="d-flex flex-wrap gap-2">
                                @foreach($userPermissions as $permission)
                                    <span class="badge bg-info text-dark fs-6">{{ $permission }}</span>
                                @endforeach
                            </div>
                        @else
                            <div class="alert alert-warning">
                                <i class="bi bi-exclamation-triangle"></i> Este usuario no tiene permisos asignados directamente.
                            </div>
                        @endif
                    </div>

                    
                    <div class="mb-4">
                        <h5 class="text-warning">
                            <i class="bi bi-check2-circle"></i> Verificaciones de Permisos
                        </h5>
                        <table class="table table-bordered">
                            <thead>
                                <tr>
                                    <th>Verificación</th>
                                    <th>Resultado</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($checks as $check => $result)
                                    <tr>
                                        <td>{{ $check }}</td>
                                        <td>
                                            @if($result)
                                                <span class="badge bg-success">
                                                    <i class="bi bi-check-circle"></i> Permitido
                                                </span>
                                            @else
                                                <span class="badge bg-danger">
                                                    <i class="bi bi-x-circle"></i> Denegado
                                                </span>
                                            @endif
                                        </td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>

                    
                    <div class="mb-4">
                        <h5 class="text-secondary">
                            <i class="bi bi-link-45deg"></i> Pruebas de Rutas Protegidas
                        </h5>
                        <div class="d-flex flex-wrap gap-2">
                            <a href="{{ route('test.admin') }}" class="btn btn-danger">
                                Ruta Solo Admin
                            </a>
                            <a href="{{ route('test.editor') }}" class="btn btn-warning">
                                Ruta Solo Editor
                            </a>
                        </div>
                        <small class="text-muted d-block mt-2">
                            Estas rutas están protegidas por middleware de roles. Si no tienes el rol necesario, verás un error 403.
                        </small>
                    </div>

                    
                    <div class="mb-4">
                        <h5 class="text-primary">
                            <i class="bi bi-list-ul"></i> Todos los Roles Disponibles en el Sistema
                        </h5>
                        <div class="d-flex flex-wrap gap-2">
                            @foreach($allRoles as $role)
                                <span class="badge bg-secondary fs-6">
                                    {{ $role->name }} 
                                    <small>({{ $role->permissions->count() }} permisos)</small>
                                </span>
                            @endforeach
                        </div>
                    </div>

                    
                    <div class="mb-4">
                        <h5 class="text-primary">
                            <i class="bi bi-list-ul"></i> Todos los Permisos Disponibles en el Sistema
                        </h5>
                        <div class="d-flex flex-wrap gap-2">
                            @foreach($allPermissions as $permission)
                                <span class="badge bg-light text-dark border fs-6">
                                    {{ $permission->name }}
                                </span>
                            @endforeach
                        </div>
                    </div>

                    
                    <div class="alert alert-secondary">
                        <h6><i class="bi bi-info-circle"></i> ¿Qué hace Spatie Permission?</h6>
                        <ul class="mb-0">
                            <li><strong>Roles:</strong> Agrupa permisos. Un usuario puede tener varios roles.</li>
                            <li><strong>Permisos:</strong> Acciones específicas que un usuario puede realizar.</li>
                            <li><strong>Herencia:</strong> Los permisos se pueden asignar directamente al usuario o a través de roles.</li>
                            <li><strong>Middleware:</strong> Puedes proteger rutas con <code>role:administrador</code> o <code>permission:ver usuarios</code></li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
