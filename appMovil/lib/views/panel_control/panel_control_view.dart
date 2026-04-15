import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/panel_control_viewmodel.dart';
import '../../models/ficha_model.dart';
import '../../models/perfil_model.dart';

class PanelControlView extends StatefulWidget {
  final String fichaId;

  const PanelControlView({super.key, required this.fichaId});

  @override
  State<PanelControlView> createState() => _PanelControlViewState();
}

class _PanelControlViewState extends State<PanelControlView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PanelControlViewModel>().cargarDatos(widget.fichaId);
    });
  }

  Future<void> _cambiarEstado(BuildContext context, String nuevoEstado) async {
    final vm = context.read<PanelControlViewModel>();
    String? justificacion;

    if (nuevoEstado == 'pausado' || nuevoEstado == 'cerrado') {
      justificacion = await _mostrarDialogoJustificacion(context, nuevoEstado);
      if (justificacion == null) return; // Canceló el diálogo
    } else {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmar Reanudación'),
          content: const Text('¿Deseas volver a poner el operativo en estado Activo? Los voluntarios podrán unirse nuevamente.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
              child: const Text('Reanudar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    final success = await vm.cambiarEstado(widget.fichaId, nuevoEstado, justificacion: justificacion);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operativo cambiado a $nuevoEstado exitosamente.'),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Error al actualizar el estado.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<String?> _mostrarDialogoJustificacion(BuildContext context, String nuevoEstado) {
    final TextEditingController ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        String actionTitle = nuevoEstado == 'cerrado' ? 'Finalizar' : 'Pausar';
        return AlertDialog(
          title: Text('$actionTitle Operativo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Por favor, indica la justificación o razón para $actionTitle esta búsqueda.'),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Escribe la justificación aquí...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('La justificación es obligatoria.')),
                  );
                } else {
                  Navigator.pop(ctx, ctrl.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: nuevoEstado == 'cerrado' ? Colors.red : const Color(0xFFFF9800),
              ),
              child: Text(actionTitle),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PanelControlViewModel>();

    if (vm.isLoading && vm.ficha == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (vm.ficha == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panel de Control')),
        body: const Center(child: Text('Operativo no encontrado.')),
      );
    }

    final ficha = vm.ficha!;
    final bool isActive = ficha.estado == 'activo';
    final bool isPaused = ficha.estado == 'pausado';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrativo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de la Ficha
            Text(
              ficha.titulo,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _EstadoBadge(estado: ficha.estado),
            if (ficha.justificacion != null && ficha.justificacion!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  border: Border.all(color: const Color(0xFFBDBDBD)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Justificación / Resolución:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5F6368))),
                    const SizedBox(height: 4),
                    Text(ficha.justificacion!),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Acciones Rápida',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isActive)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: vm.isLoading ? null : () => _cambiarEstado(context, 'activo'),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Reanudar'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), foregroundColor: Colors.white),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: vm.isLoading ? null : () => _cambiarEstado(context, 'pausado'),
                      icon: const Icon(Icons.pause),
                      label: const Text('Pausar'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800), foregroundColor: Colors.white),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: vm.isLoading || ficha.estado == 'cerrado' ? null : () => _cambiarEstado(context, 'cerrado'),
                    icon: const Icon(Icons.stop),
                    label: const Text('Finalizar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            // Lista de voluntarios
            Row(
              children: [
                const Icon(Icons.people, color: Color(0xFF1B5E20)),
                const SizedBox(width: 8),
                Text(
                  'Voluntarios (${vm.voluntarios.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (vm.voluntarios.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Aún no hay voluntarios en esta búsqueda.', style: TextStyle(color: Color(0xFF757575))),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vm.voluntarios.length,
                itemBuilder: (context, index) {
                  final v = vm.voluntarios[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE8F5E9),
                      child: Text(
                        v.nombreCompleto.isNotEmpty ? v.nombreCompleto[0].toUpperCase() : '?',
                        style: const TextStyle(color: Color(0xFF1B5E20)),
                      ),
                    ),
                    title: Text(v.nombreCompleto.isNotEmpty ? v.nombreCompleto : 'Sin Nombre'),
                    subtitle: Text(v.telefono.isNotEmpty ? v.telefono : 'Sin teléfono'),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;

    if (estado == 'activo') {
      bg = const Color(0xFFE8F5E9);
      border = const Color(0xFF4CAF50);
    } else if (estado == 'pausado') {
      bg = const Color(0xFFFFF3E0);
      border = const Color(0xFFFF9800);
    } else {
      bg = const Color(0xFFFFEBEE);
      border = const Color(0xFFF44336);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(color: border, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
