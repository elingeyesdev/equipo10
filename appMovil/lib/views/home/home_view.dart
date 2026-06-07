import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../feed/feed_view.dart';
import '../feed/mis_busquedas_view.dart';
import '../perfil/perfil_view.dart';
import '../../viewmodels/notificaciones_viewmodel.dart';
import '../notificaciones/notificaciones_view.dart';
import '../crear_ficha/crear_ficha_view.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/offline_banner.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabDef(label: 'Explorar',       icon: Icons.public_outlined,       activeIcon: Icons.public),
    _TabDef(label: 'Mis Búsquedas', icon: Icons.folder_shared_outlined, activeIcon: Icons.folder_shared),
    _TabDef(label: 'Configuración',  icon: Icons.settings_outlined,      activeIcon: Icons.settings),
  ];

  // ── Widget reutilizable: campana con badge compacto al lado ──────────────
  Widget _buildNotifButton(BuildContext context) {
    return Consumer<NotificacionesViewModel>(
      builder: (context, notifVm, _) {
        return InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificacionesView()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_outlined),
                if (notifVm.unreadCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.accentDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      notifVm.unreadCount > 9 ? '9+' : '${notifVm.unreadCount}',
                      style: const TextStyle(
                        color: AppTheme.darkDark,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    // ── Tab 0: Feed principal ─────────────────────────────────────────────
    if (_currentIndex == 0) {
      return AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        centerTitle: false,
        titleSpacing: 20,
        iconTheme: const IconThemeData(color: AppTheme.darkBase),
        actionsIconTheme: const IconThemeData(color: AppTheme.darkBase),
        title: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.radar, color: AppTheme.primary, size: 32),
              const SizedBox(width: 10),
              const Text(
                'Echoes',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          _buildNotifButton(context),
          const SizedBox(width: 8),
        ],
      );
    }

    // ── Tab 1: Mis Búsquedas ─────────────────────────────────────────────
    if (_currentIndex == 1) {
      return AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkDark,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Mis búsquedas',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
              fontSize: 28,
            ),
          ),
        ),
        centerTitle: false,
        actions: [
          _buildNotifButton(context),
          const SizedBox(width: 8),
        ],
      );
    }

    // ── Tab 2: Configuración ─────────────────────────────────────────────
    // Se elimina el AppBar para permitir un encabezado personalizado en PerfilView
    return null;
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
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.darkDark,
              shape: const StadiumBorder(),
              icon: const Icon(Icons.add),
              label: const Text(
                'Reportar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkBase.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.darkLight,
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
