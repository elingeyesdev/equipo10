import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/feed_viewmodel.dart';
import 'viewmodels/crear_ficha_viewmodel.dart';
import 'viewmodels/detalle_ficha_viewmodel.dart';
import 'viewmodels/editar_ficha_viewmodel.dart';
import 'viewmodels/mis_operativos_viewmodel.dart';
import 'viewmodels/panel_control_viewmodel.dart';
import 'views/auth/login_view.dart';
import 'views/feed/feed_view.dart';

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

  final prefs = await SharedPreferences.getInstance();
  final hasToken = prefs.getString('auth_token') != null;

  runApp(EchoesApp(hasToken: hasToken));
}

class EchoesApp extends StatelessWidget {
  final bool hasToken;
  const EchoesApp({super.key, required this.hasToken});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => FeedViewModel()),
        ChangeNotifierProvider(create: (_) => CrearFichaViewModel()),
        ChangeNotifierProvider(create: (_) => DetalleFichaViewModel()),
        ChangeNotifierProvider(create: (_) => EditarFichaViewModel()),
        ChangeNotifierProvider(create: (_) => MisOperativosViewModel()),
        ChangeNotifierProvider(create: (_) => PanelControlViewModel()),
      ],
      child: MaterialApp(
        title: 'Echoes',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: _AuthGate(hasToken: hasToken),
      ),
    );
  }
}

/// Determina si el usuario ya tiene sesión activa y redirige.
class _AuthGate extends StatelessWidget {
  final bool hasToken;
  const _AuthGate({required this.hasToken});

  @override
  Widget build(BuildContext context) {
    if (hasToken) {
      return const FeedView();
    }
    return const LoginView();
  }
}
