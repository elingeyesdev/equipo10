@extends('layouts.app')

@section('title', 'Editor de Cuadrantes - Herramienta de Admin')

@push('styles')
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet.draw/1.0.4/leaflet.draw.css" />
<style>
    .editor-container {
        height: calc(100vh - 120px);
        display: flex;
        gap: 20px;
        padding: 10px;
    }
    #map-editor {
        flex: 1;
        border-radius: 15px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        z-index: 1;
    }
    .sidebar-editor {
        width: 350px;
        background: white;
        border-radius: 15px;
        padding: 20px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.08);
        overflow-y: auto;
    }
    .status-badge {
        font-size: 0.8rem;
        padding: 4px 8px;
        border-radius: 20px;
        margin-bottom: 10px;
        display: inline-block;
    }
    .btn-save {
        background: linear-gradient(135deg, #2563eb 0%, #1e40af 100%);
        color: white;
        border: none;
        width: 100%;
        padding: 12px;
        border-radius: 10px;
        font-weight: 700;
        margin-top: 15px;
    }
    .btn-save:hover {
        background: linear-gradient(135deg, #1d4ed8 0%, #1e3a8a 100%);
    }
    .instruction-card {
        background: #f8fafc;
        border-left: 4px solid #2563eb;
        padding: 15px;
        margin-bottom: 20px;
        font-size: 0.85rem;
    }
    .drawn-item {
        padding: 10px;
        border-bottom: 1px solid #f1f5f9;
        cursor: pointer;
        transition: background 0.2s;
    }
    .drawn-item:hover {
        background: #f8fafc;
    }
</style>
@endpush

@section('content')
<div class="container-fluid">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <div>
            <h4 class="fw-bold mb-0 text-primary"><i class="bi bi-pencil-square"></i> Taller de Dibujo de Cuadrantes</h4>
            <p class="text-muted small mb-0">Define las zonas de búsqueda oficiales de Santa Cruz</p>
        </div>
        <a href="{{ route('cuadrantes.index') }}" class="btn btn-outline-secondary btn-sm">
            <i class="bi bi-arrow-left"></i> Volver al Mapa General
        </a>
    </div>

    <div class="editor-container">
        <!-- Panel de Control -->
        <div class="sidebar-editor">
            <div class="instruction-card">
                <strong>Instrucciones:</strong><br>
                1. Usa el icono de polígono <i class="bi bi-pentagon"></i> en el mapa.<br>
                2. Haz clics para trazar los bordes de la zona.<br>
                3. Al terminar, rellena los datos aquí debajo y guarda.
            </div>

            <form id="form-cuadrante">
                <input type="hidden" id="cuadrante_id">
                <div class="mb-3">
                    <label class="form-label fw-bold">Nombre del Cuadrante</label>
                    <input type="text" id="nombre" class="form-control" placeholder="Ej: UV-12 Barrio Lujan" required>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-bold">Código Único</label>
                    <input type="text" id="codigo" class="form-control" placeholder="Ej: SCZ-UV12" required>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-bold">Zona</label>
                    <select id="zona" class="form-select">
                        <option value="Norte">Norte</option>
                        <option value="Sur">Sur</option>
                        <option value="Este">Este</option>
                        <option value="Oeste">Oeste</option>
                        <option value="Centro">Centro</option>
                        <option value="Noreste">Noreste</option>
                        <option value="Sureste">Sureste</option>
                        <option value="Nororeste">Nororeste</option>
                        <option value="Suroeste">Suroeste</option>
                    </select>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-bold">Ciudad</label>
                    <input type="text" id="ciudad" class="form-control" value="Santa Cruz de la Sierra" required>
                </div>

                <div id="geometry-status" class="alert alert-info py-2" style="font-size: 0.8rem;">
                    <i class="bi bi-info-circle"></i> No hay dibujo seleccionado
                </div>

                <button type="submit" class="btn-save" id="btn-save-action" disabled>
                    <i class="bi bi-cloud-arrow-up"></i> GUARDAR CAMBIOS
                </button>
                <button type="button" class="btn btn-outline-danger w-100 mt-2" id="btn-delete" style="display: none;" onclick="deleteCuadrante()">
                    <i class="bi bi-trash"></i> ELIMINAR CUADRANTE
                </button>
                <button type="button" class="btn btn-link w-100 mt-1 text-muted small" onclick="resetForm()">
                    Cancelar / Nuevo
                </button>
            </form>

            <hr>
            <h6 class="fw-bold"><i class="bi bi-list-ul"></i> Cuadrantes Guardados</h6>
            <div id="drawn-list" class="mt-2">
                <!-- Se llena con JS -->
                @foreach($cuadrantes as $c)
                <div class="drawn-item border rounded mb-2 p-2">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <strong class="text-dark">{{ $c->codigo }}</strong>
                            <div class="small text-muted">{{ $c->nombre }}</div>
                        </div>
                        <button class="btn btn-sm btn-primary" onclick="focusCuadrante('{{ $c->id }}')">
                            <i class="bi bi-pencil"></i> Editar
                        </button>
                    </div>
                </div>
                @endforeach
            </div>
        </div>

        <!-- Mapa -->
        <div id="map-editor"></div>
    </div>
</div>
@endsection

@push('scripts')
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet.draw/1.0.4/leaflet.draw.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

<script>
    let map;
    let drawControl;
    let drawnItems = new L.FeatureGroup();
    let existingItems = new L.FeatureGroup(); // Capa para los que ya existen
    let currentLayer = null;
    let currentGeoJSON = null;
    let existingData = []; // Memoria global de cuadrantes

    // Inicializar Mapa
    function initMap() {
        map = L.map('map-editor').setView([-17.7833, -63.1821], 13);
        
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap'
        }).addTo(map);

        map.addLayer(existingItems);
        map.addLayer(drawnItems);

        // CARGAR CUADRANTES EXISTENTES
        existingData = [
            @foreach($cuadrantes as $c)
                @if($c->geometria)
                {
                    id: '{{ $c->id }}',
                    nombre: '{{ $c->nombre }}',
                    codigo: '{{ $c->codigo }}',
                    zona: '{{ $c->zona }}',
                    ciudad: '{{ $c->ciudad }}',
                    geo: {!! $c->geometria !!}
                },
                @endif
            @endforeach
        ];

        existingData.forEach(data => {
            L.geoJSON(data.geo, {
                style: {
                    color: '#64748b', // Gris para los ya existentes
                    weight: 2,
                    opacity: 0.6,
                    fillOpacity: 0.2
                }
            }).bindPopup(`<strong>${data.codigo}</strong><br>${data.nombre}`)
              .addTo(existingItems);
        });

        // Configurar herramientas de dibujo
        drawControl = new L.Control.Draw({
            draw: {
                polygon: {
                    allowIntersection: false,
                    showArea: true,
                    drawError: { color: '#e1e100', message: '<strong>Error:<strong> no puedes cruzar líneas' },
                    shapeOptions: { color: '#2563eb' },
                    // Activamos guía visual para ayudar al pulso
                    guidelineDistance: 10,
                },
                polyline: false,
                circle: false,
                rectangle: false,
                marker: false,
                circlemarker: false,
            },
            edit: {
                featureGroup: drawnItems,
                remove: true
            }
        });
        map.addControl(drawControl);

        // FUNCIÓN DE IMÁN (SNAPPING) MANUAL
        // Leaflet.draw no tiene snapping nativo perfecto sin plugin, 
        // pero podemos habilitar que se pegue a los nodos existentes al dibujar
        map.on('draw:drawstart', function(e) {
            // Aquí podríamos inicializar un plugin de snap si lo tuviéramos
        });

        // Evento al terminar de dibujar
        map.on(L.Draw.Event.CREATED, function (e) {
            // Limpiar dibujo anterior si existe
            drawnItems.clearLayers();
            
            let layer = e.layer;
            drawnItems.addLayer(layer);
            currentLayer = layer;
            
            // Extraer GeoJSON
            currentGeoJSON = JSON.stringify(layer.toGeoJSON());
            
            // Tarea E7.2: Capturar arreglo de coordenadas (vértices) al cerrar polígono
            let verticesHTML = '<div class="mt-2 text-start" style="font-family: monospace; font-size: 0.75rem; max-height: 80px; overflow-y: auto;"><strong>Vértices capturados:</strong><br>';
            if(layer.getLatLngs && layer.getLatLngs().length > 0) {
                let latlngs = layer.getLatLngs()[0]; // Obtener el primer anillo del polígono
                latlngs.forEach((coord, i) => {
                    verticesHTML += `[${coord.lat.toFixed(6)}, ${coord.lng.toFixed(6)}]<br>`;
                });
            }
            verticesHTML += '</div>';

            document.getElementById('geometry-status').className = 'alert alert-success py-2';
            document.getElementById('geometry-status').innerHTML = '<i class="bi bi-check-circle"></i> ¡Área trazada correctamente!' + verticesHTML;
            document.getElementById('btn-save-action').disabled = false;
        });

        // Evento al borrar
        map.on(L.Draw.Event.DELETED, function () {
            currentGeoJSON = null;
            document.getElementById('geometry-status').className = 'alert alert-info py-2';
            document.getElementById('geometry-status').innerHTML = '<i class="bi bi-info-circle"></i> No hay dibujo seleccionado';
            document.getElementById('btn-save-action').disabled = true;
        });
    }

    // Guardar vía AJAX
    document.getElementById('form-cuadrante').addEventListener('submit', function(e) {
        e.preventDefault();
        
        if (!currentGeoJSON) {
            Swal.fire('Error', 'Primero debes dibujar un área en el mapa', 'error');
            return;
        }

        // Calcular centro
        let bounds = currentLayer.getBounds();
        let center = {
            lat: bounds.getCenter().lat,
            lng: bounds.getCenter().lng
        };

        const data = {
            id: document.getElementById('cuadrante_id').value,
            nombre: document.getElementById('nombre').value,
            codigo: document.getElementById('codigo').value,
            zona: document.getElementById('zona').value,
            ciudad: document.getElementById('ciudad').value,
            geometria: currentGeoJSON,
            centro: center,
            _token: '{{ csrf_token() }}'
        };

        console.log("Enviando datos:", data);

        fetch('/cuadrantes/save-geometry', {
            method: 'POST',
            headers: { 
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': '{{ csrf_token() }}'
            },
            body: JSON.stringify(data)
        })
        .then(response => response.json())
        .then(res => {
            if (res.error) {
                Swal.fire('Error', res.error, 'error');
            } else {
                Swal.fire('¡Éxito!', 'Cuadrante guardado y grabado en el sistema', 'success')
                .then(() => location.reload());
            }
        })
        .catch(err => Swal.fire('Error', 'No se pudo guardar', 'error'));
    });

    function focusCuadrante(id) {
        const item = existingData.find(d => d.id === id);
        if (!item) return;

        // Resetear capas de dibujo
        drawnItems.clearLayers();
        
        // Llenar formulario
        document.getElementById('cuadrante_id').value = item.id;
        document.getElementById('nombre').value = item.nombre;
        document.getElementById('codigo').value = item.codigo;
        document.getElementById('zona').value = item.zona || 'Norte';
        document.getElementById('ciudad').value = item.ciudad || 'Santa Cruz de la Sierra';
        document.getElementById('btn-delete').style.display = 'block';
        document.getElementById('btn-save-action').disabled = false;
        document.getElementById('btn-save-action').innerHTML = '<i class="bi bi-check-circle"></i> ACTUALIZAR CUADRANTE';

        // Cargar geometría para edición
        let layer = L.geoJSON(item.geo).getLayers()[0];
        drawnItems.addLayer(layer);
        currentLayer = layer;
        currentGeoJSON = JSON.stringify(layer.toGeoJSON());

        // Enfocar en el mapa
        map.fitBounds(layer.getBounds());

        document.getElementById('geometry-status').className = 'alert alert-warning py-2';
        document.getElementById('geometry-status').innerHTML = '<i class="bi bi-pencil"></i> Editando cuadrante existente';
    }

    function resetForm() {
        document.getElementById('form-cuadrante').reset();
        document.getElementById('cuadrante_id').value = '';
        document.getElementById('btn-delete').style.display = 'none';
        document.getElementById('btn-save-action').disabled = true;
        document.getElementById('btn-save-action').innerHTML = '<i class="bi bi-cloud-arrow-up"></i> GUARDAR CUADRANTE';
        drawnItems.clearLayers();
        currentLayer = null;
        currentGeoJSON = null;
        document.getElementById('geometry-status').className = 'alert alert-info py-2';
        document.getElementById('geometry-status').innerHTML = '<i class="bi bi-info-circle"></i> No hay dibujo seleccionado';
    }

    function deleteCuadrante() {
        const id = document.getElementById('cuadrante_id').value;
        if (!id) return;

        Swal.fire({
            title: '¿Estás seguro?',
            text: "Esta acción no se puede deshacer",
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#d33',
            cancelButtonColor: '#3085d6',
            confirmButtonText: 'Sí, eliminar',
            cancelButtonText: 'Cancelar'
        }).then((result) => {
            if (result.isConfirmed) {
                fetch(`/cuadrantes/${id}`, {
                    method: 'DELETE',
                    headers: { 
                        'X-CSRF-TOKEN': '{{ csrf_token() }}',
                        'Accept': 'application/json'
                    }
                })
                .then(() => {
                    Swal.fire('Eliminado', 'El cuadrante ha sido borrado', 'success')
                    .then(() => location.reload());
                });
            }
        });
    }

    window.onload = initMap;
</script>
@endpush
