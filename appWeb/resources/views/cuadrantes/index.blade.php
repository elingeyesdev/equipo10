@extends('layouts.app')

@section('title', 'Cuadrantes - Amigate')
@section('page-title', 'Gestión de Cuadrantes')

@push('styles')
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
<style>
    .map-container {
        position: relative;
        width: 100%;
        height: 70vh;
        min-height: 600px;
        border-radius: 15px;
        overflow: hidden;
        box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        background: #f8f9fa;
    }
    
    #map {
        width: 100%;
        height: 100%;
        z-index: 1;
    }
    
    .map-controls {
        position: absolute;
        top: 15px;
        right: 15px;
        z-index: 1000;
        background: white;
        padding: 15px;
        border-radius: 10px;
        box-shadow: 0 4px 15px rgba(0,0,0,0.15);
        min-width: 200px;
    }
    
    .map-controls h6 {
        font-size: 0.9rem;
        font-weight: 700;
        margin-bottom: 10px;
        color: #1e293b;
    }
    
    .map-controls .form-label {
        font-size: 0.85rem;
        font-weight: 600;
        color: #64748b;
        margin-bottom: 5px;
    }
    
    .map-controls .form-control,
    .map-controls .form-select {
        font-size: 0.9rem;
        padding: 8px 12px;
        border: 2px solid #e2e8f0;
        border-radius: 8px;
        transition: border-color 0.2s ease;
    }
    
    .map-controls .form-control:focus,
    .map-controls .form-select:focus {
        border-color: #2563eb;
        outline: none;
        box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
    }
    
    .controls-sidebar {
        background: white;
        border-radius: 15px;
        padding: 25px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.08);
        height: 100%;
    }
    
    .control-group {
        margin-bottom: 20px;
    }
    
    .control-group label {
        display: block;
        font-weight: 600;
        margin-bottom: 8px;
        color: #1e293b;
        font-size: 0.9rem;
    }
    
    .control-group input,
    .control-group select {
        width: 100%;
        padding: 12px;
        border: 2px solid #e2e8f0;
        border-radius: 10px;
        font-size: 0.95rem;
        transition: border-color 0.2s ease, box-shadow 0.2s ease;
    }
    
    .control-group input:focus,
    .control-group select:focus {
        outline: none;
        border-color: #2563eb;
        box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
    }
    
    .btn-cuadrante {
        width: 100%;
        padding: 12px 20px;
        border: none;
        border-radius: 10px;
        font-size: 0.95rem;
        font-weight: 600;
        cursor: pointer;
        transition: all 0.2s ease;
        margin-bottom: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 8px;
    }
    
    .btn-cuadrante:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    }
    
    .btn-cuadrante:disabled {
        opacity: 0.6;
        cursor: not-allowed;
        transform: none !important;
    }
    
    .btn-reload {
        background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
        color: white;
    }
    
    .btn-reload:hover {
        background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%);
    }
    
    .btn-primary-cuadrante {
        background: linear-gradient(135deg, #2563eb 0%, #1e40af 100%);
        color: white;
    }
    
    .btn-primary-cuadrante:hover {
        background: linear-gradient(135deg, #1d4ed8 0%, #1e3a8a 100%);
    }
    
    .btn-success-cuadrante {
        background: linear-gradient(135deg, #10b981 0%, #059669 100%);
        color: white;
    }
    
    .btn-success-cuadrante:hover {
        background: linear-gradient(135deg, #059669 0%, #047857 100%);
    }
    
    .stats-box {
        background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
        border-radius: 12px;
        padding: 20px;
        margin-top: 20px;
        border: 2px solid #e2e8f0;
    }
    
    .stats-box h5 {
        margin-bottom: 15px;
        color: #1e293b;
        font-size: 1.1rem;
        font-weight: 700;
        display: flex;
        align-items: center;
        gap: 8px;
    }
    
    .stat-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 12px 0;
        border-bottom: 1px solid #e2e8f0;
    }
    
    .stat-item:last-child {
        border-bottom: none;
    }
    
    .stat-label {
        color: #64748b;
        font-weight: 600;
        font-size: 0.9rem;
        display: flex;
        align-items: center;
        gap: 8px;
    }
    
    .stat-value {
        color: #2563eb;
        font-weight: 700;
        font-size: 1.3rem;
    }
    
    .loading {
        display: none;
        text-align: center;
        padding: 20px;
        color: #2563eb;
    }
    
    .loading.active {
        display: block;
    }
    
    .spinner {
        border: 3px solid #e2e8f0;
        border-top: 3px solid #2563eb;
        border-radius: 50%;
        width: 35px;
        height: 35px;
        animation: spin 0.8s linear infinite;
        margin: 0 auto 10px;
    }
    
    @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
    }
    
    .alert-cuadrante {
        padding: 12px 15px;
        border-radius: 8px;
        margin-bottom: 15px;
        font-weight: 500;
        font-size: 0.9rem;
    }
    
    .alert-success {
        background: #d1fae5;
        color: #065f46;
        border: 1px solid #6ee7b7;
    }
    
    .alert-error {
        background: #fee2e2;
        color: #991b1b;
        border: 1px solid #fca5a5;
    }
    
    .alert-info {
        background: #dbeafe;
        color: #1e40af;
        border: 1px solid #93c5fd;
    }
    
    .log {
        background: #f8fafc;
        border-radius: 8px;
        padding: 15px;
        margin-top: 15px;
        max-height: 200px;
        overflow-y: auto;
        font-size: 0.85rem;
        font-family: 'Courier New', monospace;
        border: 1px solid #e2e8f0;
    }
    
    .log-entry {
        padding: 6px 0;
        border-bottom: 1px solid #e2e8f0;
        color: #475569;
    }
    
    .log-entry:last-child {
        border-bottom: none;
    }
    
    /* Estilos para las cuadrículas en el mapa */
    .leaflet-interactive {
        stroke-width: 2.5px;
        stroke-opacity: 0.9;
    }
    
    /* Leyenda de zonas */
    .legend {
        position: absolute;
        bottom: 20px;
        left: 20px;
        z-index: 1000;
        background: white;
        padding: 15px;
        border-radius: 10px;
        box-shadow: 0 4px 15px rgba(0,0,0,0.15);
        font-size: 0.85rem;
    }
    
    .legend h6 {
        margin-bottom: 10px;
        font-weight: 700;
        color: #1e293b;
    }
    
    .legend-item {
        display: flex;
        align-items: center;
        gap: 8px;
        margin-bottom: 6px;
    }
    
    .legend-color {
        width: 20px;
        height: 20px;
        border-radius: 4px;
        border: 2px solid rgba(0,0,0,0.2);
    }
    
    /* Responsive */
    @media (max-width: 991.98px) {
        .map-container {
            height: 500px;
            min-height: 500px;
        }
        
        .map-controls {
            position: relative;
            top: 0;
            right: 0;
            margin-bottom: 15px;
            width: 100%;
        }
        
        .controls-sidebar {
            margin-top: 20px;
        }
    }
    
    @media (max-width: 767.98px) {
        .map-container {
            height: 400px;
            min-height: 400px;
        }
        
        .legend {
            bottom: 10px;
            left: 10px;
            padding: 10px;
            font-size: 0.75rem;
        }
        
        .legend-color {
            width: 16px;
            height: 16px;
        }
    }
    /* Amber Alert Style Markers */
    .marker-pulse {
        width: 14px;
        height: 14px;
        border-radius: 50%;
        border: 2px solid white;
        box-shadow: 0 0 5px rgba(0,0,0,0.5);
        position: relative;
    }
    
    .marker-perdido { background: #dc3545; animation: pulse-red 2s infinite; }
    .marker-encontrado { background: #198754; animation: pulse-green 2s infinite; }
    .marker-otro { background: #0dcaf0; }

    @keyframes pulse-red {
        0% { box-shadow: 0 0 0 0 rgba(220, 53, 69, 0.7); }
        70% { box-shadow: 0 0 0 10px rgba(220, 53, 69, 0); }
        100% { box-shadow: 0 0 0 0 rgba(220, 53, 69, 0); }
    }
    
    @keyframes pulse-green {
        0% { box-shadow: 0 0 0 0 rgba(25, 135, 84, 0.7); }
        70% { box-shadow: 0 0 0 10px rgba(25, 135, 84, 0); }
        100% { box-shadow: 0 0 0 0 rgba(25, 135, 84, 0); }
    }

    /* Popup Styles */
    .amber-popup {
        font-family: 'Segoe UI', system-ui, sans-serif;
    }
    .leaflet-popup-content-wrapper {
        padding: 0;
        overflow: hidden;
        border-radius: 12px;
    }
    .leaflet-popup-content {
        margin: 0 !important;
        width: auto !important;
    }
    .text-truncate-2 {
        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
    }
</style>
@endpush

@section('content')

<div class="row mb-4">
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <div class="d-flex align-items-center">
                    <div class="flex-shrink-0">
                        <div class="rounded-circle bg-primary bg-opacity-10 p-3">
                            <i class="bi bi-grid-3x3-gap fs-4 text-primary"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Total Cuadrantes</h6>
                        <h3 class="mb-0 fw-bold text-primary" id="statTotalCuadrantes">{{ $cuadrantes->count() }}</h3>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <div class="d-flex align-items-center">
                    <div class="flex-shrink-0">
                        <div class="rounded-circle bg-success bg-opacity-10 p-3">
                            <i class="bi bi-check-circle fs-4 text-success"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Activos</h6>
                        <h3 class="mb-0 fw-bold text-success">{{ $cuadrantes->where('activo', true)->count() }}</h3>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <div class="d-flex align-items-center">
                    <div class="flex-shrink-0">
                        <div class="rounded-circle bg-info bg-opacity-10 p-3">
                            <i class="bi bi-file-earmark-text fs-4 text-info"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Total Barrios</h6>
                        <h3 class="mb-0 fw-bold text-info" id="statTotalBarrios">{{ $cuadrantes->sum(function($c) { return is_array($c->barrios) ? count($c->barrios) : 0; }) }}</h3>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <div class="col-xl-3 col-md-6 mb-3">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body">
                <div class="d-flex align-items-center">
                    <div class="flex-shrink-0">
                        <div class="rounded-circle bg-warning bg-opacity-10 p-3">
                            <i class="bi bi-people fs-4 text-warning"></i>
                        </div>
                    </div>
                    <div class="flex-grow-1 ms-3">
                        <h6 class="text-muted mb-1 text-uppercase" style="font-size: 0.75rem; letter-spacing: 0.5px;">Total Grupos</h6>
                        <h3 class="mb-0 fw-bold text-warning" id="statTotalGrupos">{{ $grupos ?? 0 }}</h3>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>


<div class="row g-4">
    <div class="col-12">
        <div class="card border-0 shadow-sm">
            <div class="card-header bg-white border-0 py-3">
                <div class="d-flex justify-content-between align-items-center flex-wrap">
                    <div>
                        <h5 class="mb-0 fw-bold">
                            <i class="bi bi-geo-alt text-primary me-2"></i>
                            Mapa de Cuadrantes
                        </h5>
                        <p class="text-muted small mb-0 mt-1">Visualización de cuadrantes en Santa Cruz de la Sierra</p>
                    </div>
                </div>
            </div>
            <div class="card-body p-0">
                <div class="map-container" style="height: 80vh;">
                    <div id="map"></div>
                    
                    
                    <div class="map-controls d-none d-md-block">
                        <h6><i class="bi bi-layers"></i> Capas y Filtros</h6>
                        
                        <div class="form-check form-switch mb-2">
                            <input class="form-check-input" type="checkbox" id="showPerdidos" checked onchange="toggleLayer('perdidos')">
                            <label class="form-check-label text-danger" for="showPerdidos">
                                <i class="bi bi-exclamation-triangle-fill"></i> Perdidos (<span id="countPerdidos">0</span>)
                            </label>
                        </div>
                        


                        <div class="form-check form-switch mb-2">
                            <input class="form-check-input" type="checkbox" id="showResueltos" checked onchange="toggleLayer('resueltos')">
                            <label class="form-check-label text-primary" for="showResueltos">
                                <i class="bi bi-check-all"></i> Resueltos (<span id="countResueltos">0</span>)
                            </label>
                        </div>
                    </div>
                    
                    
                    <div class="legend">
                        <h6><i class="bi bi-info-circle"></i> Zonas</h6>
                        <div class="legend-item">
                            <div class="legend-color" style="background-color: #FF6B6B;"></div>
                            <span>Norte</span>
                        </div>
                        <div class="legend-item">
                            <div class="legend-color" style="background-color: #4ECDC4;"></div>
                            <span>Noreste</span>
                        </div>
                        <div class="legend-item">
                            <div class="legend-color" style="background-color: #45B7D1;"></div>
                            <span>Este</span>
                        </div>
                        <div class="legend-item">
                            <div class="legend-color" style="background-color: #96CEB4;"></div>
                            <span>Sur</span>
                        </div>
                        <div class="legend-item">
                            <div class="legend-color" style="background-color: #FFEAA7;"></div>
                            <span>Centro</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script>
    let map;
    let rectangles = [];
    let historyLayer; // Capa para dibujar el historial de movimiento
    
    // Datos de cuadrantes desde PHP (Base de Datos)
    const cuadrantesData = {!! json_encode($cuadrantes->map(function($c) {
        $barrios = $c->barrios;
        if (is_string($barrios)) {
            $barrios = json_decode($barrios, true) ?? [];
        }
        if (!is_array($barrios)) {
            $barrios = [];
        }
        
        return [
            'id' => $c->id,
            'codigo' => $c->codigo,
            'fila' => $c->fila,
            'columna' => $c->columna,
            'nombre' => $c->nombre,
            'lat_min' => (float)$c->lat_min,
            'lat_max' => (float)$c->lat_max,
            'lng_min' => (float)$c->lng_min,
            'lng_max' => (float)$c->lng_max,
            'centro_lat' => (float)(($c->lat_min + $c->lat_max) / 2),
            'centro_lng' => (float)(($c->lng_min + $c->lng_max) / 2),
            'ciudad' => $c->ciudad,
            'zona' => $c->zona,
            'activo' => $c->activo,
            'barrios' => $barrios,
            'reportes_count' => $c->reportes_count
        ];
    })->values()->all()) !!};

    // Capas
    const capas = {
        perdidos: L.layerGroup(),
        resueltos: L.layerGroup()
    };
    
    // Datos y Configuración
    const allReportes = {!! json_encode($reportes) !!};
    const totalGrupos = {{ $grupos ?? 0 }};
    const counts = { perdidos: 0, resueltos: 0 };
    const santaCruzBounds = {
        norte: -17.7000, sur: -17.8500, este: -63.1000, oeste: -63.2500
    };

    // Función para validar y corregir coordenadas
    function getValidLatLng(lat, lng) {
        let nLat = parseFloat(lat);
        let nLng = parseFloat(lng);
        
        // Si las coordenadas están invertidas (Lat ~ -63, Lng ~ -17)
        if (nLat < -60 && nLng > -20) {
            return [nLng, nLat]; // Invertir
        }
        return [nLat, nLng];
    }

    function initMap() {
        // Zoom reducido a 11 para ver más lejos
        map = L.map('map').setView([-17.7833, -63.1821], 11);
        
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© Amigate Maps'
        }).addTo(map);

        // Agregar capas
        Object.values(capas).forEach(l => l.addTo(map));
        historyLayer = L.layerGroup().addTo(map);

        // Iconos
        const icons = {
            perdido: L.divIcon({
                className: 'custom-div-icon',
                html: "<div class='marker-pulse marker-perdido'></div>",
                iconSize: [20, 20], iconAnchor: [10, 10]
            }),
            resuelto: L.divIcon({
                className: 'custom-div-icon',
                html: "<div class='marker-pulse bg-primary'></div>",
                iconSize: [20, 20], iconAnchor: [10, 10]
            })
        };

        // Procesar Reportes
        allReportes.forEach(r => {
            const [lat, lng] = getValidLatLng(r.ubicacion_exacta_lat, r.ubicacion_exacta_lng);
            // Normalizar el tipo de reporte (quitar espacios y minúsculas)
            let type = (r.tipo_reporte || '').toString().trim().toLowerCase();
            let state = (r.estado || '').toString().trim().toLowerCase();
            let layerKey = null;
            let icon = null;

            if (state === 'resuelto') { 
                layerKey = 'resueltos'; 
                icon = icons.resuelto; 
                counts.resueltos++; 
            }
            else if (type === 'perdido') { 
                layerKey = 'perdidos'; 
                icon = icons.perdido; 
                counts.perdidos++; 
            }
            
            if (layerKey) {
                const popupContent = getPopupContent(r);
                const marker = L.marker([lat, lng], {icon: icon})
                    .bindPopup(popupContent, {minWidth: 300, maxWidth: 350});
                
                marker.reportData = r; // Adjuntar datos para historial
                marker.addTo(capas[layerKey]);
            }
        });

        // Eventos para historial de movimiento
        map.on('popupopen', function(e) {
            historyLayer.clearLayers();
            const marker = e.popup._source;
            if (!marker || !marker.reportData) return;
            
            const r = marker.reportData;
            
            // Obtener respuestas con ubicación para trazar ruta
            if (r.respuestas && r.respuestas.length > 0) {
                const puntos = [];
                // Punto inicial (Reporte original)
                const [startLat, startLng] = getValidLatLng(r.ubicacion_exacta_lat, r.ubicacion_exacta_lng);
                puntos.push([startLat, startLng]);
                
                // Ordenar respuestas por fecha
                const respuestasOrdenadas = r.respuestas.sort((a, b) => new Date(a.created_at) - new Date(b.created_at));

                respuestasOrdenadas.forEach(resp => {
                    if (resp.ubicacion_lat && resp.ubicacion_lng) {
                        const [rLat, rLng] = getValidLatLng(resp.ubicacion_lat, resp.ubicacion_lng);
                        puntos.push([rLat, rLng]);

                        // Marcador de avistamiento o encuentro
                        let label = (resp.tipo_respuesta === 'encontrado') ? '¡Aquí fue encontrado!' : 'Avistamiento';
                        let color = (resp.tipo_respuesta === 'encontrado') ? '#198754' : '#6f42c1';

                        L.circleMarker([rLat, rLng], {
                            radius: 8,
                            fillColor: color,
                            color: '#fff',
                            weight: 2,
                            opacity: 1,
                            fillOpacity: 0.9
                        }).bindTooltip(`${label}: ${new Date(resp.created_at).toLocaleDateString()}`).addTo(historyLayer);
                    }
                });

                // Dibujar línea si hay movimiento
                if (puntos.length > 1) {
                    L.polyline(puntos, {
                        color: '#6f42c1',
                        weight: 4,
                        opacity: 0.7,
                        dashArray: '10, 10', 
                        lineCap: 'round',
                        animate: true
                    }).addTo(historyLayer);
                }
            }
        });

        // Limpiar historial al cerrar popup
        map.on('popupclose', function() {
            historyLayer.clearLayers();
        });

        updateCounters();

        // Dibujar límite referencial (opcional, muy transparente)
        const bounds = [[santaCruzBounds.norte, santaCruzBounds.oeste], [santaCruzBounds.sur, santaCruzBounds.este]];
        L.rectangle(bounds, { color: '#2563eb', weight: 1, fillOpacity: 0.05 }).addTo(map);

        if (cuadrantesData.length > 0) cargarCuadrantesExistentes();
    }

    function getPopupContent(r) {
        let type = (r.tipo_reporte || '').toString().trim().toLowerCase();
        let colorClass = type === 'perdido' ? 'danger' : (type === 'encontrado' ? 'success' : 'info');
        let badge = r.recompensa > 0 ? `<span class="badge bg-warning text-dark me-1">🏆 Recompensa: ${r.recompensa}</span>` : '';
        let urgente = r.prioridad === 'urgente' ? '<span class="badge bg-danger animate__animated animate__flash infinite">URGENTE</span>' : '';
        let foto = r.imagenes && r.imagenes.length > 0 ? 
            `<div class="mb-2" style="height: 150px; background-image: url('/storage/${r.imagenes[0].ruta}'); background-size: cover; background-position: center; border-radius: 8px;"></div>` : 
            '';

        return `
            <div class="amber-popup">
                <div class="popup-header bg-${colorClass} text-white p-2 rounded-top">
                    <h6 class="mb-0 fw-bold text-uppercase"><i class="bi bi-megaphone-fill"></i> ${r.tipo_reporte}</h6>
                </div>
                <div class="p-3">
                    ${foto}
                    <h5 class="fw-bold mb-1">${r.titulo}</h5>
                    <div class="mb-2">${urgente} ${badge}</div>
                    
                    <p class="small text-muted mb-2">
                        <i class="bi bi-tag"></i> ${r.categoria ? r.categoria.nombre : 'General'}<br>
                        <i class="bi bi-calendar"></i> ${new Date(r.created_at).toLocaleDateString()}
                    </p>
                    
                    <p class="small mb-3 text-truncate-2">${r.descripcion || 'Sin descripción'}</p>
                    
                    <a href="/reportes/${r.id}" class="btn btn-${colorClass} btn-sm w-100 fw-bold">
                        VER DETALLES COMPLETOS
                    </a>
                </div>
            </div>
        `;
    }

    function updateCounters() {
        if(document.getElementById('countPerdidos')) document.getElementById('countPerdidos').textContent = counts.perdidos;
        if(document.getElementById('countResueltos')) document.getElementById('countResueltos').textContent = counts.resueltos;
    }

    function toggleLayer(type) {
        if (document.getElementById('show' + type.charAt(0).toUpperCase() + type.slice(1)).checked) {
            map.addLayer(capas[type]);
        } else {
            map.removeLayer(capas[type]);
        }
    }

    // Cargar cuadrantes existentes de la base de datos (desde PHP)
    function cargarCuadrantesExistentes() {
        try {
            // Limpiar cuadrantes anteriores
            rectangles.forEach(rect => map.removeLayer(rect));
            rectangles = [];
            
            if (cuadrantesData.length === 0) {
                return;
            }

            // Dibujar cada cuadrante en el mapa
            for (const cuadrante of cuadrantesData) {
                const bounds = [
                    [cuadrante.lat_min, cuadrante.lng_min],
                    [cuadrante.lat_max, cuadrante.lng_max]
                ];
                
                const zona = cuadrante.zona || determinarZona(cuadrante.centro_lat, cuadrante.centro_lng);
                
                const rect = L.rectangle(bounds, {
                    color: getColorPorZona(zona),
                    weight: 1,
                    fillOpacity: 0.1
                }).addTo(map);

                // Obtener barrios del cuadrante (desde el array barrios)
                const barrios = Array.isArray(cuadrante.barrios) ? cuadrante.barrios : [];
                
                const barriosTexto = barrios.length > 0 
                    ? barrios.join('<br>') 
                    : 'Sin barrios';

                rect.bindPopup(`
                    <div style="min-width: 200px;">
                        <h6 style="margin-bottom: 10px; color: #2563eb;">
                            <i class="bi bi-geo-alt-fill"></i> ${cuadrante.nombre}
                        </h6>
                        <p style="margin: 5px 0;">
                            <strong>Código:</strong> ${cuadrante.codigo}<br>
                            <strong>Zona:</strong> ${zona}<br>
                            <strong>Ciudad:</strong> ${cuadrante.ciudad}<br>
                            <strong>Barrios:</strong> ${barrios.length}
                        </p>
                        <hr style="margin: 10px 0; border-color: #e2e8f0;">
                        <div style="max-height: 150px; overflow-y: auto;">
                            <small>${barriosTexto}</small>
                        </div>
                    </div>
                `);

                rectangles.push(rect);
            }

            // Ajustar el mapa para que se vean todos los cuadrantes
            if (rectangles.length > 0) {
                const group = L.featureGroup(rectangles);
                map.fitBounds(group.getBounds().pad(0.1));
            }
            
        } catch (error) {
            console.error('Error:', error);
        }
    }

    // Determinar zona según coordenadas
    function determinarZona(lat, lng) {
        const centroLat = (santaCruzBounds.norte + santaCruzBounds.sur) / 2;
        const centroLng = (santaCruzBounds.este + santaCruzBounds.oeste) / 2;
        
        if (Math.abs(lat - centroLat) < 0.04 && Math.abs(lng - centroLng) < 0.04) {
            return 'Centro';
        } else if (lat > centroLat) {
            return lng > centroLng ? 'Noreste' : 'Norte';
        } else {
            return lng > centroLng ? 'Este' : 'Sur';
        }
    }

    // Color por zona
    function getColorPorZona(zona) {
        const colores = {
            'Norte': '#FF6B6B',
            'Noreste': '#4ECDC4',
            'Este': '#45B7D1',
            'Sur': '#96CEB4',
            'Centro': '#FFEAA7',
            'Oeste': '#D4A5A5',
            'Suroeste': '#9B59B6',
            'Noroeste': '#3498DB'
        };
        return colores[zona] || '#95a5a6';
    }

    document.addEventListener('DOMContentLoaded', initMap);
</script>
@endpush

