import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/notificaciones_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../detalle_ficha/detalle_ficha_view.dart';
import '../panel_control/revision_evidencias_view.dart';


class NotificacionesView extends StatefulWidget {
  const NotificacionesView({super.key});

  @override
  State<NotificacionesView> createState() => _NotificacionesViewState();
}

class _NotificacionesViewState extends State<NotificacionesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificacionesViewModel>().cargarNotificaciones();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notificaciones', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Consumer<NotificacionesViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading && vm.notificaciones.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.errorMessage != null && vm.notificaciones.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(vm.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => vm.cargarNotificaciones(),
                      child: const Text('Reintentar'),
                    )
                  ],
                ),
              ),
            );
          }

          if (vm.notificaciones.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes notificaciones',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: vm.cargarNotificaciones,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: vm.notificaciones.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notif = vm.notificaciones[index];
                final bool isUnread = !notif.leida;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isUnread ? AppTheme.primary.withValues(alpha: 0.5) : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  color: isUnread ? AppTheme.primary.withValues(alpha: 0.05) : Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isUnread ? AppTheme.primary : Colors.grey.shade200,
                      child: Icon(
                        _getIconForType(notif.tipo),
                        color: isUnread ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                    title: Text(
                      notif.titulo,
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notif.mensaje,
                            style: TextStyle(
                              color: isUnread ? Colors.black87 : Colors.black54,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(notif.createdAt),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      if (isUnread) {
                        vm.marcarComoLeida(notif.id);
                      }
                      final data = notif.datosJson;
                      if (data != null && data.containsKey('reporte_id')) {
                        final String reporteId = data['reporte_id'].toString();
                        final authVm = context.read<AuthViewModel>();
                        final String userId = authVm.currentUserId ?? '';
                        
                        if (notif.tipo == 'respuesta_reporte') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RevisionEvidenciasView(
                                reporteId: reporteId,
                                reporteTitulo: 'Revisión de Evidencias',
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetalleFichaView(
                                fichaId: reporteId,
                                currentUserId: userId,
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(String tipo) {
    switch (tipo) {
      case 'respuesta_reporte':
        return Icons.camera_enhance_outlined;
      case 'actualizacion_reporte':
        return Icons.edit_note;
      case 'alerta_masiva':
        return Icons.warning_amber_rounded;
      case 'nuevo_reporte':
        return Icons.add_alert;
      case 'reporte_cerrado':
        return Icons.check_circle_outline;
      case 'voluntario_unido':
        return Icons.person_add_alt_1;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} minutos';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} horas';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
