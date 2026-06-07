import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../viewmodels/perfil_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'tu_cuenta_view.dart';
import 'tu_actividad_view.dart';
import '../about/about_view.dart';
import '../auth/login_view.dart';
import '../../theme/app_theme.dart';
import 'configuracion_view.dart';
import 'soporte_view.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PerfilViewModel>().cargarPerfil();
    });
  }

  void _onLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres salir?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthViewModel>().logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginView()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 42),
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (mounted) {
        await context.read<PerfilViewModel>().actualizarAvatar(image.path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PerfilViewModel>();

    if (vm.isLoading && vm.perfil == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.perfil == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Configuración'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.danger),
              onPressed: _onLogout,
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No se pudo cargar el perfil.'),
              const SizedBox(height: 8),
              TextButton(onPressed: vm.cargarPerfil, child: const Text('Reintentar')),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                onPressed: _onLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final perfil = vm.perfil!;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
          // CABECERA
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 32,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary,
                  AppTheme.primaryBase,
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Título de Configuración
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Configuración',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: perfil.avatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: perfil.avatarUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => const Icon(Icons.person, size: 50, color: AppTheme.primary),
                              )
                            : Text(
                                perfil.nombreCompleto.isNotEmpty ? perfil.nombreCompleto[0].toUpperCase() : 'U',
                                style: const TextStyle(fontSize: 40, color: AppTheme.primary, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit, size: 18, color: AppTheme.darkDark),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  perfil.nombreCompleto.isNotEmpty ? perfil.nombreCompleto : 'Voluntario Sin Nombre',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (perfil.email.isNotEmpty)
                  Text(
                    perfil.email,
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                  ),
              ],
            ),
          ),
          
          // LISTA DE OPCIONES
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _MenuOption(
                icon: Icons.person_outline,
                title: 'Tu cuenta',
                subtitle: 'Datos personales, contraseña',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TuCuentaView()));
                },
              ),
              const Divider(height: 1),
              _MenuOption(
                icon: Icons.analytics_outlined,
                title: 'Tu actividad',
                subtitle: 'Estadísticas y habilidades (skills)',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TuActividadView()));
                },
              ),
              const Divider(height: 1),
              _MenuOption(
                icon: Icons.settings_outlined,
                title: 'Configuración de la app',
                subtitle: 'Notificaciones, permisos, tracking',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfiguracionView()));
                },
              ),
              const Divider(height: 1),
              _MenuOption(
                icon: Icons.help_outline,
                title: 'Soporte y legal',
                subtitle: 'Privacidad, eliminar cuenta',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SoporteView()));
                },
              ),
              const Divider(height: 1),
              _MenuOption(
                icon: Icons.info_outline,
                title: 'Sobre Echoes',
                subtitle: 'Misión, equipo y versión',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutView()));
                },
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout, color: AppTheme.danger),
                  ),
                  title: const Text('Cerrar sesión',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.danger)),
                  subtitle: const Text('Salir de tu cuenta', style: TextStyle(fontSize: 13)),
                  onTap: _onLogout,
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuOption({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
