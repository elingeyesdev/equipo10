import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../widgets/nombre_con_insignia.dart';

class PerfilPublicoView extends StatefulWidget {
  final String usuarioId;

  const PerfilPublicoView({super.key, required this.usuarioId});

  @override
  State<PerfilPublicoView> createState() => _PerfilPublicoViewState();
}

class _PerfilPublicoViewState extends State<PerfilPublicoView> {
  bool _isLoading = true;
  Map<String, dynamic>? _perfil;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final response = await ApiService().client.get('/auth/perfil/${widget.usuarioId}');
      if (response.statusCode == 200 && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _perfil = response.data['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Fondo muy claro y moderno
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _perfil == null
              ? const Center(child: Text('Error al cargar perfil.'))
              : _buildPremiumProfile(),
    );
  }

  Widget _buildPremiumProfile() {
    final avatarUrl = _perfil!['avatar_url'] as String?;
    final nombre = _perfil!['nombre'] as String? ?? 'Usuario';
    final rescatesOro = _perfil!['rescates_oro'] ?? 0;
    final pistas = _perfil!['evidencias_plata_bronce'] ?? 0;
    final habilidades = _perfil!['habilidades'] as List<dynamic>? ?? [];

    Color mainColor = AppTheme.primary;
    if (rescatesOro > 0) {
      mainColor = const Color(0xFFFFB300); // Gold
    } else if (pistas >= 6) {
      mainColor = const Color(0xFFB0BEC5); // Silver
    } else if (pistas >= 1) {
      mainColor = const Color(0xFF8D6E63); // Bronze
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Banner Superior Header
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [mainColor.withValues(alpha: 0.8), mainColor.withValues(alpha: 1.0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: mainColor.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 5,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? Icon(Icons.person, size: 50, color: mainColor)
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),

          // Información Principal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                NombreConInsignia(
                  nombre: nombre,
                  oro: rescatesOro,
                  plataBronce: pistas,
                  baseStyle: const TextStyle(
                    fontSize: 26, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: -0.5,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  rescatesOro > 0 ? 'Héroe Élite' : (pistas > 0 ? 'Voluntario Activo' : 'Explorador Comunitario'),
                  style: TextStyle(
                    fontSize: 16,
                    color: mainColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Tarjetas de Logros (Glassmorphism inspired)
                _buildAchievementCards(rescatesOro, pistas, mainColor),
                
                const SizedBox(height: 32),
                
                // Habilidades
                _buildHabilidades(habilidades, mainColor),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCards(int oro, int pistas, Color mainColor) {
    return Column(
      children: [
        _buildPremiumCard(
          title: 'Rescates Exitosos',
          subtitle: 'Mascotas devueltas a su hogar',
          value: oro.toString(),
          icon: Icons.emoji_events_rounded,
          color: const Color(0xFFFFB300),
          gradient: const [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
        ),
        const SizedBox(height: 16),
        _buildPremiumCard(
          title: 'Evidencias y Tracking',
          subtitle: 'Puntos de búsqueda verificados',
          value: pistas.toString(),
          icon: Icons.verified_rounded,
          color: pistas >= 6 ? const Color(0xFFB0BEC5) : const Color(0xFF8D6E63),
          gradient: pistas >= 6 
            ? const [Color(0xFFF5F7FA), Color(0xFFCFD9DF)]
            : const [Color(0xFFEFEBE9), Color(0xFFD7CCC8)],
        ),
      ],
    );
  }

  Widget _buildPremiumCard({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF374151),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabilidades(List<dynamic> habilidades, Color mainColor) {
    if (habilidades.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HABILIDADES Y EXPERIENCIA',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: habilidades.map((hab) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: mainColor.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              hab.toString(),
              style: TextStyle(
                color: mainColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}
