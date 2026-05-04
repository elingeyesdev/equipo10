import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../../viewmodels/notificaciones_viewmodel.dart';
import '../../models/reporte_model.dart';
import '../detalle_ficha/detalle_ficha_view.dart';
import '../../theme/app_theme.dart';

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedViewModel>().cargarFichas();
      context.read<NotificacionesViewModel>().cargarNotificaciones();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedVm = context.watch<FeedViewModel>();
    final currentUserId = context.read<AuthViewModel>().currentUserId ?? '';

    return RefreshIndicator(
      onRefresh: () => context.read<FeedViewModel>().cargarFichas(),
      color: AppTheme.primary,
      child: _buildSocialFeed(feedVm, currentUserId),
    );
  }

  // ── Feed social con banner, buscador y sección cercana ─────────────
  Widget _buildSocialFeed(FeedViewModel vm, String currentUserId) {
    if (vm.isLoading) return const Center(child: CircularProgressIndicator());

    if (vm.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text('Error al cargar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(vm.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF5F6368))),
          ],
        ),
      );
    }

    final alertas = vm.alertas24h;
    final cercanos = vm.reportesCercanos;
    final todos = vm.fichasFiltradas;

    return CustomScrollView(
      slivers: [
        // ── Barra de búsqueda ──────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: vm.actualizarQuery,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, categoría...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                suffixIcon: vm.query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          vm.actualizarQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
        ),

        // ── Stat de operativos activos ──────────────────────────
        if (vm.query.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${vm.totalActivos} operativos activos ahora',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

        // ── Banner de alertas de las últimas 24h ───────────────
        if (vm.query.isEmpty && alertas.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.campaign, color: Color(0xFFD32F2F), size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'ÚLTIMAS 24 HORAS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD32F2F),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const Spacer(),
                      Text('${alertas.length} nuevos', style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: alertas.take(5).length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final ficha = alertas[i];
                        return _AlertaMiniCard(ficha: ficha, currentUserId: currentUserId);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

        // ── Sección: Cerca de ti ────────────────────────────────
        if (vm.query.isEmpty && cercanos.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.near_me, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'CERCA DE TI',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 1.1),
                      ),
                      const Spacer(),
                      const Text('radio 5 km', style: TextStyle(fontSize: 11, color: Color(0xFF5F6368))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...cercanos.take(3).map((ficha) => _FichaCard(
                        ficha: ficha,
                        currentUserId: currentUserId,
                        distanciaKm: vm.distanciaKmDesde(ficha),
                      )),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),

        // ── Separador antes del listado general ─────────────────
        if (vm.query.isEmpty && (alertas.isNotEmpty || cercanos.isNotEmpty))
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.list, color: Color(0xFF5F6368), size: 16),
                  const SizedBox(width: 6),
                  const Text('TODOS LOS REPORTES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5F6368), letterSpacing: 1.1)),
                ],
              ),
            ),
          ),

        // ── Lista principal ─────────────────────────────────────
        todos.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 64, color: Color(0xFF4CAF50)),
                      const SizedBox(height: 12),
                      Text(
                        vm.query.isNotEmpty ? 'Sin resultados para "${vm.query}"' : 'No hay búsquedas activas',
                        style: const TextStyle(fontSize: 16, color: Color(0xFF5F6368)),
                      ),
                      const SizedBox(height: 6),
                      const Text('Reporta un desaparecido tocando el botón +', style: TextStyle(color: Color(0xFF9E9E9E))),
                    ],
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) => _FichaCard(ficha: todos[index], currentUserId: currentUserId),
                    childCount: todos.length,
                  ),
                ),
              ),
      ],
    );
  }
}

// ── Mini tarjeta horizontal para alertas 24h ────────────────────────
class _AlertaMiniCard extends StatelessWidget {
  final ReporteModel ficha;
  final String currentUserId;

  const _AlertaMiniCard({required this.ficha, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final feedVm = context.read<FeedViewModel>();
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => DetalleFichaView(fichaId: ficha.id, currentUserId: currentUserId),
          ),
        );
        if (result == true) feedVm.cargarFichas();
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            if (ficha.fotoUrl != null && ficha.fotoUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                child: Image.network(ficha.fotoUrl!, width: 55, height: 100, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(width: 55)),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 14),
                    const SizedBox(height: 4),
                    Text(ficha.titulo, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                    if (ficha.nombreCategoria != null)
                      Text(ficha.nombreCategoria!, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF5F6368))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta horizontal con distancia opcional (para sección Cerca)
class _FichaCard extends StatelessWidget {
  final ReporteModel ficha;
  final String currentUserId;
  final double? distanciaKm;

  const _FichaCard({required this.ficha, required this.currentUserId, this.distanciaKm});

  @override
  Widget build(BuildContext context) {
    final esCreador = ficha.creadoPor == currentUserId;

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            final feedVm = context.read<FeedViewModel>();
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => DetalleFichaView(fichaId: ficha.id, currentUserId: currentUserId),
              ),
            );
            if (result == true) feedVm.cargarFichas();
          },
          child: SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FichaImage(fotoUrl: ficha.fotoUrl),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                ficha.titulo,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A), height: 1.3),
                              ),
                            ),
                            if (ficha.avatarUsuario != null && ficha.avatarUsuario!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              CircleAvatar(
                                radius: 10,
                                backgroundImage: CachedNetworkImageProvider(ficha.avatarUsuario!),
                                backgroundColor: Colors.transparent,
                              ),
                            ] else if (esCreador) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.person_pin, size: 16, color: AppTheme.primary),
                            ],
                          ],
                        ),
                        Text(
                          ficha.descripcion,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF5F6368), fontSize: 12),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _EstadoChip(estado: ficha.estado),
                            if (distanciaKm != null && distanciaKm! < double.infinity)
                              Row(
                                children: [
                                  const Icon(Icons.near_me, size: 12, color: AppTheme.primary),
                                  const SizedBox(width: 2),
                                  Text(
                                    distanciaKm! < 1 ? '${(distanciaKm! * 1000).round()} m' : '${distanciaKm!.toStringAsFixed(1)} km',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            else
                              const Icon(Icons.chevron_right, size: 18, color: Color(0xFF9E9E9E)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FichaImage extends StatelessWidget {
  final String? fotoUrl;
  const _FichaImage({this.fotoUrl});

  @override
  Widget build(BuildContext context) {
    if (fotoUrl != null && fotoUrl!.isNotEmpty) {
      return SizedBox(
        width: 110,
        child: CachedNetworkImage(
          imageUrl: fotoUrl!,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          memCacheWidth: 220, 
          placeholder: (context, url) => _placeholder(),
          errorWidget: (context, url, error) => _placeholder(),
        ),
      );
    }
    return SizedBox(width: 110, child: _placeholder());
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.primary.withValues(alpha: 0.05),
      child: const Center(child: Icon(Icons.person_search, size: 40, color: AppTheme.primaryLight)),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final String estado;
  const _EstadoChip({required this.estado});

  @override
  Widget build(BuildContext context) {
    final isActive = estado.toLowerCase() == 'activo';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? AppTheme.success : AppTheme.warning),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.success : AppTheme.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            estado.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? AppTheme.success : const Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }
}
