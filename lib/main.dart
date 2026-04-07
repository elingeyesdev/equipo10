import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/feed_viewmodel.dart';
import 'viewmodels/crear_ficha_viewmodel.dart';
import 'viewmodels/detalle_ficha_viewmodel.dart';
import 'viewmodels/editar_ficha_viewmodel.dart';
import 'views/auth/login_view.dart';
import 'views/feed/feed_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga las variables de entorno desde el archivo .env
  await dotenv.load(fileName: '.env');

  // Inicializa Supabase con las credenciales del .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const EchoesApp());
}

class EchoesApp extends StatelessWidget {
  const EchoesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => FeedViewModel()),
        ChangeNotifierProvider(create: (_) => CrearFichaViewModel()),
        ChangeNotifierProvider(create: (_) => DetalleFichaViewModel()),
        ChangeNotifierProvider(create: (_) => EditarFichaViewModel()),
      ],
      child: MaterialApp(
        title: 'Echoes',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const _AuthGate(),
      ),
    );
  }
}

/// Determina si el usuario ya tiene sesión activa y redirige.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      return const FeedView();
    }
    return const LoginView();
  }
}
