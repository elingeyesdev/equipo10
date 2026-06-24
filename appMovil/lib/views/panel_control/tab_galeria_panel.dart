import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/panel_control_viewmodel.dart';
import '../../viewmodels/evidencia_viewmodel.dart';
import '../widgets/full_screen_image_view.dart';

class TabGaleriaPanel extends StatelessWidget {
  const TabGaleriaPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PanelControlViewModel>();
    final evVm = context.watch<EvidenciaViewModel>();

    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<Map<String, dynamic>> todasLasImagenes = [];

    // 1. Foto principal del reporte
    final fotoPrincipal = vm.ficha?.fotoUrl;
    if (fotoPrincipal != null && fotoPrincipal.isNotEmpty) {
      todasLasImagenes.add({
        'url': fotoPrincipal,
        'tipo': 'original',
        'autor': 'Reporte original',
      });
    }

    // 2. Evidencias aprobadas con foto
    for (final e in evVm.evidencias) {
      if (e.estado == 'approved' && e.fotoUrl != null && e.fotoUrl!.isNotEmpty) {
        todasLasImagenes.add({
          'url': e.fotoUrl!,
          'tipo': 'evidencia',
          'autor': e.nombreUsuario ?? 'Voluntario',
          'esClave': e.esClave,
        });
      }
    }

    // 3. Complementar con las del API (si hay extras que no estén ya)
    final urlsLocales = todasLasImagenes.map((m) => m['url']).toSet();
    for (final img in vm.galeria) {
      if (!urlsLocales.contains(img['url'])) {
        todasLasImagenes.add(img);
      }
    }

    if (todasLasImagenes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay imagenes en la galeria aún.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: todasLasImagenes.length,
      itemBuilder: (context, index) {
        final img = todasLasImagenes[index];
        return GestureDetector(
          onTap: () {
            final esOriginal = img['tipo'] == 'original';
            final esClave = img['esClave'] == true;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullScreenImageView(
                  imageUrl: img['url'],
                  title: esOriginal
                      ? 'Imagen del reporte'
                      : esClave
                          ? '★ Evidencia clave'
                          : 'Evidencia aprobada',
                  subtitle: img['autor'] ?? '',
                ),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: img['url'],
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, color: Colors.grey)),
                  placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator())),
                ),
              ),
              // Ícono de foto para la imagen original del reporte
              if (img['tipo'] == 'original')
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 11),
                  ),
                ),
              // Estrella para evidencias clave
              if (img['esClave'] == true)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.star,
                        color: Color(0xFFE9C978), size: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
