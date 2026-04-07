import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../../models/ficha_model.dart';
import '../auth/login_view.dart';
import '../crear_ficha/crear_ficha_view.dart';
import '../detalle_ficha/detalle_ficha_view.dart';

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedViewModel>().cargarFichas();
    });
  }

  Future<void> _onLogout() async {
    final vm = context.read<AuthViewModel>();
    await vm.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedVm = context.watch<FeedViewModel>();
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Echoes — Operativos Activos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _onLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<FeedViewModel>().cargarFichas(),
        color: const Color(0xFF1B5E20),
        child: _buildBody(feedVm, currentUserId),
      ),
      floatingActionButton: FloatingActionButton.extended(
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
      ),
    );
  }

  Widget _buildBody(FeedViewModel vm, String currentUserId) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Error al cargar fichas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              vm.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF5F6368)),
            ),
          ],
        ),
      );
    }

    if (vm.fichas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Color(0xFF4CAF50)),
            SizedBox(height: 12),
            Text(
              'No hay operativos activos',
              style: TextStyle(fontSize: 18, color: Color(0xFF5F6368)),
            ),
            SizedBox(height: 6),
            Text(
              'Reporta un desaparecido tocando el botón +',
              style: TextStyle(color: Color(0xFF9E9E9E)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: vm.fichas.length,
      itemBuilder: (_, index) =>
          _FichaCard(ficha: vm.fichas[index], currentUserId: currentUserId),
    );
  }
}

/// Tarjeta horizontal: imagen al lado izquierdo + contenido a la derecha.
class _FichaCard extends StatelessWidget {
  final FichaModel ficha;
  final String currentUserId;

  const _FichaCard({required this.ficha, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final esCreador = ficha.creadoPor == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          // Guarda referencia antes del gap async
          final feedVm = context.read<FeedViewModel>();
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => DetalleFichaView(
                fichaId: ficha.id,
                currentUserId: currentUserId,
              ),
            ),
          );
          // Si se eliminó o cerró la ficha, recarga el feed inmediatamente
          if (result == true) {
            feedVm.cargarFichas();
          }
        },
        child: SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // — Imagen a la izquierda —
              _FichaImage(fotoUrl: ficha.fotoUrl),

              // — Contenido a la derecha —
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Título + badge de creador
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              ficha.titulo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (esCreador) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.person_pin,
                                size: 16, color: Color(0xFF1B5E20)),
                          ],
                        ],
                      ),

                      // Descripción
                      Text(
                        ficha.descripcion,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF5F6368),
                          fontSize: 12,
                        ),
                      ),

                      // Fila inferior: estado + flecha
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _EstadoChip(estado: ficha.estado),
                          const Icon(Icons.chevron_right,
                              size: 18, color: Color(0xFF9E9E9E)),
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
    );
  }
}

/// Imagen cuadrada estándar a la izquierda de la tarjeta.
class _FichaImage extends StatelessWidget {
  final String? fotoUrl;

  const _FichaImage({this.fotoUrl});

  @override
  Widget build(BuildContext context) {
    if (fotoUrl != null && fotoUrl!.isNotEmpty) {
      return SizedBox(
        width: 110,
        child: Image.network(
          fotoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return SizedBox(width: 110, child: _placeholder());
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE8F5E9),
      child: const Center(
        child: Icon(Icons.person_search, size: 40, color: Color(0xFF4CAF50)),
      ),
    );
  }
}

/// Chip pequeño con color según el estado.
class _EstadoChip extends StatelessWidget {
  final String estado;

  const _EstadoChip({required this.estado});

  @override
  Widget build(BuildContext context) {
    final isActive = estado.toLowerCase() == 'activo';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFFF9800),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            estado.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive
                  ? const Color(0xFF1B5E20)
                  : const Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }
}
