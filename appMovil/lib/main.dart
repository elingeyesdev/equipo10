import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'services/connectivity_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/feed_viewmodel.dart';
import 'viewmodels/crear_ficha_viewmodel.dart';
import 'viewmodels/detalle_ficha_viewmodel.dart';
import 'viewmodels/editar_ficha_viewmodel.dart';
import 'viewmodels/mis_operativos_viewmodel.dart';
import 'viewmodels/panel_control_viewmodel.dart';
import 'viewmodels/perfil_viewmodel.dart';
import 'viewmodels/notificaciones_viewmodel.dart';
import 'viewmodels/evidencia_viewmodel.dart';
import 'services/auth_service.dart';
import 'views/auth/login_view.dart';
import 'views/auth/onboarding_view.dart';
import 'views/home/home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('No se pudo cargar el archivo .env o está vacío: $e');
  }

  // Cargar sesión previa en memoria (token + userId)
  final apiService = ApiService();
  await apiService.loadSession();

  // Inicializar módulo de notificaciones
  await NotificationService().initialize();

  final prefs = await SharedPreferences.getInstance();
  final hasToken = prefs.getString('auth_token') != null;
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;

  runApp(EchoesApp(hasToken: hasToken, onboardingDone: onboardingDone));
}

class EchoesApp extends StatelessWidget {
  final bool hasToken;
  final bool onboardingDone;
  const EchoesApp({super.key, required this.hasToken, required this.onboardingDone});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // E9.1 — Módulo Offline: servicio de conectividad disponible globalmente
        ChangeNotifierProvider<ConnectivityService>(
          create: (_) => ConnectivityService(),
        ),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => FeedViewModel()),
        ChangeNotifierProvider(create: (_) => CrearFichaViewModel()),
        ChangeNotifierProvider(create: (_) => DetalleFichaViewModel()),
        ChangeNotifierProvider(create: (_) => EditarFichaViewModel()),
        ChangeNotifierProvider(create: (_) => MisOperativosViewModel()),
        ChangeNotifierProvider(create: (_) => PanelControlViewModel()),
        ChangeNotifierProvider(create: (_) => PerfilViewModel(AuthService())),
        ChangeNotifierProvider(create: (_) => NotificacionesViewModel()),
        ChangeNotifierProvider(create: (_) => EvidenciaViewModel()),
      ],
      child: MaterialApp(
        title: 'Echoes',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: _AuthGate(hasToken: hasToken, onboardingDone: onboardingDone),
      ),
    );
  }
}

/// Determina si el usuario ya tiene sesión activa y redirige.
/// Si el onboarding no se ha visto, lo muestra primero.
class _AuthGate extends StatelessWidget {
  final bool hasToken;
  final bool onboardingDone;
  const _AuthGate({required this.hasToken, required this.onboardingDone});

  @override
  Widget build(BuildContext context) {
    if (hasToken) return const HomeView();
    if (!onboardingDone) return const OnboardingView();
    return const LoginView();
  }
}
