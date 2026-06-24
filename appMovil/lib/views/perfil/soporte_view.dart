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
            Icon(Icons.warning_amber_rounded, color: AppTheme.accent, size: 28),
            SizedBox(width: 8),
            Text('Eliminar cuenta'),
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
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.darkDark,
            ),
            child: const Text('Sí, eliminar cuenta',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _procesarEliminacion(BuildContext context) async {
    final vm = context.read<AuthViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final success = await vm.eliminarCuenta();

    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu cuenta ha sido eliminada. Lamentamos verte partir.'),
          backgroundColor: Colors.orange,
        ),
      );
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
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primary,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: AppTheme.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppTheme.primary),
        title: const Text('Soporte y legal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Zona de peligro ────────────────────────────────────────────────
          const _SeccionHeader(titulo: 'Zona de peligro'),
          Card(
            elevation: 0,
            color: AppTheme.accent.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.4)),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: const Icon(Icons.person_remove,
                  color: AppTheme.accentDark, size: 28),
              title: const Text(
                'Eliminar cuenta',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.darkDark),
              ),
              subtitle: const Text(
                'Esta acción borrará tus datos permanentemente y no se puede deshacer.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(
                    color: AppTheme.darkDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
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
