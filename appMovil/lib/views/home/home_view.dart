import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../feed/feed_view.dart';
import '../perfil/perfil_view.dart';
import '../widgets/main_drawer.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../../viewmodels/notificaciones_viewmodel.dart';
import '../notificaciones/notificaciones_view.dart';
import '../crear_ficha/crear_ficha_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  void _onLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres salir?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthViewModel>().logout();
            },
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  final List<Widget?> _pages = [null, null];

  Widget _getPage(int index) {
    if (_pages[index] == null) {
      if (index == 0) {
        _pages[index] = const FeedView();
      } else {
        _pages[index] = const PerfilView();
      }
    }
    return _pages[index]!;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const MainDrawer(),
        appBar: _currentIndex == 0
            ? AppBar(
                title: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.radar, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Echoes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                actions: [
                  Consumer<NotificacionesViewModel>(
                    builder: (context, notifVm, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications),
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
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                bottom: const TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: [
                    Tab(icon: Icon(Icons.public), text: 'Todos'),
                    Tab(icon: Icon(Icons.folder_shared), text: 'Mis búsquedas'),
                  ],
                ),
              )
            : AppBar(
                title: const Text('Centro de Cuentas'),
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Cerrar sesión',
                    onPressed: _onLogout,
                  ),
                ],
              ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _getPage(0),
            _getPage(1),
          ],
        ),
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () async {
                  final feedVmLocal = context.read<FeedViewModel>();
                  final nav = Navigator.of(context);
                  final result = await nav.push(
                    MaterialPageRoute(builder: (_) => const CrearFichaView()),
                  );
                  if (result == true) {
                    feedVmLocal.cargarFichas();
                  }
                },
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Reportar'),
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
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF1B5E20),
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.radar),
                activeIcon: Icon(Icons.radar, color: Color(0xFF1B5E20)),
                label: 'Operativos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person, color: Color(0xFF1B5E20)),
                label: 'Mi Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
