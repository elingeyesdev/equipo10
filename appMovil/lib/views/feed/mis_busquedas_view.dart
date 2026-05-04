import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../detalle_ficha/detalle_ficha_view.dart';
import '../crear_ficha/crear_ficha_view.dart';
import '../feed/feed_view.dart';
import '../../theme/app_theme.dart';

/// Vista que muestra únicamente los reportes creados por el usuario actual.
class MisBusquedasView extends StatelessWidget {
  const MisBusquedasView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FeedViewModel>();
    final currentUserId = context.read<AuthViewModel>().currentUserId ?? '';
    final misFichas = vm.fichas.where((f) => f.creadoPor == currentUserId).toList();

    return RefreshIndicator(
      onRefresh: () => context.read<FeedViewModel>().cargarFichas(),
      color: AppTheme.primary,
      child: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : misFichas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_outlined,
                          size: 72, color: AppTheme.primary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      const Text(
                        'Aún no tienes búsquedas',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Crea tu primer reporte usando el botón +',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final feedVm = context.read<FeedViewModel>();
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CrearFichaView()),
                          );
                          if (result == true) feedVm.cargarFichas();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Crear reporte'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(180, 48),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: misFichas.length,
                  itemBuilder: (_, index) {
                    final ficha = misFichas[index];
                    return RepaintBoundary(
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () async {
                            final feedVm = context.read<FeedViewModel>();
                            final result = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => DetalleFichaView(
                                    fichaId: ficha.id, currentUserId: currentUserId),
                              ),
                            );
                            if (result == true) feedVm.cargarFichas();
                          },
                          child: _MiBusquedaTile(ficha: ficha),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

/// Tile horizontal para "Mis búsquedas" con indicador de estado prominente.
class _MiBusquedaTile extends StatelessWidget {
  final dynamic ficha;
  const _MiBusquedaTile({required this.ficha});

  @override
  Widget build(BuildContext context) {
    final isActive = ficha.estado?.toLowerCase() == 'activo';
    final statusColor = isActive ? AppTheme.success : AppTheme.warning;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Indicador de estado vertical
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ficha.titulo ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  ficha.descripcion ?? '',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (ficha.estado ?? 'desconocido').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        ],
      ),
    );
  }
}
