import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../viewmodels/perfil_viewmodel.dart';
import 'tu_cuenta_view.dart';
import 'tu_actividad_view.dart';

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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No se pudo cargar el perfil.'),
            TextButton(onPressed: vm.cargarPerfil, child: const Text('Reintentar'))
          ],
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
            padding: const EdgeInsets.only(bottom: 24, top: 24),
            decoration: const BoxDecoration(
              color: Color(0xFF1B5E20),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
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
                                errorWidget: (context, url, error) => const Icon(Icons.person, size: 50, color: Color(0xFF1B5E20)),
                              )
                            : Text(
                                perfil.nombreCompleto.isNotEmpty ? perfil.nombreCompleto[0].toUpperCase() : 'U',
                                style: const TextStyle(fontSize: 40, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 20, color: Color(0xFF1B5E20)),
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
                title: 'Tu Cuenta',
                subtitle: 'Datos personales, contraseña',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TuCuentaView()));
                },
              ),
              const Divider(height: 1),
              _MenuOption(
                icon: Icons.analytics_outlined,
                title: 'Tu Actividad',
                subtitle: 'Estadísticas y habilidades (skills)',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TuActividadView()));
                },
              ),
              const Divider(height: 1),
              _MenuOption(
                icon: Icons.settings_outlined,
                title: 'Configuración de la App',
                subtitle: 'Notificaciones, permisos, tracking',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Próximamente')));
                },
              ),
              const Divider(height: 1),
              _MenuOption(
                icon: Icons.help_outline,
                title: 'Soporte y Legal',
                subtitle: 'Privacidad, eliminar cuenta',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Próximamente')));
                },
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
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF1B5E20)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
