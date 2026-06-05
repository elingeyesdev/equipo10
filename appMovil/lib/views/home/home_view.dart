import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../feed/feed_view.dart';
import '../feed/mis_busquedas_view.dart';
import '../perfil/perfil_view.dart';
import '../../viewmodels/notificaciones_viewmodel.dart';
import '../notificaciones/notificaciones_view.dart';
import '../crear_ficha/crear_ficha_view.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/offline_banner.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  // Etiquetas del navbar
  static const _tabs = [
    _TabDef(
      label: 'Explorar',
      icon: Icons.public_outlined,
      activeIcon: Icons.public,
    ),
    _TabDef(
      label: 'Mis Búsquedas',
      icon: Icons.folder_shared_outlined,
      activeIcon: Icons.folder_shared,
    ),
    _TabDef(
      label: 'Configuración',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
    ),
  ];

  AppBar _buildAppBar() {
    // Tab 0: AppBar de Explorar con nombre de app alineado a la izquierda
    if (_currentIndex == 0) {
      return AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 20,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.radar, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Echoes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtros Avanzados',
            onPressed: () => _mostrarFiltros(context),
          ),
          Consumer<NotificacionesViewModel>(
            builder: (context, notifVm, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Notificaciones',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificacionesView()),
                    ),
                  ),
                  if (notifVm.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          notifVm.unreadCount > 9
                              ? '9+'
                              : '${notifVm.unreadCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      );
    }

    // Tab 1: Mis Búsquedas — también con notificaciones
    if (_currentIndex == 1) {
      return AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mis búsquedas'),
        actions: [
          Consumer<NotificacionesViewModel>(
            builder: (context, notifVm, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Notificaciones',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificacionesView()),
                    ),
                  ),
                  if (notifVm.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          notifVm.unreadCount > 9
                              ? '9+'
                              : '${notifVm.unreadCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      );
    }

    // Tab 2: Configuración — sin botones extra
    return AppBar(
      automaticallyImplyLeading: false,
      title: const Text('Configuración'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: OfflineBanner(
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            FeedView(),
            MisBusquedasView(),
            PerfilView(),
          ],
        ),
      ),
      floatingActionButton: _currentIndex < 2
          ? FloatingActionButton.extended(
              onPressed: () async {
                final feedVm = context.read<FeedViewModel>();
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CrearFichaView()),
                );
                if (result == true) feedVm.cargarFichas();
              },
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              icon: const Icon(Icons.add),
              label: const Text('Reportar',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: _tabs
              .map((t) => BottomNavigationBarItem(
                    icon: Icon(t.icon),
                    activeIcon: Icon(t.activeIcon),
                    label: t.label,
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _mostrarFiltros(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final feedVm = context.read<FeedViewModel>();
        
        String? tipoTemp = feedVm.filtroTipo;
        String? estadoTemp = feedVm.filtroEstado;
        double radioTemp = feedVm.filtroDistanciaRadioKm ?? 10.0; // por defecto 10 km
        
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20, 
                bottom: MediaQuery.of(context).viewInsets.bottom + 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filtros Avanzados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Filtro por Estado
                  const Text('Estado del caso:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: estadoTemp,
                    hint: const Text('Cualquier estado'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(value: 'activo', child: Text('Activo')),
                      DropdownMenuItem(value: 'pausado', child: Text('Pausado')),
                      DropdownMenuItem(value: 'resuelto', child: Text('Resuelto')),
                    ],
                    onChanged: (val) => setState(() => estadoTemp = val),
                  ),
                  const SizedBox(height: 12),
                  
                  // Filtro por Tipo de Reporte
                  const Text('Tipo de caso:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: tipoTemp,
                    hint: const Text('Cualquier tipo'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(value: 'desaparicion', child: Text('Desaparición de Persona')),
                      DropdownMenuItem(value: 'mascota', child: Text('Mascota Extraviada')),
                      DropdownMenuItem(value: 'objeto', child: Text('Objeto Perdido')),
                    ],
                    onChanged: (val) => setState(() => tipoTemp = val),
                  ),
                  const SizedBox(height: 12),

                  // Filtro de Radio de búsqueda
                  const Text('Radio de cercanía (km):', style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: radioTemp,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    label: '${radioTemp.round()} km',
                    activeColor: AppTheme.primary,
                    onChanged: (val) => setState(() => radioTemp = val),
                  ),
                  Center(child: Text('${radioTemp.round()} km a la redonda', style: const TextStyle(color: Colors.grey))),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            feedVm.setFiltros(tipo: null, estado: null, radio: null);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Limpiar Filtros'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            feedVm.setFiltros(
                              tipo: tipoTemp,
                              estado: estadoTemp,
                              radio: radioTemp,
                            );
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Definición simple de una tab del navbar.
class _TabDef {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _TabDef(
      {required this.label, required this.icon, required this.activeIcon});
}
