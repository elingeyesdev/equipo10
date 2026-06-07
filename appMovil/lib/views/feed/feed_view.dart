import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../../viewmodels/notificaciones_viewmodel.dart';
import '../../models/reporte_model.dart';
import '../detalle_ficha/detalle_ficha_view.dart';
import '../../theme/app_theme.dart';

// ── Icono dinámico según categoría real del sistema ───────────────────
IconData _getIconoPorCategoria(String? categoria) {
  if (categoria == null) return Icons.person_search;
  final cat = categoria.toLowerCase().trim();
  if (cat.contains('mascota') || cat == 'mascotas') return Icons.pets;
  if (cat.contains('veh') || cat == 'vehículos' || cat == 'vehiculos') return Icons.directions_car;
  if (cat.contains('document') || cat == 'documentos') return Icons.badge;
  if (cat.contains('electr') || cat == 'electrónicos' || cat == 'electronicos') return Icons.devices;
  if (cat.contains('persona') || cat == 'personas') return Icons.person_search;
  return Icons.search;
}

/// Formatea una fecha relativa (ej: "hace 2 días", "hace 1 hora")
String _formatRelativo(DateTime? fecha) {
  if (fecha == null) return '';
  final diff = DateTime.now().difference(fecha);
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays < 7) return 'hace ${diff.inDays} día${diff.inDays > 1 ? 's' : ''}';
  if (diff.inDays < 30) {
    final semanas = (diff.inDays / 7).floor();
    return 'hace $semanas sem.';
  }
  final meses = (diff.inDays / 30).floor();
  return 'hace $meses mes${meses > 1 ? 'es' : ''}';
}

// ── Estilo compartido para títulos de sección ─────────────────────────
// Para cambiar tamaño o peso:  modifica fontSize y fontWeight aquí.
// Para tu fuente TTF:
//   1. Copia el .ttf a  assets/fonts/TuFuente.ttf
//   2. En pubspec.yaml > flutter > fonts añade la familia.
//   3. Descomenta la línea fontFamily abajo.
const _kSectionTitleStyle = TextStyle(
  fontSize: 15,           // ← cambia el tamaño aquí
  fontWeight: FontWeight.w600, // ← cambia el peso aquí (w400, w600, w700, bold…)
  color: Color(0xFF111827),
  letterSpacing: -0.1,
  fontFamily: 'Roundman', // ← descomenta para aplicar tu fuente
);

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
      child: _buildFeed(feedVm, currentUserId),
    );
  }

  Widget _buildFeed(FeedViewModel vm, String currentUserId) {
    if (vm.isLoading) return const Center(child: CircularProgressIndicator());

    if (vm.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text('Error al cargar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(vm.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280))),
          ],
        ),
      );
    }

    final alertas = vm.alertas24h;
    final cercanos = vm.reportesCercanos;
    final todos = vm.fichasFiltradas;

    return CustomScrollView(
      cacheExtent: 1200,
      slivers: [
        // ── Barra de búsqueda (vidrio esmerilado al flotar) ────
        SliverPersistentHeader(
          floating: true,
          delegate: _SearchBarDelegate(
            controller: _searchCtrl,
            query: vm.query,
            onChanged: vm.actualizarQuery,
            onClear: () {
              _searchCtrl.clear();
              vm.actualizarQuery('');
            },
            onFilter: () => _mostrarFiltros(context),
          ),
        ),

        // ── Contador de operativos activos ──────────────────────
        if (vm.query.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(
                        color: AppTheme.primaryBase, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text('Se encontraron ${todos.length} operativo${todos.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),

        // ── Alertas últimas 24h ─────────────────────────────────
        if (vm.query.isEmpty && alertas.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: Row(
                    children: [
                      const Text('Últimas 24 horas', style: _kSectionTitleStyle),
                      const SizedBox(width: 6),
                      const Icon(Icons.campaign,
                          color: AppTheme.primaryBase, size: 18),
                      const Spacer(),
                      Text('${alertas.length} nuevos',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 115,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: alertas.take(5).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _AlertaMiniCard(
                        ficha: alertas[i], currentUserId: currentUserId),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

        // ── Carrusel: Cerca de ti ───────────────────────────────
        if (vm.query.isEmpty && cercanos.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: Row(
                    children: [
                      const Text('Cerca de ti', style: _kSectionTitleStyle),
                      const SizedBox(width: 6),
                      const Icon(Icons.near_me,
                          color: AppTheme.primary, size: 18),
                      const Spacer(),
                      const Text('radio 5 km',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 240,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    itemCount: cercanos.take(10).length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 14),
                    itemBuilder: (_, i) => _FichaCercanaCard(
                      ficha: cercanos[i],
                      currentUserId: currentUserId,
                      distanciaKm: vm.distanciaKmDesde(cercanos[i]),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ── Cabecera sección "Todos" ────────────────────────────
        if (vm.query.isEmpty &&
            (alertas.isNotEmpty || cercanos.isNotEmpty))
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 2, 20, 8), // Reducido de 8 a 2
              child: Text('Todos los reportes',
                  style: _kSectionTitleStyle),
            ),
          ),

        // ── Grid principal 2 columnas ───────────────────────────
        if (todos.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off,
                      size: 64, color: AppTheme.primaryLight),
                  const SizedBox(height: 12),
                  Text(
                    (vm.filtroTipo != null || vm.filtroEstado != null || vm.filtroDistanciaRadioKm != null || vm.query.isNotEmpty)
                        ? 'No se encontraron resultados con estos filtros'
                        : 'No hay reportes que encajen con tu búsqueda',
                    style: const TextStyle(
                        fontSize: 16, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                      'Reporta un desaparecido tocando el botón +',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,   // Reducido de 20 a 12
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, index) => _FichaGridCard(
                  ficha: todos[index],
                  currentUserId: currentUserId,
                  distanciaKm: vm.distanciaKmDesde(todos[index]),
                ),
                childCount: todos.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Delegate para SliverPersistentHeader con fondo de vidrio ──────────
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
                      DropdownMenuItem(value: 'desaparicion', child: Text('DesapariciÃ³n de Persona')),
                      DropdownMenuItem(value: 'mascota', child: Text('Mascota Extraviada')),
                      DropdownMenuItem(value: 'objeto', child: Text('Objeto Perdido')),
                    ],
                    onChanged: (val) => setState(() => tipoTemp = val),
                  ),
                  const SizedBox(height: 12),

                  // Filtro de Radio de bÃºsqueda
                  const Text('Radio de cercanÃ­a (km):', style: TextStyle(fontWeight: FontWeight.bold)),
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
  bool shouldRebuild(_SearchBarDelegate old) =>
      old.query != query;

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
                hintText: 'Buscar reportes...',
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
                  borderSide:
                      const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide:
                      const BorderSide(color: AppTheme.border),
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


// ── Navegación con fade suave + delay para ver la animación ───────────
Future<T?> _navigateWithFade<T>(BuildContext context, Widget page) async {
  // Pequeña pausa para que la animación de escala sea visible
  await Future.delayed(const Duration(milliseconds: 100));
  if (!context.mounted) return null;
  return Navigator.of(context).push<T>(
    PageRouteBuilder(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
              parent: animation, curve: Curves.easeInOut),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    ),
  );
}

// ── Mini tarjeta de alertas 24h (AnimatedScale) ───────────────────────
class _AlertaMiniCard extends StatefulWidget {
  final ReporteModel ficha;
  final String currentUserId;
  const _AlertaMiniCard(
      {required this.ficha, required this.currentUserId});

  @override
  State<_AlertaMiniCard> createState() => _AlertaMiniCardState();
}

class _AlertaMiniCardState extends State<_AlertaMiniCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ficha = widget.ficha;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () async {
        final feedVm = context.read<FeedViewModel>();
        final result =
            await _navigateWithFade<bool>(
          context,
          DetalleFichaView(
              fichaId: ficha.id,
              currentUserId: widget.currentUserId),
        );
        if (result == true) feedVm.cargarFichas();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 180,
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppTheme.border),
          ),
          child: Row(
            children: [
              if (ficha.fotoUrl != null &&
                  ficha.fotoUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(13),
                    bottomLeft: Radius.circular(13),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: ficha.fotoUrl!,
                    width: 60,
                    height: 115,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        const SizedBox(width: 60),
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 115,
                  decoration: const BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(13),
                      bottomLeft: Radius.circular(13),
                    ),
                  ),
                  child: Icon(
                      _getIconoPorCategoria(ficha.nombreCategoria),
                      color: AppTheme.primaryBase,
                      size: 28),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Row(children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppTheme.accentDark, size: 12),
                        SizedBox(width: 4),
                        Text('NUEVO',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.accentDark,
                                letterSpacing: 0.5)),
                      ]),
                      const SizedBox(height: 4),
                      Text(ficha.titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              height: 1.2)),
                      if (ficha.nombreCategoria != null) ...[
                        const SizedBox(height: 3),
                        Text(ficha.nombreCategoria!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tarjeta carrusel "Cerca de Ti" (AnimatedScale, sin caja) ──────────
class _FichaCercanaCard extends StatefulWidget {
  final ReporteModel ficha;
  final String currentUserId;
  final double? distanciaKm;
  const _FichaCercanaCard(
      {required this.ficha,
      required this.currentUserId,
      this.distanciaKm});

  @override
  State<_FichaCercanaCard> createState() => _FichaCercanaCardState();
}

class _FichaCercanaCardState extends State<_FichaCercanaCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ficha = widget.ficha;
    final distanciaKm = widget.distanciaKm;
    final esCreador = ficha.creadoPor == widget.currentUserId;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () async {
        final feedVm = context.read<FeedViewModel>();
        final result = await _navigateWithFade<bool>(
          context,
          DetalleFichaView(
              fichaId: ficha.id,
              currentUserId: widget.currentUserId),
        );
        if (result == true) feedVm.cargarFichas();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // ── Tarjeta imagen principal ──
            Expanded(
              flex: 7,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (ficha.fotoUrl != null &&
                        ficha.fotoUrl!.isNotEmpty)
                      Hero(
                        tag: 'foto_cercana_${ficha.id}',
                        child: CachedNetworkImage(
                          imageUrl: ficha.fotoUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 400,
                          placeholder: (_, __) =>
                              _CategoriaPlaceholder(
                                  categoria:
                                      ficha.nombreCategoria),
                          errorWidget: (_, __, ___) =>
                              _CategoriaPlaceholder(
                                  categoria:
                                      ficha.nombreCategoria),
                        ),
                      )
                    else
                      _CategoriaPlaceholder(
                          categoria: ficha.nombreCategoria),

                    // ── Chip de estado (esquina superior izquierda) ──
                    Positioned(
                      top: 7,
                      left: 7,
                      child: _buildEstadoChip(ficha.estado),
                    ),

                      if (distanciaKm != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: _BadgeOscuro(
                            icon: Icons.near_me,
                            label: distanciaKm < 1
                                ? '${(distanciaKm * 1000).round()} m'
                                : '${distanciaKm.toStringAsFixed(1)} km',
                          ),
                        ),

                      // Badge "Tu reporte"
                      if (esCreador)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.darkBase.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person,
                                    size: 10, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Tu reporte',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ficha.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                              letterSpacing: -0.2)),
                      const SizedBox(height: 2),
                      Text(ficha.descripcion,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280))),
                      const SizedBox(height: 2),
                      if (ficha.createdAt != null)
                        Text(_formatRelativo(ficha.createdAt),
                            style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF9E9E9E))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tarjeta de grid tipo Airbnb (AnimatedScale) ───────────────────────
class _FichaGridCard extends StatefulWidget {
  final ReporteModel ficha;
  final String currentUserId;
  final double? distanciaKm;
  const _FichaGridCard(
      {required this.ficha,
      required this.currentUserId,
      this.distanciaKm});

  @override
  State<_FichaGridCard> createState() => _FichaGridCardState();
}

class _FichaGridCardState extends State<_FichaGridCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ficha = widget.ficha;
    final distanciaKm = widget.distanciaKm;
    final esCreador = ficha.creadoPor == widget.currentUserId;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () async {
        setState(() => _pressed = false);
        final feedVm = context.read<FeedViewModel>();
        final result = await _navigateWithFade<bool>(
          context,
          DetalleFichaView(
              fichaId: ficha.id,
              currentUserId: widget.currentUserId),
        );
        if (result == true) feedVm.cargarFichas();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen grande (70%)
            Expanded(
              flex: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (ficha.fotoUrl != null &&
                        ficha.fotoUrl!.isNotEmpty)
                      Hero(
                        tag: 'foto_${ficha.id}',
                        child: CachedNetworkImage(
                          imageUrl: ficha.fotoUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 400,
                          placeholder: (_, __) =>
                              _CategoriaPlaceholder(
                                  categoria: ficha.nombreCategoria),
                          errorWidget: (_, __, ___) =>
                              _CategoriaPlaceholder(
                                  categoria: ficha.nombreCategoria),
                        ),
                      )
                    else
                      _CategoriaPlaceholder(
                          categoria: ficha.nombreCategoria),

                    // ── Chip de estado (esquina superior izquierda) ──
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildEstadoChip(ficha.estado),
                    ),

                    // Badge distancia (esquina superior derecha)
                    if (distanciaKm != null &&
                        distanciaKm < double.infinity)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _BadgeOscuro(
                          label: distanciaKm < 1
                              ? '${(distanciaKm * 1000).round()} m'
                              : '${distanciaKm.toStringAsFixed(1)} km',
                        ),
                      ),

                    // Indicador de creador (esquina inferior izquierda)
                    if (esCreador)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.darkBase.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person,
                                  size: 10, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Tu reporte',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Texto debajo (sin caja)
            const SizedBox(height: 8),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ficha.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                          letterSpacing: -0.2)),
                  const SizedBox(height: 3),
                  Text(ficha.descripcion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF6B7280))),
                  const SizedBox(height: 4),
                  if (ficha.createdAt != null)
                    Text(
                      _formatRelativo(ficha.createdAt),
                      style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF9E9E9E)),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge oscuro reutilizable (distancia, etc.) ───────────────────────
// ── Chip de estado reutilizable ──────────────────────────────────────────
Widget _buildEstadoChip(String estado) {
  final e = estado.toLowerCase();
  final Color dotColor;

  if (e == 'activo') {
    dotColor = AppTheme.primary; // Azul
  } else if (e == 'pausado') {
    dotColor = AppTheme.accent; // Dorado
  } else {
    dotColor = AppTheme.backgroundDark; // Gris
  }

  return Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(
      color: dotColor,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    ),
  );
}

class _BadgeOscuro extends StatelessWidget {

  final String label;
  final IconData? icon;
  const _BadgeOscuro({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── Placeholder con ícono según categoría ────────────────────────────
class _CategoriaPlaceholder extends StatelessWidget {
  final String? categoria;
  const _CategoriaPlaceholder({this.categoria});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primary.withOpacity(0.06),
      child: Center(
        child: Icon(_getIconoPorCategoria(categoria),
            size: 48, color: AppTheme.primaryLight.withOpacity(0.6)),
      ),
    );
  }
}

// ── Estado en texto plano (punto + texto) ─────────────────────────────
class _EstadoTexto extends StatelessWidget {
  final String estado;
  const _EstadoTexto({required this.estado});

  @override
  Widget build(BuildContext context) {
    final isActive = estado.toLowerCase() == 'activo';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF16A34A)
                : const Color(0xFFF59E0B),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          estado,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isActive
                ? const Color(0xFF16A34A)
                : const Color(0xFFB45309),
          ),
        ),
      ],
    );
  }
}
