<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'Echoes - Admin')</title>
    
    
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.0/font/bootstrap-icons.css">
    
    <link href="https://cdn.datatables.net/1.13.6/css/dataTables.bootstrap5.min.css" rel="stylesheet">
    
    <style>
        :root {
            /* Paleta Echoes — sincronizada con app_theme.dart */
            --bg-light:        #F8F8F8;
            --bg-base:         #ECECEC;
            --bg-dark:         #DFDFDF;
            --accent:          #E9C978;
            --accent-dark:     #E5C062;
            --accent-light:    #EDD28E;
            --primary-color:   #3F7AC5;
            --primary-base:    #5388CB;
            --primary-light:   #6796D1;
            --dark-base:       #353F4C;
            --dark-dark:       #2B333D;
            --dark-light:      #3F4B5B;
            --success-color:   #16A34A;
            --warning-color:   #F59E0B;
            --danger-color:    #EF4444;
            --sidebar-width:   260px;
            --sidebar-dark:    #353F4C;
            --sidebar-darker:  #2B333D;
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
            background-color: var(--bg-light);
            color: var(--dark-dark);
            min-height: 100vh;
            overflow-x: hidden;
            width: 100%;
            max-width: 100%;
            position: relative;
        }
        
        /* Bootstrap Color Override — paleta Echoes */
        .bg-primary {
            background-color: var(--primary-color) !important;
        }

        .text-primary {
            color: var(--primary-color) !important;
        }

        .btn-primary {
            background-color: var(--primary-color);
            border-color: var(--primary-color);
            color: white;
        }

        .btn-primary:hover {
            background-color: var(--primary-base);
            border-color: var(--primary-base);
            color: white;
        }

        .border-primary {
            border-color: var(--primary-color) !important;
        }

        .bg-primary-subtle {
            background-color: rgba(63, 122, 197, 0.1) !important;
        }
        
        /* Sidebar */
        .sidebar {
            position: fixed;
            top: 0;
            left: 0;
            width: var(--sidebar-width);
            height: 100vh;
            background-color: var(--sidebar-dark);
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
        
        .sidebar-header {
            display: flex;
            flex-direction: row;
            align-items: center;
            gap: 14px;
            text-align: left;
        }

        .sidebar-header img.sidebar-logo {
            width: 52px;
            height: 52px;
            object-fit: contain;
            border-radius: 10px;
            flex-shrink: 0;
        }

        .sidebar-header h4 {
            display: none;
        }

        .sidebar-welcome {
            display: flex;
            flex-direction: column;
            gap: 2px;
        }

        .sidebar-welcome span {
            color: rgba(255,255,255,0.65);
            font-size: 0.78rem;
            font-weight: 400;
        }

        .sidebar-welcome strong {
            color: white;
            font-size: 0.95rem;
            font-weight: 700;
            line-height: 1.2;
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
            background: var(--accent);
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
            color: var(--accent);
            background: rgba(233, 201, 120, 0.15);
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
            color: var(--primary-color);
        }
        
        .user-info {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 7px 14px;
            background-color: var(--bg-base);
            border-radius: 8px;
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
        
        /* Buttons — paleta Echoes */
        .btn-primary {
            background-color: var(--primary-color);
            border: none;
            color: white;
            padding: 10px 25px;
            border-radius: 8px;
            font-weight: 600;
            transition: background-color 0.2s ease;
        }

        .btn-primary:hover, .btn-primary:active, .btn-primary:focus {
            background-color: var(--primary-base);
            color: white;
            box-shadow: none;
        }

        .btn-outline-primary {
            background-color: var(--primary-color);
            border: none;
            color: white;
            font-weight: 600;
            border-radius: 8px;
            transition: background-color 0.2s ease;
        }

        .btn-outline-primary:hover {
            background-color: var(--primary-base);
            color: white;
        }

        /* Acciones de finalización/advertencia → dorado */
        .btn-warning, .btn-outline-warning {
            background-color: var(--accent);
            border: none;
            color: var(--dark-dark);
            font-weight: 600;
            border-radius: 8px;
            transition: background-color 0.2s ease;
        }

        .btn-warning:hover, .btn-outline-warning:hover {
            background-color: var(--accent-dark);
            color: var(--dark-dark);
        }

        /* Salir / cerrar sesión → dorado (finalización) */
        .btn-logout {
            background-color: var(--accent);
            border: none;
            color: var(--dark-dark);
            font-weight: 600;
            border-radius: 8px;
            padding: 6px 16px;
            font-size: 0.875rem;
            cursor: pointer;
            transition: background-color 0.2s ease;
        }

        .btn-logout:hover {
            background-color: var(--accent-dark);
            color: var(--dark-dark);
        }

        .btn-outline-danger {
            background-color: var(--danger-color);
            border: none;
            color: white;
            font-weight: 600;
            border-radius: 8px;
            transition: background-color 0.2s ease;
        }

        .btn-outline-danger:hover {
            background-color: #dc2626;
            color: white;
        }

        /* Override Bootstrap focus ring */
        .btn:focus, .btn:focus-visible,
        .form-control:focus, .form-select:focus {
            outline: none;
            box-shadow: 0 0 0 3px rgba(63, 122, 197, 0.2);
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
            background-color: var(--bg-base);
        }

        .table thead th {
            font-weight: 700;
            text-transform: uppercase;
            font-size: 0.75rem;
            letter-spacing: 0.5px;
            color: var(--dark-light);
            border: none;
            padding: 15px;
        }

        .table tbody tr {
            transition: background-color 0.15s ease;
            border-bottom: 1px solid var(--bg-base);
        }

        .table tbody tr:hover {
            background-color: rgba(233, 201, 120, 0.08);
        }
        
        .table tbody td {
            padding: 15px;
            vertical-align: middle;
        }
        
        /* Badges — sólidos, sin bordes */
        .badge {
            padding: 5px 10px;
            border-radius: 6px;
            font-weight: 600;
            font-size: 0.75rem;
            border: none !important;
        }

        /* Overrides de badges Bootstrap → paleta Echoes (sólidos, sin borde) */
        .badge.bg-primary,
        .badge.bg-primary-subtle   { background-color: #3F7AC5 !important; color: white !important; }
        .badge.bg-warning,
        .badge.bg-warning-subtle   { background-color: #E9C978 !important; color: #2B333D !important; }
        .badge.bg-success,
        .badge.bg-success-subtle   { background-color: #DFDFDF !important; color: #3F4B5B !important; }
        .badge.bg-danger,
        .badge.bg-danger-subtle    { background-color: #EF4444 !important; color: white !important; }
        .badge.bg-secondary,
        .badge.bg-secondary-subtle { background-color: #ECECEC !important; color: #3F4B5B !important; }
        .badge.bg-info,
        .badge.bg-info-subtle      { background-color: #5388CB !important; color: white !important; }
        .badge.bg-dark,
        .badge.bg-dark-subtle      { background-color: #353F4C !important; color: white !important; }
        .badge.bg-light            { background-color: #ECECEC !important; color: #3F4B5B !important; }
        /* Eliminar opacidad de Bootstrap en badges */
        .badge[class*="bg-opacity"] { opacity: 1 !important; }
        /* Las clases text-* en badges no deben sobrescribir los colores de bg-*-subtle */
        .badge.text-primary { color: white !important; }
        .badge.text-success  { color: #3F4B5B !important; }
        .badge.text-danger   { color: white !important; }
        .badge.text-warning  { color: #2B333D !important; }
        .badge.text-secondary{ color: #3F4B5B !important; }
        .badge.text-info     { color: white !important; }
        /* Overrides para elementos no-badge que usan subtle */
        .bg-primary-subtle:not(.badge) { background-color: rgba(63, 122, 197, 0.1) !important; }
        .bg-success-subtle:not(.badge) { background-color: rgba(22, 163, 74, 0.1) !important; }
        .bg-warning-subtle:not(.badge) { background-color: rgba(233, 201, 120, 0.15) !important; }
        .bg-info-subtle:not(.badge)    { background-color: rgba(83, 136, 203, 0.1) !important; }
        
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
    
    <button class="sidebar-toggle" id="sidebarToggle" aria-label="Toggle sidebar">&#9776;</button>
    
    
    <div class="sidebar-overlay" id="sidebarOverlay"></div>
    
    <div class="container-fluid p-0" style="overflow-x: hidden; max-width: 100%;">
        <div class="row g-0" style="margin: 0; max-width: 100%;">
            
            <nav class="sidebar" id="sidebar">
                <div class="sidebar-header">
                    <img src="/images/logoapp.png" alt="Echoes" class="sidebar-logo">
                    <div class="sidebar-welcome">
                        <span>Bienvenido,</span>
                        <strong>{{ Auth::user()->name ?? 'Administrador' }}</strong>
                    </div>
                </div>

                <ul class="nav flex-column">
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('dashboard') ? 'active' : '' }}" href="{{ route('dashboard') }}">
                            Dashboard
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('usuarios.*') ? 'active' : '' }}" href="{{ route('usuarios.index') }}">
                            Usuarios
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('reportes.*') ? 'active' : '' }}" href="{{ route('reportes.index') }}">
                            Reportes
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('estadisticas.*') ? 'active' : '' }}" href="{{ route('estadisticas.index') }}">
                            Estadísticas
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('resenas.*') ? 'active' : '' }}" href="{{ route('resenas.index') }}">
                            Reseñas
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('categorias.*') ? 'active' : '' }}" href="{{ route('categorias.index') }}">
                            Categorías
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('cuadrantes.*') ? 'active' : '' }}" href="{{ route('cuadrantes.index') }}">
                            Cuadrantes
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('grupos.*') ? 'active' : '' }}" href="{{ route('grupos.index') }}">
                            Grupos
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('respuestas.*') ? 'active' : '' }}" href="{{ route('respuestas.index') }}">
                            Respuestas
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link {{ request()->routeIs('notificaciones.*') ? 'active' : '' }}" href="{{ route('notificaciones.index') }}">
                            Notificaciones
                        </a>
                    </li>
                    @role('administrador')
                    <li class="nav-item mt-3">
                        <a class="nav-link {{ request()->routeIs('users.roles.*') ? 'active' : '' }}" href="{{ route('users.roles.index') }}">
                            Gestión de roles
                        </a>
                    </li>
                    @endrole
                    <li class="nav-item mt-3">
                        <a class="nav-link {{ request()->routeIs('configuracion.*') ? 'active' : '' }}" href="{{ route('configuracion.index') }}">
                            Configuración
                        </a>
                    </li>
                </ul>
            </nav>

            
            <main class="main-content col-12">
                
                <nav class="top-navbar">
                    <div class="d-flex justify-content-between align-items-center">
                        <h1 class="navbar-brand mb-0">@yield('page-title', 'Dashboard')</h1>
                        <div class="d-flex align-items-center gap-3">
                            <form action="{{ route('logout') }}" method="POST" class="d-inline" id="logout-form">
                                @csrf
                                <button type="button" class="btn-logout" onclick="confirmLogout()">Cerrar sesión</button>
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

        // Confirmación de cierre de sesión
        function confirmLogout() {
            Swal.fire({
                title: '¿Cerrar sesión?',
                text: '¿Estás seguro de que deseas cerrar tu sesión?',
                icon: 'question',
                showCancelButton: true,
                confirmButtonColor: '#E9C978',
                cancelButtonColor: '#3F7AC5',
                confirmButtonText: 'Sí, cerrar sesión',
                cancelButtonText: 'Cancelar',
                background: 'white',
                customClass: {
                    popup: 'rounded-4',
                    confirmButton: 'btn',
                    cancelButton: 'btn'
                },
                didRender: () => {
                    const confirmBtn = document.querySelector('.swal2-confirm');
                    if (confirmBtn) confirmBtn.style.color = '#2B333D';
                }
            }).then((result) => {
                if (result.isConfirmed) {
                    document.getElementById('logout-form').submit();
                }
            });
        }

        // Confirmación de eliminación
        function confirmarEliminacion(form) {
            event.preventDefault();
            Swal.fire({
                title: '¿Estás seguro?',
                text: "Esta acción no se puede deshacer",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#E9C978',
                cancelButtonColor: '#3F7AC5',
                confirmButtonText: 'Sí, eliminar',
                cancelButtonText: 'Cancelar',
                background: 'white',
                customClass: {
                    popup: 'rounded-4',
                    confirmButton: 'btn',
                    cancelButton: 'btn'
                },
                didRender: () => {
                    document.querySelector('.swal2-confirm').style.color = '#2B333D';
                }
            }).then((result) => {
                if (result.isConfirmed) {
                    form.submit();
                }
            });
        }
        
        // Sidebar toggle para móvil
        $(document).ready(function() {
            var sidebar = $('#sidebar');
            var sidebarToggle = $('#sidebarToggle');
            var sidebarOverlay = $('#sidebarOverlay');

            function toggleSidebar() {
                sidebar.toggleClass('show');
                sidebarOverlay.toggleClass('show');
                if (sidebar.hasClass('show')) {
                    sidebarToggle.html('&#10005;');
                } else {
                    sidebarToggle.html('&#9776;');
                }
            }

            sidebarToggle.on('click', function(e) {
                e.stopPropagation();
                toggleSidebar();
            });

            sidebarOverlay.on('click', function() {
                sidebar.removeClass('show');
                sidebarOverlay.removeClass('show');
                sidebarToggle.html('&#9776;');
            });

            if (window.innerWidth <= 991) {
                $('.sidebar .nav-link').on('click', function() {
                    setTimeout(function() {
                        sidebar.removeClass('show');
                        sidebarOverlay.removeClass('show');
                        sidebarToggle.html('&#9776;');
                    }, 300);
                });
            }
        });
        
        // Ajustar en resize
        $(window).on('resize', function() {
            if (window.innerWidth > 991) {
                sidebar.removeClass('show');
                sidebarOverlay.removeClass('show');
                sidebarToggle.html('&#9776;');
            }
        });
    </script>
    
    @stack('scripts')
</body>
</html>
