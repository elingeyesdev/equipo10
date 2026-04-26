import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/perfil_viewmodel.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  // Opciones predefinidas de habilidades
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PerfilViewModel>().cargarPerfil();
    });
  }

  Future<void> _mostrarDialogoAgregarHabilidad(BuildContext context) async {
    final vm = context.read<PerfilViewModel>();
    String opcionSeleccionada = _opcionesHabilidades.first;
    final TextEditingController otroCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return AlertDialog(
            title: const Text('Agregar Habilidad'),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (opcionSeleccionada == 'Otro') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: otroCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Especifica la habilidad',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                ]
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  String nuevaHabilidad = opcionSeleccionada;
                  if (opcionSeleccionada == 'Otro') {
                    nuevaHabilidad = otroCtrl.text.trim();
                    if (nuevaHabilidad.isEmpty) return; // Validación básica
                  }
                  
                  Navigator.pop(ctx);
                  final success = await vm.agregarHabilidad(nuevaHabilidad);
                  
                  if (!mounted) return;
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Habilidad agregada.'), backgroundColor: Color(0xFF1B5E20)),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(vm.errorMessage ?? 'Error al agregar habilidad.'), backgroundColor: Colors.red),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
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

    if (vm.isLoading && vm.perfil == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Perfil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (vm.perfil == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Perfil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No se pudo cargar el perfil.'),
              TextButton(onPressed: vm.cargarPerfil, child: const Text('Reintentar'))
            ],
          ),
        ),
      );
    }

    final perfil = vm.perfil!;
    final stats = perfil.estadisticas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Avatar y Datos
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFE8F5E9),
                    backgroundImage: perfil.avatarUrl != null ? NetworkImage(perfil.avatarUrl!) : null,
                    child: perfil.avatarUrl == null 
                        ? Text(
                            perfil.nombreCompleto.isNotEmpty ? perfil.nombreCompleto[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 40, color: Color(0xFF1B5E20)),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    perfil.nombreCompleto.isNotEmpty ? perfil.nombreCompleto : 'Voluntario Sin Nombre',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (perfil.email.isNotEmpty)
                    Text(
                      perfil.email,
                      style: const TextStyle(fontSize: 16, color: Color(0xFF757575)),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: Color(0xFF1976D2), size: 16),
                        SizedBox(width: 4),
                        Text('Usuario Activo', style: TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Dashboard de Estadísticas
            const Text(
              'Estadísticas de Impacto',
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
                  color: Colors.blue,
                ),
                _StatCard(
                  icon: Icons.campaign,
                  title: 'Reportes Creados',
                  value: '${stats['reportes_creados'] ?? 0}',
                  color: Colors.orange,
                ),
                _StatCard(
                  icon: Icons.check_circle,
                  title: 'Casos Resueltos',
                  value: '${stats['casos_exitosos'] ?? 0}',
                  color: Colors.green,
                ),
                _StatCard(
                  icon: Icons.stars,
                  title: 'Puntos',
                  value: '${stats['puntos_ayuda'] ?? 0}',
                  color: Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Habilidades Especiales
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Habilidades (Skills)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => _mostrarDialogoAgregarHabilidad(context),
                  icon: const Icon(Icons.add_circle, color: Color(0xFF1B5E20)),
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
                    backgroundColor: const Color(0xFFE8F5E9),
                    labelStyle: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
                    deleteIconColor: const Color(0xFF1B5E20),
                    onDeleted: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Eliminar habilidad'),
                          content: Text('¿Seguro que deseas eliminar "$hab"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true), 
                              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
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
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: color.withOpacity(0.2)),
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
