import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/perfil_viewmodel.dart';
import '../../theme/app_theme.dart';

class TuActividadView extends StatefulWidget {
  const TuActividadView({super.key});

  @override
  State<TuActividadView> createState() => _TuActividadViewState();
}

class _TuActividadViewState extends State<TuActividadView> {
  final List<String> _opcionesHabilidades = [
    'Primeros Auxilios',
    'Rescatista',
    'Manejo de Drones',
    'Veterinario',
    'Conocimiento del Terreno',
    'Buceo',
    'Transporte/Vehículo 4x4',
    'Otro'
  ];

  Future<void> _mostrarDialogoAgregarHabilidad(BuildContext context) async {
    final vm = context.read<PerfilViewModel>();
    String opcionSeleccionada = _opcionesHabilidades.first;
    final TextEditingController otroCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return AlertDialog(
            title: const Text('Agregar habilidad'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selecciona una habilidad especial:'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: opcionSeleccionada,
                  isExpanded: true,
                  items: _opcionesHabilidades.map((String val) {
                    return DropdownMenuItem<String>(
                      value: val,
                      child: Text(val),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setStateModal(() {
                        opcionSeleccionada = val;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (opcionSeleccionada == 'Otro') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: otroCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Especifica la habilidad',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                ]
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  String nuevaHabilidad = opcionSeleccionada;
                  if (opcionSeleccionada == 'Otro') {
                    nuevaHabilidad = otroCtrl.text.trim();
                    if (nuevaHabilidad.isEmpty) return;
                  }

                  Navigator.pop(ctx);
                  final success = await vm.agregarHabilidad(nuevaHabilidad);

                  if (!mounted) return;
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Habilidad agregada.'),
                          backgroundColor: AppTheme.primary),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              vm.errorMessage ?? 'Error al agregar habilidad.'),
                          backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PerfilViewModel>();
    final perfil = vm.perfil;

    if (perfil == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Tu actividad'),
          centerTitle: false,
          titleSpacing: 0,
        ),
        body: const Center(child: Text('No se pudo cargar la actividad.')),
      );
    }

    final stats = perfil.estadisticas;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Tu actividad'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas de impacto',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _StatCard(
                  icon: Icons.search,
                  title: 'Búsquedas',
                  value: '${stats['operativos_participados'] ?? 0}',
                  color: AppTheme.primary,
                ),
                _StatCard(
                  icon: Icons.campaign,
                  title: 'Reportes creados',
                  value: '${stats['reportes_creados'] ?? 0}',
                  color: AppTheme.primary,
                ),
                _StatCard(
                  icon: Icons.emoji_events,
                  title: 'Rescates (Oro)',
                  value: '${perfil.rescatesOro}',
                  color: const Color(0xFFFFB300),
                ),
                _StatCard(
                  icon: Icons.verified,
                  title: 'Evidencias',
                  value: '${perfil.evidenciasPlataBronce}',
                  color: const Color(0xFFB0BEC5),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Habilidades (skills)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => _mostrarDialogoAgregarHabilidad(context),
                  icon: const Icon(Icons.add_circle, color: AppTheme.primary),
                  tooltip: 'Añadir habilidad',
                )
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Añade habilidades para que los líderes de búsqueda sepan cómo puedes ayudar mejor en campo.',
              style: TextStyle(color: Color(0xFF5F6368)),
            ),
            const SizedBox(height: 16),
            if (perfil.habilidades.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: const Text(
                  'Aún no has añadido habilidades.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF9E9E9E)),
                ),
              )
            else
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: perfil.habilidades.map((hab) {
                  return Chip(
                    label: Text(hab),
                    backgroundColor: AppTheme.darkBase,
                    labelStyle: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                    deleteIconColor: Colors.white70,
                    onDeleted: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Eliminar habilidad'),
                          content: Text('¿Seguro que deseas eliminar "$hab"?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Eliminar',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await vm.eliminarHabilidad(hab);
                      }
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5F6368),
            ),
          )
        ],
      ),
    );
  }
}
