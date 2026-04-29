/// Tipos de notificación disponibles en la app.
///
/// Para agregar un nuevo tipo en el futuro, solo agrega un valor aquí
/// y maneja el caso en [NotificationService.show()].
enum NotificationType {
  /// Confirmación cuando el usuario se une exitosamente a una búsqueda.
  joinSearchConfirmation,

  // ── Tipos futuros (descomenta cuando los implementes) ──────────────
  // searchClosed,      // La búsqueda a la que perteneces fue cerrada
  // searchPaused,      // La búsqueda fue pausada por el creador
  // volunteerJoined,   // Alguien se unió a tu operativo (admin)
  // newSearchNearby,   // Nueva búsqueda creada cerca de tu ubicación
}

/// Representa una notificación que se mostrará al usuario.
///
/// Úsala junto con [NotificationService] para mostrar notificaciones
/// nativas en el dispositivo.
///
/// Ejemplo de uso:
/// ```dart
/// NotificationService().show(
///   AppNotification(
///     type: NotificationType.joinSearchConfirmation,
///     title: '¡Excelente!',
///     body: 'Te has unido a la búsqueda "Operativo Río Verde".',
///     payload: {'fichaId': '123'},
///   ),
/// );
/// ```
class AppNotification {
  /// Tipo de notificación. Determina el canal y el icono.
  final NotificationType type;

  /// Título de la notificación (línea principal en negrita).
  final String title;

  /// Cuerpo del mensaje de la notificación.
  final String body;

  /// Datos adicionales opcionales (ej: fichaId para navegar al tocar).
  /// Útil para el futuro cuando se implemente navegación al tocar la notif.
  final Map<String, dynamic>? payload;

  const AppNotification({
    required this.type,
    required this.title,
    required this.body,
    this.payload,
  });
}
