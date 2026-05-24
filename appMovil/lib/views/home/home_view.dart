import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../feed/feed_view.dart';
import '../feed/mis_busquedas_view.dart';
import '../perfil/perfil_view.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../../viewmodels/notificaciones_viewmodel.dart';
import '../notificaciones/notificaciones_view.dart';
import '../crear_ficha/crear_ficha_view.dart';
import '../widgets/main_drawer.dart';
import '../../theme/app_theme.dart';
import '../auth/login_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  // Títulos y configuración por tab
  static const _titles = ['Explorar', 'Mis Búsquedas', 'Mi Perfil'];
  static const _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.public_outlined),
      activeIcon: Icon(Icons.public),
      label: 'Explorar',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.folder_shared_outlined),
      activeIcon: Icon(Icons.folder_shared),
      label: 'Mis Búsquedas',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Mi Perfil',
    ),
  ];

  void _onLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres salir?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthViewModel>().logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginView()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 42),
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      foregroundColor: Colors.white,
      title: _currentIndex == 0
          ? const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.radar, color: Colors.white),
                SizedBox(width: 8),
                Text('Echoes', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            )
          : Text(_titles[_currentIndex]),
      actions: [
        // Ícono de notificaciones (solo en Explorar y Mis Búsquedas)
        if (_currentIndex < 2)
          Consumer<NotificacionesViewModel>(
            builder: (context, notifVm, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Notificaciones',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificacionesView()),
                      );
                    },
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
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          notifVm.unreadCount > 9 ? '9+' : '${notifVm.unreadCount}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesión',
          onPressed: _onLogout,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MainDrawer(),
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: Explorar (feed social completo)
          const FeedView(),
          // Tab 1: Mis Búsquedas
          const MisBusquedasView(),
          // Tab 2: Mi Perfil
          const PerfilView(),
        ],
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
              shape: const StadiumBorder(), // Píldora, igual que la barra de búsqueda
              icon: const Icon(Icons.add),
              label: const Text('Reportar',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: _navItems,
        ),
      ),
    );
  }
}
