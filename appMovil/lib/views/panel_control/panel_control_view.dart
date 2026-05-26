import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../viewmodels/panel_control_viewmodel.dart';
import '../../viewmodels/evidencia_viewmodel.dart';
import '../../widgets/map_tile_layer.dart';
import '../../widgets/lpp_marker.dart';
import 'revision_evidencias_view.dart';

class PanelControlView extends StatefulWidget {
  final String fichaId;

  const PanelControlView({super.key, required this.fichaId});

  @override
  State<PanelControlView> createState() => _PanelControlViewState();
}

class _PanelControlViewState extends State<PanelControlView> {
  final MapController _mapController = MapController();
  bool _useSatellite = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<PanelControlViewModel>();
      vm.cargarDatos(widget.fichaId);
      vm.iniciarPolling(widget.fichaId);
      // Cargar evidencias (modo creador: ve todas)
      context
          .read<EvidenciaViewModel>()
          .cargarEvidencias(widget.fichaId, esCreador: true);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    // Detener polling si la vista se destruye
    context.read<PanelControlViewModel>().detenerPolling();
    super.dispose();
  }

  Color _getColorParaEtiqueta(String etiqueta) {
    switch (etiqueta) {
      case 'Visto por última vez': return Colors.purple;
      case 'Nueva pista': return Colors.grey;
      case 'Última señal': return Colors.white;
      case 'Zona de interés': return Colors.yellow;
      default: return const Color(0xFFF59E0B);
    }
  }

  Future<void> _cambiarEstado(BuildContext context, String nuevoEstado) async {
    final vm = context.read<PanelControlViewModel>();
    String? justificacion;

    if (nuevoEstado == 'pausado' || nuevoEstado == 'cerrado') {
      justificacion = await _mostrarDialogoJustificacion(context, nuevoEstado);
      if (justificacion == null) return; // Canceló el diálogo
    } else {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmar Reanudación'),
          content: const Text('¿Deseas volver a poner la búsqueda en estado Activa? Los voluntarios podrán unirse nuevamente.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              child: const Text('Reanudar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    final success = await vm.cambiarEstado(widget.fichaId, nuevoEstado, justificacion: justificacion);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Búsqueda cambiada a $nuevoEstado exitosamente.'),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Error al actualizar el estado.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<String?> _mostrarDialogoJustificacion(BuildContext context, String nuevoEstado) {
    final TextEditingController ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        String actionTitle = nuevoEstado == 'cerrado' ? 'Finalizar' : 'Pausar';
        return AlertDialog(
          title: Text('$actionTitle Búsqueda'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Por favor, indica la justificación o razón para $actionTitle esta búsqueda.'),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Escribe la justificación aquí...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('La justificación es obligatoria.')),
                  );
                } else {
                  Navigator.pop(ctx, ctrl.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: nuevoEstado == 'cerrado' ? Colors.red : const Color(0xFFFF9800),
              ),
              child: Text(actionTitle),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarDialogoAlertaMasiva(BuildContext context) async {
    final vm = context.read<PanelControlViewModel>();
    final TextEditingController ctrl = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.campaign, color: Color(0xFF1B5E20)),
            SizedBox(width: 8),
            Text('Alerta Masiva'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Este mensaje será enviado a todos los voluntarios que estén buscando o esperando en este momento.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Ej: Atención equipo, concentremos la búsqueda en la zona norte del cuadrante...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx); // Cerrar diálogo
              
              final success = await vm.enviarAlertaMasiva(widget.fichaId, ctrl.text.trim());
              if (!mounted) return;
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Alerta masiva enviada con éxito!'),
                    backgroundColor: Color(0xFF1B5E20),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(vm.errorMessage ?? 'Error al enviar alerta.'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
            child: const Text('Enviar Alerta'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PanelControlViewModel>();

    if (vm.isLoading && vm.ficha == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (vm.ficha == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panel de Control')),
        body: const Center(child: Text('Búsqueda no encontrada.')),
      );
    }

    final ficha = vm.ficha!;
    final bool isActive = ficha.estado == 'activo';
    final bool isClosed = ficha.estado == 'cerrado' || ficha.estado == 'resuelto';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel de Comando'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'General'),
              Tab(icon: Icon(Icons.map), text: 'Mapa de Cobertura'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(), // Evita conflicto con gestos del mapa
          children: [
            _buildTabGeneral(context, vm, ficha, isActive),
            _buildTabMapa(vm, ficha),
          ],
        ),
        floatingActionButton: isClosed
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _mostrarDialogoAlertaMasiva(context),
                backgroundColor: const Color(0xFF0277BD),
                icon: const Icon(Icons.campaign, color: Colors.white),
                label: const Text('Alerta Masiva', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
      ),
    );
  }

  Widget _buildTabGeneral(BuildContext context, PanelControlViewModel vm, dynamic ficha, bool isActive) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen de la Ficha
          Text(
            ficha.titulo,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _EstadoBadge(estado: ficha.estado),
          if (ficha.justificacion != null && ficha.justificacion!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                border: Border.all(color: const Color(0xFFBDBDBD)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Justificación / Resolución:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5F6368))),
                  const SizedBox(height: 4),
                  Text(ficha.justificacion!),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Acciones Rápidas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isActive)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: vm.isLoading ? null : () => _cambiarEstado(context, 'activo'),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Reanudar'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), foregroundColor: Colors.white),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: vm.isLoading ? null : () => _cambiarEstado(context, 'pausado'),
                    icon: const Icon(Icons.pause),
                    label: const Text('Pausar'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800), foregroundColor: Colors.white),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: vm.isLoading || ficha.estado == 'cerrado' || ficha.estado == 'resuelto' ? null : () => _cambiarEstado(context, 'cerrado'),
                  icon: const Icon(Icons.stop),
                  label: const Text('Finalizar'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // Boton de revision de evidencias
          _buildBotonRevisionEvidencias(context, vm),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Lista de voluntarios
          Row(
            children: [
              const Icon(Icons.people, color: Color(0xFF1B5E20)),
              const SizedBox(width: 8),
              Text(
                'Voluntarios (${vm.voluntarios.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (vm.voluntarios.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Aún no hay voluntarios en esta búsqueda.', style: TextStyle(color: Color(0xFF757575))),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vm.voluntarios.length,
              itemBuilder: (context, index) {
                final v = vm.voluntarios[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE8F5E9),
                    child: Text(
                      v.nombreCompleto.isNotEmpty ? v.nombreCompleto[0].toUpperCase() : '?',
                      style: const TextStyle(color: Color(0xFF1B5E20)),
                    ),
                  ),
                  title: Text(v.nombreCompleto.isNotEmpty ? v.nombreCompleto : 'Sin Nombre'),
                  subtitle: Text(v.telefono.isNotEmpty ? v.telefono : 'Sin teléfono'),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBotonRevisionEvidencias(BuildContext context, PanelControlViewModel vm) {
    final evVm = context.watch<EvidenciaViewModel>();
    final pendingCount = evVm.evidencias.where((e) => e.estado == 'pending').length;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RevisionEvidenciasView(
                  reporteId: widget.fichaId,
                  reporteTitulo: vm.ficha?.titulo ?? 'Búsqueda',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.rate_review_outlined,
                    color: Color(0xFFB8860B),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Revisión de Evidencias',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF202124),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pendingCount > 0
                            ? '$pendingCount evidencia(s) esperando revisión'
                            : 'Ver todas las evidencias enviadas',
                        style: TextStyle(
                          fontSize: 13,
                          color: pendingCount > 0 ? const Color(0xFFD32F2F) : const Color(0xFF5F6368),
                          fontWeight: pendingCount > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (pendingCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF5F6368),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabMapa(PanelControlViewModel vm, dynamic ficha) {
    LatLng? center;
    
    // Calcular el centro del mapa (Prioridad: LPP > Cuadrante > Recorridos)
    if (ficha.latitud != null && ficha.longitud != null) {
      center = LatLng(ficha.latitud!, ficha.longitud!);
    } else if (ficha.cuadranteLatMin != null && ficha.cuadranteLatMax != null &&
        ficha.cuadranteLngMin != null && ficha.cuadranteLngMax != null) {
      center = LatLng(
        (ficha.cuadranteLatMin! + ficha.cuadranteLatMax!) / 2,
        (ficha.cuadranteLngMin! + ficha.cuadranteLngMax!) / 2,
      );
    } else if (vm.recorridosMap.isNotEmpty) {
      center = vm.recorridosMap.first.first;
    }

    if (center == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No hay datos de ubicación.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Asegúrese de que el reporte tenga una ubicación inicial o cuadrante asignado.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Colores para diferenciar voluntarios (heat map simple)
    final List<Color> pathColors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal
    ];

    // Combinar el LPP original con las pistas adicionales
    final List<Marker> markersPistas = [];
    
    // 1. Agregar el punto original (LPP)
    if (ficha.latitud != null && ficha.longitud != null) {
      markersPistas.add(
        Marker(
          point: LatLng(ficha.latitud!, ficha.longitud!),
          width: 80,
          height: 70,
          alignment: Alignment.center,
          child: LppMarker(
            fotoUrl: ficha.fotoUrl,
            nombre: 'Visto por última vez',
            color: const Color(0xFFD32F2F), // Rojo para el LPP
          ),
        )
      );
    }
    
    // 2. Agregar las evidencias fotograficas capturadas (solo approved)
    final evVm = context.read<EvidenciaViewModel>();
    final evidenciasAprobadas =
        evVm.evidencias.where((e) => e.estado == 'approved').toList();
    markersPistas.addAll(
        evidenciasAprobadas.where((e) => e.lat != null && e.lng != null).map((evidencia) {
      return Marker(
        point: LatLng(evidencia.lat!, evidencia.lng!),
        width: 80,
        height: 70,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {
            Future.delayed(const Duration(milliseconds: 150), () {
              if (!mounted) return;
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Evidencia'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (evidencia.fotoUrl != null && evidencia.fotoUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              evidencia.fotoUrl!,
                              height: 150,
                              width: 300,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(evidencia.descripcion),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            });
          },
          child: LppMarker(
            fotoUrl: evidencia.fotoUrl,
            nombre: 'Evidencia',
            color: Colors.blueAccent,
          ),
        ),
      );
    }));
    
    // 2. Agregar el resto de pistas
    markersPistas.addAll(vm.pistas.map((pista) {
      return Marker(
        point: pista.punto,
        width: 80,
        height: 70,
        alignment: Alignment.center,
        child: LppMarker(
          fotoUrl: ficha.fotoUrl,
          nombre: pista.etiqueta,
          color: _getColorParaEtiqueta(pista.etiqueta),
        ),
      );
    }));

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15.0,
          ),
          children: [
            MapTileLayer(useSatellite: _useSatellite),
            // Polígono del cuadrante
            if (ficha.cuadranteLatMin != null)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: [
                      LatLng(ficha.cuadranteLatMax!, ficha.cuadranteLngMin!),
                      LatLng(ficha.cuadranteLatMax!, ficha.cuadranteLngMax!),
                      LatLng(ficha.cuadranteLatMin!, ficha.cuadranteLngMax!),
                      LatLng(ficha.cuadranteLatMin!, ficha.cuadranteLngMin!),
                    ],
                    color: Colors.blue.withOpacity(0.1),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            // Recorridos de voluntarios
            PolylineLayer(
              polylines: List.generate(vm.rutasVoluntarios.length, (index) {
                final ruta = vm.rutasVoluntarios[index];
                final originalIndex = vm.todasLasRutas.indexOf(ruta);
                return Polyline(
                  points: ruta.puntos,
                  color: pathColors[originalIndex % pathColors.length].withOpacity(0.7),
                  strokeWidth: 4.0,
                );
              }),
            ),
            // Marcadores de posición actual de voluntarios
            MarkerLayer(
              markers: List.generate(vm.rutasVoluntarios.length, (index) {
                final ruta = vm.rutasVoluntarios[index];
                if (ruta.puntos.isEmpty) return null;
                final lastPoint = ruta.puntos.last;
                final originalIndex = vm.todasLasRutas.indexOf(ruta);
                final markerColor = pathColors[originalIndex % pathColors.length];
                
                return Marker(
                  point: lastPoint,
                  width: 100,
                  height: 60,
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))
                          ],
                        ),
                        child: Text(
                          ruta.nombre,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: markerColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Icon(
                        Icons.person_pin_circle,
                        color: markerColor,
                        size: 32,
                        shadows: const [Shadow(color: Colors.white, blurRadius: 2)],
                      ),
                    ],
                  ),
                );
              }).whereType<Marker>().toList(),
            ),
            // Marcadores de pistas y LPP
            MarkerLayer(
              markers: markersPistas,
            ),
          ],
        ),
        // Filtro de Voluntarios en la parte superior
        if (vm.todasLasRutas.isNotEmpty)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: const Text('Todos'),
                      selected: vm.filtroNombreVoluntario == null,
                      onSelected: (selected) {
                        if (selected) vm.setFiltroVoluntario(null);
                      },
                      selectedColor: const Color(0xFF1B5E20).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF1B5E20),
                    ),
                  ),
                  ...vm.todasLasRutas.map((ruta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(ruta.nombre),
                        selected: vm.filtroNombreVoluntario == ruta.nombre,
                        onSelected: (selected) {
                          if (selected) {
                            vm.setFiltroVoluntario(ruta.nombre);
                            // Opcional: Centrar la cámara en el último punto del voluntario seleccionado
                            if (ruta.puntos.isNotEmpty) {
                              _mapController.move(ruta.puntos.last, 16.0);
                            }
                          } else {
                            vm.setFiltroVoluntario(null);
                          }
                        },
                        selectedColor: const Color(0xFF1B5E20).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF1B5E20),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        // Toggle de capas (satelital / callejero)
        Positioned(
          bottom: 56,
          right: 60,
          child: MapLayerToggleButton(
            heroTag: null,
            useSatellite: _useSatellite,
            onToggle: () => setState(() => _useSatellite = !_useSatellite),
          ),
        ),
        // Botón de centrado dinámico en LPP
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'btn_centrar_panel',
            mini: true,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1B5E20),
            onPressed: () {
              _mapController.move(center!, 15.0);
            },
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;

    if (estado == 'activo') {
      bg = const Color(0xFFE8F5E9);
      border = const Color(0xFF4CAF50);
    } else if (estado == 'pausado') {
      bg = const Color(0xFFFFF3E0);
      border = const Color(0xFFFF9800);
    } else {
      bg = const Color(0xFFFFEBEE);
      border = const Color(0xFFF44336);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(color: border, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
