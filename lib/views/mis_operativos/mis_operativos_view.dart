import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../viewmodels/mis_operativos_viewmodel.dart';
import '../../models/ficha_model.dart';
import '../detalle_ficha/detalle_ficha_view.dart';
import '../widgets/main_drawer.dart';

class MisOperativosView extends StatefulWidget {
  const MisOperativosView({super.key});

  @override
  State<MisOperativosView> createState() => _MisOperativosViewState();
}

class _MisOperativosViewState extends State<MisOperativosView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
      context.read<MisOperativosViewModel>().cargarMisFichas(currentUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MisOperativosViewModel>();
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Operativos'),
      ),
      drawer: const MainDrawer(),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<MisOperativosViewModel>().cargarMisFichas(currentUserId),
        color: const Color(0xFF1B5E20),
        child: _buildBody(vm, currentUserId),
      ),
    );
  }

  Widget _buildBody(MisOperativosViewModel vm, String currentUserId) {
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
            Icon(Icons.folder_off, size: 64, color: Color(0xFF4CAF50)),
            SizedBox(height: 12),
            Text(
              'No tienes operativos creados',
              style: TextStyle(fontSize: 18, color: Color(0xFF5F6368)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: vm.fichas.length,
      itemBuilder: (_, index) =>
          _MiFichaCard(ficha: vm.fichas[index], currentUserId: currentUserId),
    );
  }
}

class _MiFichaCard extends StatelessWidget {
  final FichaModel ficha;
  final String currentUserId;

  const _MiFichaCard({required this.ficha, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final vm = context.read<MisOperativosViewModel>();
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => DetalleFichaView(
                fichaId: ficha.id,
                currentUserId: currentUserId,
              ),
            ),
          );
          if (result == true) {
            vm.cargarMisFichas(currentUserId);
          }
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
                      Text(
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
                      Text(
                        ficha.descripcion,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF5F6368),
                          fontSize: 12,
                        ),
                      ),
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

class _EstadoChip extends StatelessWidget {
  final String estado;
  const _EstadoChip({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (estado.toLowerCase()) {
      case 'activo':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF4CAF50);
        break;
      case 'pausado':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFFF9800);
        break;
      case 'cerrado':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFF44336);
        break;
      default:
        bgColor = const Color(0xFFE0E0E0);
        textColor = const Color(0xFF9E9E9E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            estado.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor.withOpacity(0.8), // Darken slightly
            ),
          ),
        ],
      ),
    );
  }
}
