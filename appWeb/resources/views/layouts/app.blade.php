<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'Amigate - Admin')</title>
    
    
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    
    <link href="https://cdn.datatables.net/1.13.6/css/dataTables.bootstrap5.min.css" rel="stylesheet">
    
    <style>
        :root {
            --primary-color: #2563eb;
            --secondary-color: #1e40af;
            --success-color: #51CF66;
            --warning-color: #FFD93D;
            --danger-color: #FF6B6B;
            --sidebar-width: 260px;
            --sidebar-dark: #1e293b;
            --sidebar-darker: #0f172a;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        html {
            overflow-x: hidden;
            width: 100%;
            max-width: 100%;
            font-size: 90%; /* Efecto de "Zoom Out" para toda la app */
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            min-height: 100vh;
            overflow-x: hidden;
            width: 100%;
            max-width: 100%;
            position: relative;
        }
        
        /* Bootstrap Primary Color Override */
        .bg-primary {
            background-color: #2563eb !important;
        }
        
        .text-primary {
            color: #2563eb !important;
        }
        
        .btn-primary {
            background-color: #2563eb;
            border-color: #2563eb;
        }
        
        .btn-primary:hover {
            background-color: #1d4ed8;
            border-color: #1d4ed8;
        }
        
        .border-primary {
            border-color: #2563eb !important;
        }
        
        .bg-primary-subtle {
            background-color: rgba(37, 99, 235, 0.1) !important;
        }
        
        /* Sidebar */
        .sidebar {
            position: fixed;
            top: 0;
            left: 0;
            width: var(--sidebar-width);
            height: 100vh; /* Altura fija para poder hacer scroll */
            background: linear-gradient(180deg, var(--sidebar-dark) 0%, var(--sidebar-darker) 100%);
            box-shadow: 4px 0 20px rgba(0,0,0,0.15);
            z-index: 1050; /* Que se vea encima de todo */
            overflow-y: auto;
            overflow-x: hidden;
            display: flex;
            flex-direction: column;
        }
        
        .sidebar::-webkit-scrollbar {
            width: 6px;
        }
        
        .sidebar::-webkit-scrollbar-track {
            background: rgba(255,255,255,0.1);
        }
        
        .sidebar::-webkit-scrollbar-thumb {
            background: rgba(255,255,255,0.3);
            border-radius: 10px;
        }
        
        .sidebar::-webkit-scrollbar-thumb:hover {
            background: rgba(255,255,255,0.5);
        }
        
        .sidebar-header {
            padding: 25px 20px;
            border-bottom: 1px solid rgba(255,255,255,0.1);
            background: rgba(0,0,0,0.2);
        }
        
        .sidebar-header h4 {
            color: white;
            font-weight: 700;
            font-size: 1.5rem;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .sidebar-header p {
            color: rgba(255,255,255,0.8);
            font-size: 0.85rem;
            margin: 5px 0 0 0;
        }
        
        .sidebar .nav {
            padding: 20px 10px 50px 10px; /* Espacio extra abajo para que no se corte */
            flex: 1;
        }
        
        .sidebar .nav-link {
            color: rgba(255,255,255,0.85);
            padding: 14px 18px;
            margin: 4px 0;
            border-radius: 12px;
            transition: background-color 0.2s ease, color 0.2s ease, transform 0.2s ease;
            display: flex;
            align-items: center;
            font-weight: 500;
            position: relative;
            overflow: hidden;
        }
        
        .sidebar .nav-link::before {
            content: '';
            position: absolute;
            left: 0;
            top: 0;
            height: 100%;
            width: 4px;
            background: white;
            transform: scaleY(0);
            transition: transform 0.3s ease;
        }
        
        .sidebar .nav-link:hover {
            color: white;
            background: rgba(255,255,255,0.15);
            transform: translateX(3px);
        }
        
        .sidebar .nav-link:hover::before {
            transform: scaleY(1);
        }
        
        .sidebar .nav-link.active {
            color: white;
            background: rgba(255,255,255,0.25);
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        }
        
        .sidebar .nav-link.active::before {
            transform: scaleY(1);
        }
        
        .sidebar .nav-link i {
            margin-right: 12px;
            width: 24px;
            font-size: 1.1rem;
            text-align: center;
        }
        
        /* Main Content */
        .main-content {
            margin-left: var(--sidebar-width);
            min-height: 100vh;
            transition: margin-left 0.3s ease;
            width: calc(100% - var(--sidebar-width));
            max-width: calc(100% - var(--sidebar-width));
            overflow-x: hidden;
        }
        
        /* Top Navbar */
        .top-navbar {
            background: white;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            padding: 15px 30px;
            margin-bottom: 25px;
            border-radius: 0 0 15px 15px;
            position: sticky;
            top: 0;
            z-index: 999;
            width: 100%;
            max-width: 100%;
            overflow-x: hidden;
        }
        
        .top-navbar .navbar-brand {
            font-size: 1.5rem;
            font-weight: 700;
            background: linear-gradient(135deg, #2563eb 0%, #1e40af 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        
        .user-info {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 8px 16px;
            background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
            border-radius: 25px;
            border: 2px solid #e0e0e0;
        }
        
        .user-info i {
            font-size: 1.5rem;
            color: #2563eb;
        }
        
        /* Cards */
        .card {
            border: none;
            border-radius: 15px;
            box-shadow: 0 2px 15px rgba(0,0,0,0.08);
            margin-bottom: 25px;
            transition: box-shadow 0.2s ease, transform 0.2s ease;
            overflow: hidden;
            width: 100%;
            max-width: 100%;
        }
        
        .card:hover {
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
            transform: translateY(-1px);
        }
        
        /* Sidebar Compacto */
        .sidebar {
            padding-top: 10px !important;
            padding-bottom: 10px !important;
        }
        .sidebar-brand {
            padding: 10px 20px !important;
            margin-bottom: 10px !important;
        }
        .sidebar .nav-link {
            padding: 8px 15px !important;
            font-size: 0.95rem !important;
        }
        .sidebar-heading {
            padding: 5px 15px !important;
            font-size: 0.75rem !important;
            margin-top: 10px !important;
        }
        hr.sidebar-divider {
            margin: 10px 0 !important;
        }
        
        .card-header {
            background: white;
            border-bottom: 2px solid #f0f0f0;
            padding: 20px 25px;
            border-radius: 15px 15px 0 0 !important;
        }
        
        .card-body {
            padding: 25px;
        }
        
        /* Buttons */
        .btn-primary {
            background: linear-gradient(135deg, #2563eb 0%, #1e40af 100%);
            border: none;
            padding: 10px 25px;
            border-radius: 10px;
            font-weight: 600;
            transition: box-shadow 0.2s ease, transform 0.2s ease, background 0.2s ease;
            box-shadow: 0 4px 15px rgba(37, 99, 235, 0.3);
        }
        
        .btn-primary:hover {
            transform: translateY(-1px);
            box-shadow: 0 5px 18px rgba(37, 99, 235, 0.35);
            background: linear-gradient(135deg, #1d4ed8 0%, #1e3a8a 100%);
        }
        
        .btn-outline-primary {
            border: 2px solid #2563eb;
            color: #2563eb;
            font-weight: 600;
            border-radius: 10px;
            transition: background 0.2s ease, border-color 0.2s ease, color 0.2s ease, transform 0.2s ease;
        }
        
        .btn-outline-primary:hover {
            background: linear-gradient(135deg, #2563eb 0%, #1e40af 100%);
            border-color: transparent;
            transform: translateY(-1px);
            color: white;
        }
        
        /* Tables */
        .table {
            background: white;
            border-radius: 10px;
            overflow: hidden;
            width: 100%;
            max-width: 100%;
        }
        
        .table-responsive {
            overflow-x: auto;
            -webkit-overflow-scrolling: touch;
        }
        
        .table thead {
            background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
        }
        
        .table thead th {
            font-weight: 700;
            text-transform: uppercase;
            font-size: 0.75rem;
            letter-spacing: 0.5px;
            color: #495057;
            border: none;
            padding: 15px;
        }
        
        .table tbody tr {
            transition: background-color 0.15s ease;
            border-bottom: 1px solid #f0f0f0;
        }
        
        .table tbody tr:hover {
            background-color: #f8f9fa;
        }
        
        .table tbody td {
            padding: 15px;
            vertical-align: middle;
        }
        
        /* Badges */
        .badge {
            padding: 6px 12px;
            border-radius: 8px;
            font-weight: 600;
            font-size: 0.75rem;
        }
        
        /* Alerts */
        .alert {
            border-radius: 12px;
            border: none;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            padding: 15px 20px;
        }
        
        /* Content Wrapper */
        .content-wrapper {
            padding: 0 30px 30px 30px;
            width: 100%;
            max-width: 100%;
            overflow-x: hidden;
        }
        
        /* Stats Cards */
        .stats-card {
            padding: 25px;
            border-radius: 15px;
            color: white;
            margin-bottom: 20px;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }
        
        /* Animación pulse desactivada para mejor rendimiento */
        .stats-card::before {
            display: none;
        }
        
        .stats-card i {
            font-size: 2.5rem;
            opacity: 0.9;
            position: relative;
            z-index: 1;
        }
        
        /* Sidebar Overlay para móvil */
        .sidebar-overlay {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            z-index: 999;
            transition: opacity 0.3s ease;
        }
        
        .sidebar-overlay.show {
            display: block;
        }
        
        /* Botón hamburguesa */
        .sidebar-toggle {
            display: none;
            position: fixed;
            top: 15px;
            left: 15px;
            z-index: 1001;
            background: var(--sidebar-dark);
            color: white;
            border: none;
            width: 45px;
            height: 45px;
            border-radius: 10px;
            font-size: 1.3rem;
            cursor: pointer;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
            transition: all 0.3s ease;
        }
        
        .sidebar-toggle:hover {
            background: var(--sidebar-darker);
            transform: scale(1.05);
        }
        
        /* Prevenir scroll horizontal global */
        .container-fluid,
        .row,
        [class*="container"],
        [class*="col-"] {
            max-width: 100%;
        }
        
        /* Responsive */
        @media (max-width: 991.98px) {
            .sidebar {
                transform: translateX(-100%);
                transition: transform 0.3s ease;
                z-index: 1000;
            }
            
            .sidebar.show {
                transform: translateX(0);
            }
            
            .main-content {
                margin-left: 0 !important;
                width: 100% !important;
                max-width: 100% !important;
            }
            
            .container-fluid {
                padding-left: 0 !important;
                padding-right: 0 !important;
                margin-left: 0 !important;
                margin-right: 0 !important;
                width: 100% !important;
                max-width: 100% !important;
            }
            
            .row {
                margin-left: 0 !important;
                margin-right: 0 !important;
            }
            
            [class*="col-"] {
                padding-left: 10px;
                padding-right: 10px;
            }
            
            .sidebar-toggle {
                display: flex;
                align-items: center;
                justify-content: center;
            }
            
            .top-navbar {
                padding-left: 70px;
                padding-right: 15px;
            }
            
            .content-wrapper {
                padding: 0 15px 20px 15px;
                width: 100%;
                max-width: 100%;
            }
        }
        
        @media (max-width: 767.98px) {
            .top-navbar {
                padding: 12px 10px 12px 60px !important;
                margin-bottom: 15px;
                border-radius: 0 0 12px 12px;
                width: 100% !important;
                max-width: 100% !important;
            }
            
            .top-navbar .d-flex {
                flex-wrap: wrap;
                gap: 8px;
            }
            
            .top-navbar .navbar-brand {
                font-size: 1.1rem !important;
                word-break: break-word;
            }
            
            .top-navbar .navbar-brand {
                font-size: 1.2rem;
            }
            
            .user-info {
                padding: 6px 12px;
                gap: 8px;
            }
            
            .user-info i {
                font-size: 1.2rem;
            }
            
            .user-info strong,
            .user-info small {
                font-size: 0.75rem;
            }
            
            .sidebar-header {
                padding: 20px 15px;
            }
            
            .sidebar-header h4 {
                font-size: 1.2rem;
            }
            
            .sidebar .nav {
                padding: 15px 8px;
            }
            
            .sidebar .nav-link {
                padding: 12px 15px;
                font-size: 0.9rem;
            }
            
            .sidebar .nav-link i {
                font-size: 1rem;
                width: 20px;
            }
            
            .content-wrapper {
                padding: 0 10px 15px 10px !important;
                width: 100% !important;
                max-width: 100% !important;
            }
            
            .top-navbar {
                width: 100% !important;
                max-width: 100% !important;
            }
            
            .top-navbar .d-flex {
                flex-wrap: wrap;
                gap: 10px;
            }
            
            .user-info {
                flex-wrap: wrap;
            }
            
            /* Prevenir overflow en todos los elementos */
            * {
                max-width: 100%;
            }
            
            img {
                max-width: 100%;
                height: auto;
            }
            
            .card,
            .card-body,
            .card-header {
                max-width: 100%;
                overflow-x: hidden;
            }
            
            /* Asegurar que las tablas sean responsive */
            .table-responsive {
                overflow-x: auto;
                -webkit-overflow-scrolling: touch;
                width: 100%;
            }
            
            /* Prevenir que los elementos se salgan */
            .btn,
            .badge,
            .alert {
                max-width: 100%;
                word-wrap: break-word;
            }
            
            /* Ajustar textos largos */
            h1, h2, h3, h4, h5, h6,
            p, span, div, a {
                word-wrap: break-word;
                overflow-wrap: break-word;
            }
        }
        
        @media (max-width: 575.98px) {
            .sidebar-toggle {
                width: 40px;
                height: 40px;
                font-size: 1.1rem;
                top: 10px;
                left: 10px;
            }
            
            .top-navbar {
                padding: 10px 10px 10px 60px;
            }
            
            .top-navbar .navbar-brand {
                font-size: 1rem;
            }
            
            .user-info {
                padding: 5px 10px;
                gap: 6px;
            }
            
            .user-info div {
                display: none;
            }
            
            .sidebar {
                width: 240px;
            }
        }
        
        /* Animations - Optimizadas */
        @keyframes fadeIn {
            from {
                opacity: 0;
            }
            to {
                opacity: 1;
            }
        }
        
        /* Desactivar animaciones para usuarios que prefieren movimiento reducido */
        @media (prefers-reduced-motion: reduce) {
            *,
            *::before,
            *::after {
                animation-duration: 0.01ms !important;
                animation-iteration-count: 1 !important;
                transition-duration: 0.01ms !important;
            }
        }
        
        /* Elementos visibles por defecto */
        .content-wrapper > * {
            opacity: 1;
        }
        
        /* GPU Acceleration para mejor rendimiento */
        .sidebar,
        .main-content,
        .card,
        .btn {
            will-change: transform;
            transform: translateZ(0);
            backface-visibility: hidden;
        }
    </style>
    
    @stack('styles')
</head>
<body>
    
    <button class="sidebar-toggle" id="sidebarToggle" aria-label="Toggle sidebar">
        <i class="bi bi-list"></i>
    </button>
    
    
    <div class="sidebar-overlay" id="sidebarOverlay"></div>
    
    <div class="container-fluid p-0" style="overflow-x: hidden; max-width: 100%;">
        <div class="row g-0" style="margin: 0; max-width: 100%;">
            
            <nav class="sidebar" id="sidebar">
                <div class="sidebar-header">
                    <h4>
                        <i class="bi bi-search-heart"></i>
                        Amigate
                    </h4>
                    <p>Panel de Administración</p>
                </div>
                
                <ul class="nav flex-column">
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('dashboard') ? 'active' : '' }}" href="{{ route('dashboard') }}">
                            <i class="bi bi-speedometer2"></i>
                            <span>Dashboard</span>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('usuarios.*') ? 'active' : '' }}" href="{{ route('usuarios.index') }}">
                            <i class="bi bi-people"></i>
                            <span>Usuarios</span>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('reportes.*') ? 'active' : '' }}" href="{{ route('reportes.index') }}">
                            <i class="bi bi-file-earmark-text"></i>
                            <span>Reportes</span>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('estadisticas.*') ? 'active' : '' }}" href="{{ route('estadisticas.index') }}">
                            <i class="bi bi-graph-up"></i>
                            <span>Estadísticas</span>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('categorias.*') ? 'active' : '' }}" href="{{ route('categorias.index') }}">
                            <i class="bi bi-tags"></i>
                            <span>Categorías</span>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('cuadrantes.*') ? 'active' : '' }}" href="{{ route('cuadrantes.index') }}">
                            <i class="bi bi-grid-3x3"></i>
                            <span>Cuadrantes</span>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('grupos.*') ? 'active' : '' }}" href="{{ route('grupos.index') }}">
                            <i class="bi bi-people-fill"></i>
                            <span>Grupos</span>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('respuestas.*') ? 'active' : '' }}" href="{{ route('respuestas.index') }}">
                            <i class="bi bi-chat-dots"></i>
                            <span>Respuestas</span>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('notificaciones.*') ? 'active' : '' }}" href="{{ route('notificaciones.index') }}">
                            <i class="bi bi-bell"></i>
                            <span>Notificaciones</span>
                        </a>
                    </li>
                    @role('administrador')
                    <li class="nav-item mt-3">
                        <a class="nav-link {{ request()->routeIs('users.roles.*') ? 'active' : '' }}" href="{{ route('users.roles.index') }}">
                            <i class="bi bi-shield-lock"></i>
                            <span>Gestión de Roles</span>
                        </a>
                    </li>
                    @endrole
                    <li class="nav-item mt-3">
                        <a class="nav-link {{ request()->routeIs('configuracion.*') ? 'active' : '' }}" href="{{ route('configuracion.index') }}">
                            <i class="bi bi-gear"></i>
                            <span>Configuración</span>
                        </a>
                    </li>
                </ul>
            </nav>

            
            <main class="main-content col-12">
                
                <nav class="top-navbar">
                    <div class="d-flex justify-content-between align-items-center">
                        <h1 class="navbar-brand mb-0">@yield('page-title', 'Dashboard')</h1>
                        <div class="d-flex align-items-center gap-3">
                            <div class="user-info">
                                <i class="bi bi-person-circle"></i>
                                <div>
                                    <strong class="d-block" style="font-size: 0.9rem;">{{ Auth::user()->name ?? 'Administrador' }}</strong>
                                    <small class="text-muted" style="font-size: 0.75rem;">{{ Auth::user()->email ?? 'Sistema' }}</small>
                                </div>
                            </div>
                            <form action="{{ route('logout') }}" method="POST" class="d-inline">
                                @csrf
                                <button type="submit" class="btn btn-outline-danger btn-sm" title="Cerrar Sesión">
                                    <i class="bi bi-box-arrow-right me-1"></i>Salir
                                </button>
                            </form>
                        </div>
                    </div>
                </nav>

                
                @if(session('success'))
                    <div class="content-wrapper">
                        <div class="alert alert-success alert-dismissible fade show" role="alert">
                            <i class="bi bi-check-circle-fill me-2"></i>
                            <strong>¡Éxito!</strong> {{ session('success') }}
                            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                        </div>
                    </div>
                @endif

                @if(session('error'))
                    <div class="content-wrapper">
                        <div class="alert alert-danger alert-dismissible fade show" role="alert">
                            <i class="bi bi-exclamation-triangle-fill me-2"></i>
                            <strong>Error!</strong> {{ session('error') }}
                            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                        </div>
                    </div>
                @endif

                
                <div class="content-wrapper">
                    @yield('content')
                </div>
            </main>
        </div>
    </div>

    
    <script src="https://code.jquery.com/jquery-3.7.0.min.js"></script>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    
    <script src="https://cdn.datatables.net/1.13.6/js/jquery.dataTables.min.js"></script>
    <script src="https://cdn.datatables.net/1.13.6/js/dataTables.bootstrap5.min.js"></script>
    
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    
    <script>
        // Suprimir warnings de DataTables en consola
        $.fn.dataTable.ext.errMode = 'none';
        
        // Inicializar DataTables - Optimizado con validación robusta
        $(document).ready(function() {
            // Delay para asegurar que el DOM esté completamente renderizado
            setTimeout(function() {
                $('.data-table').each(function() {
                    var $table = $(this);
                    
                    // Verificar que la tabla tenga estructura válida
                    var $thead = $table.find('thead');
                    var $tbody = $table.find('tbody');
                    
                    if (!$thead.length || !$tbody.length) {
                        return; // Saltar si no tiene thead o tbody
                    }
                    
                    var headerCols = $thead.find('th').length;
                    if (headerCols === 0) {
                        return; // Saltar si no tiene columnas en el header
                    }
                    
                    // Buscar la primera fila sin colspan para validar
                    var $dataRows = $tbody.find('tr').filter(function() {
                        return $(this).find('td[colspan]').length === 0;
                    });
                    
                    var isValid = true;
                    var firstRowCols = 0;
                    
                    if ($dataRows.length > 0) {
                        // Hay filas con datos, verificar que todas tengan el mismo número de columnas
                        firstRowCols = $dataRows.first().find('td').length;
                        
                        // Verificar que todas las filas tengan el mismo número de columnas
                        $dataRows.each(function() {
                            var rowCols = $(this).find('td').length;
                            if (rowCols !== headerCols) {
                                isValid = false;
                                return false; // break
                            }
                        });
                    } else {
                        // Solo hay filas vacías (con colspan), está bien
                        firstRowCols = headerCols;
                    }
                    
                    // Solo inicializar si es válido
                    if (isValid && headerCols === firstRowCols) {
                        try {
                            // Verificar si DataTables ya está inicializado
                            if ($.fn.DataTable.isDataTable($table)) {
                                $table.DataTable().destroy();
                            }
                            
                            $table.DataTable({
                    language: {
                        url: '//cdn.datatables.net/plug-ins/1.13.6/i18n/es-ES.json'
                    },
                    pageLength: 25,
                    responsive: true,
                                autoWidth: false,
                    dom: '<"row"<"col-sm-12 col-md-6"l><"col-sm-12 col-md-6"f>>rt<"row"<"col-sm-12 col-md-5"i><"col-sm-12 col-md-7"p>>',
                    deferRender: true,
                                processing: true,
                                columnDefs: [
                                    { orderable: false, targets: -1 } // Deshabilitar ordenamiento en última columna (Acciones)
                                ],
                                // Suprimir warnings adicionales
                                initComplete: function() {
                                    // Forzar recálculo de columnas
                                    try {
                                        this.api().columns.adjust();
                                    } catch(e) {
                                        // Ignorar errores en el ajuste
                                    }
                                }
                            });
                        } catch (e) {
                            // Silenciar errores - no inicializar DataTables si hay problemas
                            console.debug('DataTables no inicializado para esta tabla:', e);
                        }
                    } else {
                        // No inicializar DataTables si hay problemas
                        console.debug('DataTables: Tabla omitida. Header:', headerCols, 'Body:', firstRowCols, 'Válida:', isValid);
                    }
                });
            }, 200); // Aumentar delay a 200ms para mayor seguridad
        });

        // Confirmación de eliminación
        function confirmarEliminacion(form) {
            event.preventDefault();
            Swal.fire({
                title: '¿Estás seguro?',
                text: "Esta acción no se puede deshacer",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#d33',
                cancelButtonColor: '#3085d6',
                confirmButtonText: 'Sí, eliminar',
                cancelButtonText: 'Cancelar',
                background: 'white',
                customClass: {
                    popup: 'rounded-4',
                    confirmButton: 'btn btn-danger',
                    cancelButton: 'btn btn-secondary'
                }
            }).then((result) => {
                if (result.isConfirmed) {
                    form.submit();
                }
            });
        }
        
        // Sidebar toggle para móvil
        const sidebar = $('#sidebar');
        const sidebarToggle = $('#sidebarToggle');
        const sidebarOverlay = $('#sidebarOverlay');
        
        function toggleSidebar() {
            sidebar.toggleClass('show');
            sidebarOverlay.toggleClass('show');
            
            // Cambiar icono del botón
            const icon = sidebarToggle.find('i');
            if (sidebar.hasClass('show')) {
                icon.removeClass('bi-list').addClass('bi-x');
            } else {
                icon.removeClass('bi-x').addClass('bi-list');
            }
        }
        
        // Toggle al hacer clic en el botón
        sidebarToggle.on('click', function(e) {
            e.stopPropagation();
            toggleSidebar();
        });
        
        // Cerrar sidebar al hacer clic en el overlay
        sidebarOverlay.on('click', function() {
            sidebar.removeClass('show');
            sidebarOverlay.removeClass('show');
            sidebarToggle.find('i').removeClass('bi-x').addClass('bi-list');
        });
        
        // Cerrar sidebar al hacer clic en un link (solo en móvil)
        if (window.innerWidth <= 991) {
            $('.sidebar .nav-link').on('click', function() {
                setTimeout(function() {
                    sidebar.removeClass('show');
                    sidebarOverlay.removeClass('show');
                    sidebarToggle.find('i').removeClass('bi-x').addClass('bi-list');
                }, 300);
            });
        }
        
        // Ajustar en resize
        $(window).on('resize', function() {
            if (window.innerWidth > 991) {
                sidebar.removeClass('show');
                sidebarOverlay.removeClass('show');
                sidebarToggle.find('i').removeClass('bi-x').addClass('bi-list');
            }
        });
    </script>
    
    @stack('scripts')
</body>
</html>
