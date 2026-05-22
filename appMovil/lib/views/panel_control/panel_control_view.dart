import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../viewmodels/panel_control_viewmodel.dart';
import '../../widgets/map_tile_layer.dart';

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
    });
  }

  @override
  void dispose() {
    // Detener polling si la vista se destruye
    context.read<PanelControlViewModel>().detenerPolling();
    super.dispose();
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

  Widget _buildTabMapa(PanelControlViewModel vm, dynamic ficha) {
    if (vm.recorridosMap.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No hay datos de cobertura aún.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Los trazos de los voluntarios aparecerán aquí una vez que comiencen a realizar la búsqueda en el mapa.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Calcular el centro del mapa basado en el primer punto disponible
    LatLng center = vm.recorridosMap.first.first;
    if (ficha.cuadranteLatMin != null && ficha.cuadranteLatMax != null &&
        ficha.cuadranteLngMin != null && ficha.cuadranteLngMax != null) {
      center = LatLng(
        (ficha.cuadranteLatMin! + ficha.cuadranteLatMax!) / 2,
        (ficha.cuadranteLngMin! + ficha.cuadranteLngMax!) / 2,
      );
    }

    // Colores para diferenciar voluntarios (heat map simple)
    final List<Color> pathColors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal
    ];

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
              polylines: List.generate(vm.recorridosMap.length, (index) {
                return Polyline(
                  points: vm.recorridosMap[index],
                  color: pathColors[index % pathColors.length].withOpacity(0.7),
                  strokeWidth: 4.0,
                );
              }),
            ),
          ],
        ),
        // Toggle de capas (satelital / callejero)
        Positioned(
          bottom: 56,
          right: 60,
          child: MapLayerToggleButton(
            heroTag: 'btn_toggle_panel',
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
              _mapController.move(center, 15.0);
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
