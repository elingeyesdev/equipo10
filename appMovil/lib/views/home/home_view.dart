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
}

/// Definición simple de una tab del navbar.
class _TabDef {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _TabDef(
      {required this.label, required this.icon, required this.activeIcon});
}
