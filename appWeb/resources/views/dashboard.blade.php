@extends('layouts.app')

@section('title', 'Dashboard - Amigate')
@section('page-title', 'Dashboard')

@push('styles')
<style>
    /* ============================================
       🎨 DISEÑO IMPACTANTE - CENTRO DE RESCATE
       ============================================ */
    
    /* Aurora Gradient Animation */
    @keyframes aurora {
        0%, 100% { background-position: 0% 50%; }
        50% { background-position: 100% 50%; }
    }
    
    @keyframes float {
        0%, 100% { transform: translateY(0px); }
        50% { transform: translateY(-10px); }
    }
    
    @keyframes shimmer {
        0% { background-position: -200% 0; }
        100% { background-position: 200% 0; }
    }
    
    @keyframes glow {
        0%, 100% { box-shadow: 0 0 20px rgba(37, 99, 235, 0.3); }
        50% { box-shadow: 0 0 40px rgba(37, 99, 235, 0.6); }
    }
    
    @keyframes pulse-ring {
        0% { transform: scale(0.95); opacity: 1; }
        100% { transform: scale(1.3); opacity: 0; }
    }
    
    @keyframes countUp {
        from { opacity: 0; transform: translateY(20px); }
        to { opacity: 1; transform: translateY(0); }
    }

    /* Dashboard Hero Header */
    .dashboard-header {
        background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 50%, #1e40af 100%);
        border-radius: 16px;
        padding: 25px;
        color: white;
        margin-bottom: 25px;
        position: relative;
        overflow: hidden;
        box-shadow: 0 10px 30px -10px rgba(30, 58, 138, 0.4);
    }
    
    .dashboard-header::before {
        content: '';
        position: absolute;
        top: 0;
        right: 0;
        width: 300px;
        height: 100%;
        background: radial-gradient(circle at right, rgba(255,255,255,0.1) 0%, transparent 70%);
    }
    
    .dashboard-header h1 {
        font-size: 1.75rem;
        font-weight: 700;
        margin-bottom: 8px;
        position: relative;
        z-index: 1;
    }
    
    .dashboard-header p {
        font-size: 0.95rem;
        opacity: 0.9;
        position: relative;
        z-index: 1;
        margin-bottom: 0;
    }
    
    .dashboard-header .live-indicator {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        background: rgba(16, 185, 129, 0.2);
        backdrop-filter: blur(10px);
        padding: 8px 16px;
        border-radius: 50px;
        font-size: 0.85rem;
        font-weight: 600;
        border: 1px solid rgba(16, 185, 129, 0.4);
    }
    
    .dashboard-header .live-dot {
        width: 10px;
        height: 10px;
        background: #10b981;
        border-radius: 50%;
        animation: pulse-border 2s infinite;
    }

    /* Stat Cards - Premium Design */
    .stat-card {
        background: #ffffff;
        border-radius: 16px;
        padding: 20px;
        box-shadow: 0 4px 15px rgba(0, 0, 0, 0.08);
        transition: all 0.3s ease;
        position: relative;
        overflow: hidden;
        height: 100%;
        min-height: 160px;
        border: 1px solid #e2e8f0;
        display: flex;
        flex-direction: column;
        justify-content: center;
    }
    
    .stat-card::before {
        content: '';
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        height: 3px;
    }
    
    .stat-card.primary::before { background: linear-gradient(90deg, #2563eb, #7c3aed); }
    .stat-card.success::before { background: linear-gradient(90deg, #10b981, #34d399); }
    .stat-card.warning::before { background: linear-gradient(90deg, #f59e0b, #fbbf24); }
    .stat-card.info::before { background: linear-gradient(90deg, #06b6d4, #22d3ee); }
    .stat-card.danger::before { background: linear-gradient(90deg, #ef4444, #f87171); }
    
    .stat-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 10px 25px rgba(0, 0, 0, 0.12);
    }
    
    .stat-card.primary:hover { box-shadow: 0 25px 50px -12px rgba(37, 99, 235, 0.25); }
    .stat-card.success:hover { box-shadow: 0 25px 50px -12px rgba(16, 185, 129, 0.25); }
    .stat-card.warning:hover { box-shadow: 0 25px 50px -12px rgba(245, 158, 11, 0.25); }
    .stat-card.info:hover { box-shadow: 0 25px 50px -12px rgba(6, 182, 212, 0.25); }
    .stat-card.danger:hover { box-shadow: 0 25px 50px -12px rgba(239, 68, 68, 0.25); }

    .stat-icon {
        width: 50px;
        height: 50px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.5rem;
    }
    
    .stat-icon::after {
        content: '';
        position: absolute;
        top: -50%;
        left: -50%;
        width: 200%;
        height: 200%;
        background: linear-gradient(45deg, transparent, rgba(255,255,255,0.3), transparent);
        animation: shimmer 3s infinite;
    }
    
    .stat-icon.primary { 
        background: linear-gradient(135deg, #2563eb, #7c3aed); 
        color: white;
        box-shadow: 0 10px 30px -5px rgba(37, 99, 235, 0.4);
    }
    .stat-icon.success { 
        background: linear-gradient(135deg, #10b981, #34d399); 
        color: white;
        box-shadow: 0 10px 30px -5px rgba(16, 185, 129, 0.4);
    }
    .stat-icon.warning { 
        background: linear-gradient(135deg, #f59e0b, #fbbf24); 
        color: white;
        box-shadow: 0 10px 30px -5px rgba(245, 158, 11, 0.4);
    }
    .stat-icon.info { 
        background: linear-gradient(135deg, #06b6d4, #22d3ee); 
        color: white;
        box-shadow: 0 10px 30px -5px rgba(6, 182, 212, 0.4);
    }
    .stat-icon.danger { 
        background: linear-gradient(135deg, #ef4444, #f87171); 
        color: white;
        box-shadow: 0 10px 30px -5px rgba(239, 68, 68, 0.4);
    }
    
    .stat-value {
        font-size: 2rem;
        font-weight: 700;
        margin: 8px 0;
        color: #1e293b;
    }
    
    .stat-label {
        font-size: 0.75rem;
        color: #64748b;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }
    
    .stat-change {
        font-size: 0.9rem;
        margin-top: 12px;
        display: flex;
        align-items: center;
        gap: 6px;
        padding: 6px 12px;
        border-radius: 50px;
        width: fit-content;
    }
    
    .stat-change.positive {
        background: rgba(16, 185, 129, 0.1);
        color: #059669;
    }
    
    .stat-change.neutral {
        background: rgba(100, 116, 139, 0.1);
        color: #64748b;
    }

    /* Chart Container - Premium Design */
    .chart-container {
        background: #ffffff;
        border-radius: 24px;
        padding: 28px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.06);
        height: 100%;
        border: 1px solid #e2e8f0;
        transition: all 0.3s ease;
    }
    
    .chart-container:hover {
        box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
    }
    
    .chart-container h5 {
        font-weight: 700;
        color: #1e293b;
    }
    
    /* Activity Card - Premium Style */
    .activity-card {
        background: #ffffff;
        border-radius: 24px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.06);
        overflow: hidden;
        border: 1px solid #e2e8f0;
    }
    
    .activity-card .card-header {
        background: linear-gradient(135deg, rgba(37, 99, 235, 0.05), rgba(124, 58, 237, 0.05));
        border-bottom: 1px solid rgba(0,0,0,0.05);
    }
    
    .activity-item {
        padding: 20px 24px;
        border-bottom: 1px solid #f1f5f9;
        transition: all 0.3s ease;
        position: relative;
    }
    
    .activity-item::before {
        content: '';
        position: absolute;
        left: 0;
        top: 0;
        bottom: 0;
        width: 3px;
        background: transparent;
        transition: background 0.3s ease;
    }
    
    .activity-item:hover {
        background: linear-gradient(90deg, rgba(37, 99, 235, 0.03), transparent);
        padding-left: 28px;
    }
    
    .activity-item:hover::before {
        background: linear-gradient(180deg, #2563eb, #7c3aed);
    }
    
    .activity-item:last-child {
        border-bottom: none;
    }
    
    .user-avatar {
        width: 50px;
        height: 50px;
        border-radius: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        font-size: 1.2rem;
        box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
    }
    
    /* Badges Premium */
    .badge {
        font-weight: 600;
        letter-spacing: 0.3px;
    }
    
    /* Animación de Pulso para Alertas */
    @keyframes pulse-border {
        0% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.7); }
        70% { box-shadow: 0 0 0 15px rgba(239, 68, 68, 0); }
        100% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0); }
    }
    
    .pulse-animation {
        animation: pulse-border 2s infinite;
    }
    
    /* Mini stat cards */
    .mini-stat-card {
        background: rgba(255, 255, 255, 0.95);
        border-radius: 20px;
        padding: 20px;
        text-align: center;
        box-shadow: 0 4px 15px rgba(0,0,0,0.05);
        transition: all 0.3s ease;
        position: relative;
        overflow: hidden;
    }
    
    .mini-stat-card::before {
        content: '';
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        height: 4px;
    }
    
    .mini-stat-card.danger::before { background: linear-gradient(90deg, #ef4444, #f87171); }
    .mini-stat-card.success::before { background: linear-gradient(90deg, #10b981, #34d399); }
    .mini-stat-card.warning::before { background: linear-gradient(90deg, #f59e0b, #fbbf24); }
    .mini-stat-card.info::before { background: linear-gradient(90deg, #06b6d4, #22d3ee); }
    
    .mini-stat-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 20px 40px rgba(0,0,0,0.1);
    }
    
    .category-badge {
        display: inline-flex;
        align-items: center;
        gap: 8px;
        padding: 10px 15px;
        border-radius: 12px;
        font-weight: 600;
        font-size: 0.9rem;
        transition: all 0.2s ease;
    }
    
    .category-badge:hover {
        transform: scale(1.02);
    }
    
    /* Fade in animation */
    .fade-in {
        opacity: 0;
        animation: fadeIn 0.5s ease forwards;
    }
    
    @keyframes fadeIn {
        from { opacity: 0; transform: translateY(10px); }
        to { opacity: 1; transform: translateY(0); }
    }
    
    /* Stagger animation for cards */
    .stat-card:nth-child(1) { animation-delay: 0.1s; }
    .stat-card:nth-child(2) { animation-delay: 0.2s; }
    .stat-card:nth-child(3) { animation-delay: 0.3s; }
    .stat-card:nth-child(4) { animation-delay: 0.4s; }
    
    /* GPU Optimization */
    .stat-card,
    .mini-stat-card,
    .chart-container,
    .activity-card {
        will-change: transform;
        transform: translateZ(0);
    }
    
    /* Reduce motion for accessibility */
    @media (prefers-reduced-motion: reduce) {
        .dashboard-header,
        .stat-icon::after,
        .fade-in {
            animation: none;
        }
        .dashboard-header {
            background: linear-gradient(135deg, #1e3a8a 0%, #7c3aed 100%);
        }
    }

    /* ============================================
       RESPONSIVE DESIGN
       ============================================ */
    
    @media (max-width: 991.98px) {
        .dashboard-header {
            padding: 30px 20px;
            border-radius: 20px;
        }
        
        .dashboard-header h1 {
            font-size: 2.2rem;
        }
        
        .stat-card {
            padding: 22px;
            border-radius: 20px;
        }
        
        .stat-value {
            font-size: 2.5rem;
        }
        
        .stat-icon {
            width: 55px;
            height: 55px;
            font-size: 1.6rem;
        }
    }
    
    @media (max-width: 767.98px) {
        .dashboard-header {
            padding: 25px 18px;
            border-radius: 18px;
            margin-bottom: 20px;
        }
        
        .dashboard-header h1 {
            font-size: 1.8rem;
        }
        
        .dashboard-header p {
            font-size: 0.95rem;
        }
        
        .dashboard-header .d-flex {
            flex-direction: column;
            align-items: flex-start !important;
            gap: 15px;
        }
        
        .stat-card {
            padding: 20px 16px;
            border-radius: 16px;
            margin-bottom: 12px;
        }
        
        .stat-icon {
            width: 50px;
            height: 50px;
            font-size: 1.4rem;
        }
        
        .stat-value {
            font-size: 2rem;
        }
        
        .stat-label {
            font-size: 0.75rem;
        }
        
        .chart-container,
        .activity-card {
            border-radius: 16px;
            margin-bottom: 16px;
        }
        
        .activity-item {
            padding: 16px;
        }
        
        .activity-item:hover {
            padding-left: 18px;
        }
        
        .user-avatar {
            width: 42px;
            height: 42px;
        }
    }
    
    @media (max-width: 575.98px) {
        .dashboard-header {
            padding: 20px 15px;
            border-radius: 16px;
        }
        
        .dashboard-header h1 {
            font-size: 1.5rem;
        }
        
        .dashboard-header::before,
        .dashboard-header::after {
            display: none;
        }
        
        .stat-card {
            padding: 16px 14px;
        }
        
        .stat-icon {
            width: 45px;
            height: 45px;
            font-size: 1.2rem;
        }
        
        .stat-value {
            font-size: 1.75rem;
        }
        
        .activity-item {
            padding: 14px;
        }
        
        .badge {
            font-size: 0.7rem;
            padding: 4px 8px;
        }
    }
    
    /* Chart responsive */
    @media (max-width: 767.98px) {
        #tipoReportesChart,
        #categoriasChart {
            max-height: 250px !important;
        }
    }
    
    @media (max-width: 575.98px) {
        #tipoReportesChart,
        #categoriasChart {
            max-height: 200px !important;
        }
    }
</style>
@endpush

@section('content')

<div class="dashboard-header" style="background: linear-gradient(135deg, #1e3a8a, #3b82f6); padding: 25px; border-radius: 16px; color: white; margin-bottom: 25px;">
    <div class="d-flex justify-content-between align-items-center">
        <div>
            <div class="d-flex align-items-center gap-2 mb-2">
                <span style="background: rgba(16, 185, 129, 0.9); padding: 6px 14px; border-radius: 50px; font-size: 0.8rem; font-weight: 600; display: inline-flex; align-items: center; gap: 6px;">
                    <span style="width: 8px; height: 8px; background: #fff; border-radius: 50%; animation: pulse 1.5s infinite;"></span>
                    EN VIVO
                </span>
            </div>
            <h1 class="mb-1" style="font-size: 1.75rem; font-weight: 700;">
                <i class="bi bi-speedometer2 me-2"></i>
                Dashboard
            </h1>
            <p class="mb-0" style="font-size: 0.95rem; opacity: 0.9;">
                <i class="bi bi-calendar3 me-1"></i>
                {{ now()->locale('es')->isoFormat('dddd, D [de] MMMM, YYYY') }} • <span id="current-time">{{ now()->format('H:i:s') }}</span>
            </p>
        </div>
        <div class="d-none d-md-flex align-items-center gap-2">
            <span style="background: rgba(255,255,255,0.15); padding: 8px 16px; border-radius: 50px; font-size: 0.85rem; display: flex; align-items: center; gap: 8px;">
                <i class="bi bi-arrow-repeat" id="refresh-icon"></i>
                <span id="countdown">30s</span>
            </span>
        </div>
    </div>
</div>

<style>
    @keyframes pulse {
        0%, 100% { opacity: 1; transform: scale(1); }
        50% { opacity: 0.5; transform: scale(1.2); }
    }
    #refresh-icon.spinning {
        animation: spin 1s linear;
    }
    @keyframes spin {
        from { transform: rotate(0deg); }
        to { transform: rotate(360deg); }
    }
</style>


<div class="row g-4 mb-4">
    <!-- Card COMUNIDAD (Total Usuarios) -->
    <div class="col-xl-3 col-md-6">
        <div class="stat-card success">
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <div class="stat-label mb-2">
                        <i class="bi bi-heart-fill text-success me-1"></i> COMUNIDAD
                    </div>
                    <div class="stat-value">{{ $totalUsuarios ?? 0 }}</div>
                    <div class="stat-change positive">
                        <i class="bi bi-people-fill"></i>
                        Usuarios activos
                    </div>
                </div>
                <div class="stat-icon success">
                    <i class="bi bi-people-fill"></i>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Card ZONA CRÍTICA -->
    <div class="col-xl-3 col-md-6">
        <div class="stat-card danger">
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <div class="stat-label mb-2">
                        <i class="bi bi-exclamation-triangle-fill text-danger me-1"></i> ZONA CRÍTICA
                    </div>
                    <div class="stat-value" style="font-size: 1.5rem;">
                        {{ $zonaCritica ? Str::limit($zonaCritica->nombre, 15) : 'Sin alertas' }}
                    </div>
                    <div class="stat-change neutral">
                        <i class="bi bi-geo-alt-fill"></i>
                        {{ $zonaCritica ? $zonaCritica->reportes_count . ' casos' : 'Todo bajo control' }}
                    </div>
                </div>
                <div class="stat-icon danger">
                    <i class="bi bi-pin-map-fill"></i>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Card ALERTAS HOY -->
    <div class="col-xl-3 col-md-6">
        <div class="stat-card primary">
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <div class="stat-label mb-2">
                        <i class="bi bi-lightning-fill text-primary me-1"></i> ALERTAS HOY
                    </div>
                    <div class="stat-value">{{ $reportesHoy }}</div>
                    <div class="stat-change neutral">
                        <i class="bi bi-clock-history"></i>
                        Últimas 24 horas
                    </div>
                </div>
                <div class="stat-icon primary">
                    <i class="bi bi-bell-fill"></i>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Card CASOS ACTIVOS -->
    <div class="col-xl-3 col-md-6">
        <div class="stat-card warning">
            <div class="d-flex justify-content-between align-items-start">
                <div>
                    <div class="stat-label mb-2">
                        <i class="bi bi-hourglass-split text-warning me-1"></i> EN SEGUIMIENTO
                    </div>
                    <div class="stat-value">{{ number_format($reportesActivos ?? 0, 0, ',', '.') }}</div>
                    <div class="stat-change neutral">
                        <i class="bi bi-search"></i>
                        Búsquedas activas
                    </div>
                </div>
                <div class="stat-icon warning">
                    <i class="bi bi-binoculars-fill"></i>
                </div>
            </div>
        </div>
    </div>
</div>





<div class="row g-4 mb-4">
    <div class="col-xl-6">
        <div class="chart-container">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <div>
                    <h5 class="mb-1 fw-bold">
                        <i class="bi bi-pie-chart-fill text-danger me-2"></i>
                         Estado de Alertas
                    </h5>
                    <p class="text-muted small mb-0">Casos activos vs resueltos</p>
                </div>
            </div>
            <canvas id="tipoReportesChart" style="max-height: 300px;"></canvas>
        </div>
    </div>
    
    <div class="col-xl-6">
        <div class="chart-container">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <div>
                    <h5 class="mb-1 fw-bold">
                        <i class="bi bi-graph-up-arrow text-success me-2"></i>
                         Pulso de la Ciudad
                    </h5>
                    <p class="text-muted small mb-0">Casos reportados los últimos 7 días</p>
                </div>
            </div>
            <canvas id="tendenciaChart" style="max-height: 300px;"></canvas>
        </div>
    </div>
</div>

<div class="row g-4">
    <!-- Actividad Reciente (Columna Principal) -->
    <div class="col-12 col-xl-8">
        <div class="activity-card">
            <div class="card-header bg-white border-0 py-4 px-4">
                <div class="d-flex justify-content-between align-items-center flex-wrap gap-2">
                    <div>
                        <h5 class="mb-1 fw-bold">
                            <i class="bi bi-clock-history text-primary me-2"></i>
                            Actividad Reciente
                        </h5>
                        <p class="text-muted small mb-0">Últimos reportes del sistema</p>
                    </div>
                    <a href="{{ route('reportes.index') }}" class="btn btn-primary btn-sm rounded-pill px-3">
                        Ver todos <i class="bi bi-arrow-right ms-1"></i>
                    </a>
                </div>
            </div>
            <div class="card-body p-0">
                @forelse($ultimosReportes ?? [] as $reporte)
                <div class="activity-item">
                    <div class="d-flex align-items-center">
                        <div class="flex-shrink-0 me-3">
                            <div class="user-avatar bg-primary-subtle text-primary rounded-4">
                                <i class="bi bi-file-earmark-text fs-5"></i>
                            </div>
                        </div>
                        <div class="flex-grow-1">
                            <div class="d-flex justify-content-between align-items-start mb-2">
                                <div>
                                    <h6 class="mb-1 fw-bold text-dark">{{ Str::limit($reporte->titulo, 50) }}</h6>
                                    <div class="d-flex align-items-center gap-2 flex-wrap">
                                        <span class="badge bg-{{ $reporte->tipo_reporte == 'perdido' ? 'danger' : 'success' }}-subtle text-{{ $reporte->tipo_reporte == 'perdido' ? 'danger' : 'success' }} border border-{{ $reporte->tipo_reporte == 'perdido' ? 'danger' : 'success' }} rounded-pill">
                                            <i class="bi bi-{{ $reporte->tipo_reporte == 'perdido' ? 'x-circle' : 'check-circle' }}-fill me-1"></i>
                                            {{ ucfirst($reporte->tipo_reporte) }}
                                        </span>
                                        <span class="badge rounded-pill" style="background-color: {{ $reporte->categoria->color ?? '#6c757d' }}20; color: {{ $reporte->categoria->color ?? '#6c757d' }}; border: 1px solid {{ $reporte->categoria->color ?? '#6c757d' }}">
                                            {{ $reporte->categoria->nombre ?? 'N/A' }}
                                        </span>
                                        @if($reporte->recompensa)
                                            <span class="badge bg-warning-subtle text-warning border border-warning rounded-pill">
                                                <i class="bi bi-cash-coin me-1"></i>Bs. {{ number_format($reporte->recompensa, 2) }}
                                            </span>
                                        @endif
                                    </div>
                                </div>
                                <div class="text-end">
                                    @if($reporte->estado == 'activo')
                                        <span class="badge bg-primary-subtle text-primary border border-primary rounded-pill px-3">Activo</span>
                                    @elseif($reporte->estado == 'resuelto')
                                        <span class="badge bg-success-subtle text-success border border-success rounded-pill px-3">
                                            <i class="bi bi-check-circle-fill me-1"></i>Resuelto
                                        </span>
                                    @else
                                        <span class="badge bg-secondary-subtle text-secondary border border-secondary rounded-pill px-3">{{ ucfirst($reporte->estado) }}</span>
                                    @endif
                                </div>
                            </div>
                            <div class="d-flex align-items-center justify-content-between">
                                <div class="d-flex align-items-center gap-3">
                                    <div class="d-flex align-items-center">
                                        @if($reporte->usuario->avatar_url ?? false)
                                            <img src="{{ $reporte->usuario->avatar_url }}" class="rounded-circle me-2" width="24" height="24" alt="Avatar">
                                        @else
                                            <div class="rounded-circle bg-gray-200 text-secondary d-flex align-items-center justify-content-center me-2 fw-bold" style="width: 24px; height: 24px; font-size: 10px; background-color: #f1f5f9;">
                                                {{ substr($reporte->usuario->nombre ?? 'U', 0, 1) }}
                                            </div>
                                        @endif
                                        <small class="text-muted fw-semibold">{{ $reporte->usuario->nombre ?? 'N/A' }}</small>
                                    </div>
                                    <small class="text-muted">
                                        <i class="bi bi-calendar3 me-1"></i>{{ $reporte->created_at->format('d/m/Y') }}
                                    </small>
                                </div>
                                <a href="{{ route('reportes.show', $reporte->id) }}" class="btn btn-outline-primary btn-sm rounded-pill px-3">
                                    Ver detalles
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
                @empty
                <div class="activity-item text-center py-5">
                    <div class="bg-light rounded-circle d-inline-flex p-3 mb-3">
                        <i class="bi bi-inbox fs-1 text-muted"></i>
                    </div>
                    <h5 class="text-muted fw-semibold">No hay reportes recientes</h5>
                    <p class="text-muted small">Los reportes nuevos aparecerán aquí</p>
                </div>
                @endforelse
            </div>
        </div>
    </div>
    
    <!-- Columna Lateral (Usuarios y Categorías) -->
    <div class="col-12 col-xl-4">
        <div class="row g-4">
            <!-- Nuevos Usuarios -->
            <div class="col-12">
                <div class="activity-card">
                    <div class="card-header bg-white border-0 py-4 px-4">
                        <h5 class="mb-1 fw-bold">
                            <i class="bi bi-person-plus text-primary me-2"></i>
                            Nuevos Usuarios
                        </h5>
                        <p class="text-muted small mb-0">Últimos registros en la comunidad</p>
                    </div>
                    <div class="card-body p-0">
                        @forelse($nuevosUsuarios ?? [] as $usuario)
                        <div class="activity-item">
                            <div class="d-flex align-items-center">
                                <div class="flex-shrink-0 me-3">
                                    @if($usuario->avatar_url)
                                        <img src="{{ $usuario->avatar_url }}" class="rounded-circle shadow-sm" width="45" height="45" alt="Avatar">
                                    @else
                                        <div class="user-avatar bg-success-subtle text-success rounded-4 fw-bold fs-5">
                                            {{ substr($usuario->nombre, 0, 1) }}
                                        </div>
                                    @endif
                                </div>
                                <div class="flex-grow-1">
                                    <h6 class="mb-1 fw-bold text-dark">{{ $usuario->nombre }}</h6>
                                    <small class="text-muted d-block mb-1">{{ Str::limit($usuario->email, 22) }}</small>
                                    <span class="badge bg-light text-secondary border rounded-pill">
                                        <i class="bi bi-clock me-1"></i>{{ $usuario->created_at->diffForHumans(null, true, true) }}
                                    </span>
                                </div>
                            </div>
                        </div>
                        @empty
                        <div class="activity-item text-center py-4">
                            <p class="text-muted small mb-0">No hay usuarios nuevos</p>
                        </div>
                        @endforelse
                    </div>
                </div>
            </div>
            
            <!-- Categorías Populares (LISTA) -->
            <div class="col-12">
                <div class="activity-card">
                    <div class="card-header bg-white border-0 py-4 px-4">
                        <h5 class="mb-1 fw-bold">
                            <i class="bi bi-tags text-primary me-2"></i>
                            Top Categorías
                        </h5>
                        <p class="text-muted small mb-0">Mayor actividad histórica</p>
                    </div>
                    <div class="card-body px-4 pb-4" style="max-height: 280px; overflow-y: auto;">
                        @forelse($categoriasPopulares ?? [] as $categoria)
                        <div class="d-flex align-items-center mb-3">
                            <div class="flex-grow-1">
                                <div class="d-flex justify-content-between mb-1">
                                    <span class="fw-bold" style="color: {{ $categoria->color }};">
                                        <i class="bi bi-circle-fill me-2 small"></i>{{ $categoria->nombre }}
                                    </span>
                                    <span class="fw-bold text-dark">{{ $categoria->reportes_count }}</span>
                                </div>
                                <div class="progress" style="height: 6px; border-radius: 10px; background-color: #f1f5f9;">
                                    <div class="progress-bar" role="progressbar" 
                                         style="width: {{ $totalReportes > 0 ? ($categoria->reportes_count / $totalReportes) * 100 : 0 }}%; background-color: {{ $categoria->color }}; border-radius: 10px;" 
                                         aria-valuenow="{{ $categoria->reportes_count }}" aria-valuemin="0" aria-valuemax="{{ $totalReportes }}"></div>
                                </div>
                            </div>
                        </div>
                        @empty
                        <div class="text-center py-4">
                            <p class="text-muted small mb-0">No hay datos disponibles</p>
                        </div>
                        @endforelse
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

@endsection

@push('scripts')
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script>
    // Gráfico de Tipo de Reportes - Solo Perdidos vs Resueltos
    const tipoCtx = document.getElementById('tipoReportesChart');
    if (tipoCtx) {
        new Chart(tipoCtx, {
            type: 'doughnut',
            data: {
                labels: ['Perdidos (Activos)', 'Resueltos'],
                datasets: [{
                    data: [{{ $reportesPerdidos ?? 0 }}, {{ $reportesResueltos ?? 0 }}],
                    backgroundColor: [
                        'rgba(239, 68, 68, 0.8)',
                        'rgba(37, 99, 235, 0.8)'
                    ],
                    borderColor: [
                        '#ef4444',
                        '#2563eb'
                    ],
                    borderWidth: 3,
                    hoverOffset: 15
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            padding: 20,
                            font: { size: 13, weight: '600' },
                            usePointStyle: true,
                            pointStyle: 'circle'
                        }
                    },
                    tooltip: {
                         backgroundColor: 'rgba(0, 0, 0, 0.85)',
                         padding: 15,
                         cornerRadius: 10
                    }
                },
                cutout: '65%'
            }
        });
    }

    // Gráfico de Tendencia Semanal - Line Chart con datos REALES
    const tendenciaCtx = document.getElementById('tendenciaChart');
    if (tendenciaCtx) {
        // Datos reales del backend
        const tendenciaData = {!! json_encode($tendenciaSemanal) !!};
        const dias = tendenciaData.map(item => item.fecha);
        const valores = tendenciaData.map(item => item.total);
        
        new Chart(tendenciaCtx, {
            type: 'line',
            data: {
                labels: dias,
                datasets: [{
                    label: 'Alertas',
                    data: valores,
                    borderColor: '#10b981',
                    backgroundColor: 'rgba(16, 185, 129, 0.15)',
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4,
                    pointBackgroundColor: '#10b981',
                    pointBorderColor: '#fff',
                    pointBorderWidth: 2,
                    pointRadius: 6,
                    pointHoverRadius: 8
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        backgroundColor: 'rgba(0, 0, 0, 0.85)',
                        padding: 12,
                        cornerRadius: 8,
                        callbacks: {
                            label: (ctx) => `${ctx.parsed.y} alertas`
                        }
                    }
                },
                scales: {
                    x: {
                        grid: { display: false },
                        ticks: { font: { weight: '600' }, color: '#64748b' }
                    },
                    y: {
                        beginAtZero: true,
                        grid: { color: '#f1f5f9' },
                        ticks: { 
                            font: { weight: '600' }, 
                            color: '#64748b',
                            stepSize: 1
                        }
                    }
                }
            }
        });
    }
    // ========================================
    // AUTO-REFRESH SYSTEM
    // ========================================
    let countdown = 30;
    const countdownEl = document.getElementById('countdown');
    const refreshIcon = document.getElementById('refresh-icon');
    const currentTimeEl = document.getElementById('current-time');
    
    // Actualizar hora cada segundo
    setInterval(() => {
        const now = new Date();
        const hours = String(now.getHours()).padStart(2, '0');
        const minutes = String(now.getMinutes()).padStart(2, '0');
        const seconds = String(now.getSeconds()).padStart(2, '0');
        if (currentTimeEl) {
            currentTimeEl.textContent = `${hours}:${minutes}:${seconds}`;
        }
    }, 1000);
    
    // Countdown y refresh
    setInterval(() => {
        countdown--;
        if (countdownEl) {
            countdownEl.textContent = countdown + 's';
        }
        
        if (countdown <= 0) {
            countdown = 30;
            if (refreshIcon) {
                refreshIcon.classList.add('spinning');
            }
            // Recargar página para obtener datos actualizados
            window.location.reload();
        }
    }, 1000);
</script>
@endpush
