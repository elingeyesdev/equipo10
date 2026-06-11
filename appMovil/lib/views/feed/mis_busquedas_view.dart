import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../detalle_ficha/detalle_ficha_view.dart';
import '../crear_ficha/crear_ficha_view.dart';
import '../../theme/app_theme.dart';
import '../../services/reporte_service.dart';

String _formatRelativo(DateTime? fecha) {
  if (fecha == null) return '';
  final diff = DateTime.now().difference(fecha);
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays < 7)
    return 'hace ${diff.inDays} día${diff.inDays > 1 ? 's' : ''}';
  if (diff.inDays < 30) {
    final semanas = (diff.inDays / 7).floor();
    return 'hace $semanas sem.';
  }
  final meses = (diff.inDays / 30).floor();
  return 'hace $meses mes${meses > 1 ? 'es' : ''}';
}

/// Vista que muestra únicamente los reportes creados por el usuario actual.
class MisBusquedasView extends StatefulWidget {
  const MisBusquedasView({super.key});

  @override
  State<MisBusquedasView> createState() => _MisBusquedasViewState();
}

class _MisBusquedasViewState extends State<MisBusquedasView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String? _filtroEstado;
  String? _filtroTipo;

  List<dynamic>? _todasMisFichas;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarMisFichas();
    });
  }

  Future<void> _cargarMisFichas() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final userId = context.read<AuthViewModel>().currentUserId ?? '';
    try {
      final fichas = await ReporteService().obtenerMisReportes(userId);
      if (mounted) {
        setState(() {
          _todasMisFichas = fichas;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _todasMisFichas = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String? tipoTemp = _filtroTipo;
        String? estadoTemp = _filtroEstado;

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Filtros avanzados',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Estado del reporte:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: estadoTemp,
                      hint: const Text('Cualquier estado'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todos')),
                        DropdownMenuItem(
                            value: 'activo', child: Text('Activo')),
                        DropdownMenuItem(
                            value: 'pausado', child: Text('Pausado')),
                        DropdownMenuItem(
                            value: 'resuelto',
                            child: Text('Terminado/Resuelto')),
                      ],
                      onChanged: (val) => setState(() => estadoTemp = val),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Tipo de reporte:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: tipoTemp,
                      hint: const Text('Cualquier tipo'),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Todos')),
                        DropdownMenuItem(
                            value: 'desaparicion',
                            child: Text('Desaparición de persona')),
                        DropdownMenuItem(
                            value: 'mascota',
                            child: Text('Mascota extraviada')),
                        DropdownMenuItem(
                            value: 'objeto', child: Text('Objeto perdido')),
                      ],
                      onChanged: (val) => setState(() => tipoTemp = val),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              this.setState(() {
                                _filtroTipo = null;
                                _filtroEstado = null;
                              });
                              Navigator.pop(ctx);
                            },
                            child: const Text('Limpiar filtros'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              this.setState(() {
                                _filtroTipo = tipoTemp;
                                _filtroEstado = estadoTemp;
                              });
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
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthViewModel>().currentUserId ?? '';

    final listaBase = _todasMisFichas ?? [];

    // Filtrado local
    final misFichas = listaBase.where((f) {
      if (_query.isNotEmpty) {
        final queryLower = _query.toLowerCase();
        final titulo = (f.titulo).toLowerCase();
        final descripcion = (f.descripcion).toLowerCase();
        if (!titulo.contains(queryLower) && !descripcion.contains(queryLower)) {
          return false;
        }
      }
      if (_filtroEstado != null) {
        if (f.estado?.toLowerCase() != _filtroEstado) {
          // Si el filtro es resuelto, también consideramos terminado
          if (!(_filtroEstado == 'resuelto' &&
              (f.estado?.toLowerCase() == 'terminado' ||
                  f.estado?.toLowerCase() == 'resuelto'))) {
            return false;
          }
        }
      }
      if (_filtroTipo != null &&
          f.nombreCategoria?.toLowerCase() != _filtroTipo) {
        final cat = f.nombreCategoria?.toLowerCase() ?? '';
        if (_filtroTipo == 'desaparicion' && !cat.contains('persona'))
          return false;
        if (_filtroTipo == 'mascota' && !cat.contains('mascota')) return false;
        if (_filtroTipo == 'objeto' &&
            !(cat.contains('veh') ||
                cat.contains('document') ||
                cat.contains('electr') ||
                cat.contains('objeto'))) return false;
        if (!['desaparicion', 'mascota', 'objeto'].contains(_filtroTipo) &&
            cat != _filtroTipo) return false;
      }
      return true;
    }).toList();

    // Contadores originales (sin filtrar)
    final activos =
        listaBase.where((f) => f.estado?.toLowerCase() == 'activo').length;
    final pausados =
        listaBase.where((f) => f.estado?.toLowerCase() == 'pausado').length;
    final terminados = listaBase
        .where((f) =>
            f.estado?.toLowerCase() == 'resuelto' ||
            f.estado?.toLowerCase() == 'terminado')
        .length;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<FeedViewModel>().cargarFichas(); // refrescar feed también
        await _cargarMisFichas();
      },
      color: AppTheme.primary,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Barra de búsqueda (vidrio esmerilado al flotar)
                SliverPersistentHeader(
                  floating: true,
                  delegate: _SearchBarDelegate(
                    controller: _searchCtrl,
                    query: _query,
                    onChanged: (val) {
                      setState(() {
                        _query = val;
                      });
                    },
                    onClear: () {
                      _searchCtrl.clear();
                      setState(() {
                        _query = '';
                      });
                    },
                    onFilter: _mostrarFiltros,
                  ),
                ),
                // Subtítulo con contadores
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Row(
                      children: [
                        Text(
                          '$activos activos • $pausados pausados • $terminados terminados',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
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
                          Text(
                            (_query.isNotEmpty ||
                                    _filtroEstado != null ||
                                    _filtroTipo != null)
                                ? 'No hay resultados'
                                : 'Tu radar está vacío',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            (_query.isNotEmpty ||
                                    _filtroEstado != null ||
                                    _filtroTipo != null)
                                ? 'No se encontraron reportes con los filtros aplicados.'
                                : 'Crea tu primer reporte para mantener un registro de tus búsquedas y colaborar con la comunidad.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                                MaterialPageRoute(
                                    builder: (_) => const CrearFichaView()),
                              );
                              if (result == true) {
                                feedVm.cargarFichas();
                                _cargarMisFichas();
                              }
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text(
                              'Crear nuevo reporte',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
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
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
                                  final result =
                                      await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => DetalleFichaView(
                                          fichaId: ficha.id,
                                          currentUserId: currentUserId),
                                    ),
                                  );
                                  if (result == true) {
                                    feedVm.cargarFichas();
                                    _cargarMisFichas();
                                  }
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

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilter;

  const _SearchBarDelegate({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
    required this.onFilter,
  });

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  bool shouldRebuild(_SearchBarDelegate old) => old.query != query;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: AppTheme.darkDark, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar en mis reportes...',
                hintStyle: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: AppTheme.textSecondary, size: 20),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            size: 18, color: AppTheme.textSecondary),
                        onPressed: onClear,
                      )
                    : null,
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
                  borderSide:
                      const BorderSide(color: AppTheme.primaryBase, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppTheme.darkBase),
            tooltip: 'Filtros',
            onPressed: onFilter,
          ),
          const SizedBox(width: 8),
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
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                if (ficha.nombreCategoria != null ||
                    ficha.createdAt != null) ...[
                  Row(
                    children: [
                      if (ficha.nombreCategoria != null) ...[
                        const Icon(Icons.category_outlined,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(ficha.nombreCategoria!,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textSecondary)),
                        const SizedBox(width: 12),
                      ],
                      if (ficha.createdAt != null) ...[
                        const Icon(Icons.access_time,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(_formatRelativo(ficha.createdAt),
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: statusColor, shape: BoxShape.circle),
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
