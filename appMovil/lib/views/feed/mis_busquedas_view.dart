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

    // Contadores
    final activas = misFichas.where((f) => f.estado?.toLowerCase() == 'activo').length;
    final pausadas = misFichas.where((f) => f.estado?.toLowerCase() == 'pausado').length;
    final resueltas = misFichas.where((f) => f.estado?.toLowerCase() == 'resuelto' || f.estado?.toLowerCase() == 'terminado').length;

    return RefreshIndicator(
      onRefresh: () => context.read<FeedViewModel>().cargarFichas(),
      color: AppTheme.primary,
      child: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Barra de búsqueda y botón de filtro
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            style: const TextStyle(color: AppTheme.darkDark, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Buscar en mis reportes...',
                              hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                              prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100),
                                borderSide: const BorderSide(color: AppTheme.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100),
                                borderSide: const BorderSide(color: AppTheme.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100),
                                borderSide: const BorderSide(color: AppTheme.primaryBase, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.filter_list, color: AppTheme.darkBase),
                          tooltip: 'Filtros',
                          onPressed: () {
                            // TODO: Implementar filtros para mis búsquedas
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
                // Subtítulo con contadores
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Text(
                      '$activas activas • $pausadas pausadas • $resueltas terminadas',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                // Contenido
                if (misFichas.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primary.withValues(alpha: 0.05),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primary.withValues(alpha: 0.1),
                              ),
                              child: const Icon(
                                Icons.manage_search_rounded,
                                size: 72,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Tu radar está vacío',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Crea tu primer reporte para mantener un registro de tus búsquedas y colaborar con la comunidad.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 40),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final feedVm = context.read<FeedViewModel>();
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const CrearFichaView()),
                              );
                              if (result == true) feedVm.cargarFichas();
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text(
                              'Crear nuevo reporte',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, index) {
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
                        childCount: misFichas.length,
                      ),
                    ),
                  ),
              ],
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
    final String estadoStr = ficha.estado?.toLowerCase() ?? '';
    final Color statusColor;
    if (estadoStr == 'activo') {
      statusColor = AppTheme.primary;
    } else if (estadoStr == 'pausado') {
      statusColor = AppTheme.accent;
    } else {
      statusColor = AppTheme.backgroundDark;
    }

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
