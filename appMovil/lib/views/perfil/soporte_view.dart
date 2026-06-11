import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../auth/login_view.dart';

class SoporteView extends StatelessWidget {
  const SoporteView({super.key});

  void _onEliminarCuenta(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 28),
            SizedBox(width: 8),
            Text('Eliminar cuenta', style: TextStyle(color: AppTheme.danger)),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar tu cuenta?\n\n'
          'Esta acción no se puede deshacer. Todos tus datos personales, '
          'historial de operativos y puntos de ayuda serán borrados '
          'permanentemente del sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _procesarEliminacion(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sí, eliminar cuenta'),
          ),
        ],
      ),
    );
  }

  Future<void> _procesarEliminacion(BuildContext context) async {
    final vm = context.read<AuthViewModel>();

    // Mostrar un dialog de carga de barrera
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await vm.eliminarCuenta();

    if (!context.mounted) return;

    // Quitar el dialog de carga
    Navigator.of(context).pop();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Tu cuenta ha sido eliminada. Lamentamos verte partir.'),
          backgroundColor: Colors.orange,
        ),
      );
      // Redirigir a login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginView()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Error al eliminar la cuenta.'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Soporte y legal',
            style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Legal ──────────────────────────────────────────────────────────
          const _SeccionHeader(titulo: 'Legal y privacidad'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.policy_outlined,
                      color: AppTheme.primary),
                  title: const Text('Política de privacidad',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Abriendo enlace externo...')));
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined,
                      color: AppTheme.primary),
                  title: const Text('Términos de servicio',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Abriendo enlace externo...')));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Contacto ───────────────────────────────────────────────────────
          const _SeccionHeader(titulo: 'Ayuda y contacto'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading:
                  const Icon(Icons.email_outlined, color: AppTheme.primary),
              title: const Text('Contactar a soporte',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('soporte@echoesapp.com',
                  style: TextStyle(fontSize: 12)),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Abriendo cliente de correo...')));
              },
            ),
          ),
          const SizedBox(height: 32),

          // ── Zona Peligro ───────────────────────────────────────────────────
          const _SeccionHeader(titulo: 'Zona de peligro'),
          Card(
            elevation: 0,
            color: AppTheme.danger.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.danger.withOpacity(0.3)),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_remove, color: AppTheme.danger),
              ),
              title: const Text('Eliminar cuenta',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppTheme.danger)),
              subtitle: const Text(
                  'Esta acción borrará tus datos permanentemente y no se puede deshacer.',
                  style: TextStyle(fontSize: 12, color: AppTheme.danger)),
              onTap: () => _onEliminarCuenta(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionHeader extends StatelessWidget {
  final String titulo;
  const _SeccionHeader({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
