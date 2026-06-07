import re

with open('lib/views/detalle_ficha/detalle_ficha_view.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Extract the body part
# Finding body: SingleChildScrollView(
start_index = code.find('          body: SingleChildScrollView(')
if start_index == -1:
    print("Could not find body!")
    exit(1)

# we need to find the matching closing brace for this body.
# Wait, it's easier to use a regex to replace the exact block.
# Actually, the block we want to replace starts with:
#           body: SingleChildScrollView(
# and ends right before:
#         ),
#       ),
#     );
#   }
# 
#   Widget _buildActionArea(
pattern = r'          body: SingleChildScrollView\(.*?\n          \),\n        \),\n      \),\n    \);\n  \}'

match = re.search(pattern, code, re.DOTALL)
if not match:
    print("Could not find full block!")
    exit(1)

replacement = """          body: DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroImage(fotoUrl: ficha.fotoUrl, categoria: ficha.nombreCategoria),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _EstadoBadge(estado: ficha.estado),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3E5F5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFF8E24AA)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.group, size: 14, color: Color(0xFF8E24AA)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${vm.voluntariosCount} Voluntarios',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF8E24AA),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (esCreador)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppTheme.primary),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (ficha.avatarUsuario != null && ficha.avatarUsuario!.isNotEmpty) ...[
                                            CircleAvatar(
                                              radius: 8,
                                              backgroundImage: CachedNetworkImageProvider(ficha.avatarUsuario!),
                                              backgroundColor: Colors.transparent,
                                            ),
                                          ] else
                                            const Icon(Icons.person, size: 14, color: AppTheme.primary),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'Tú creaste esta búsqueda',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                ficha.titulo,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 3,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.info,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildActionArea(vm, esCreador, esBloqueado, estadoText),
                            ]
                          )
                        )
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      const TabBar(
                        labelColor: AppTheme.primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppTheme.primary,
                        indicatorWeight: 3,
                        tabs: [
                          Tab(text: "Detalles"),
                          Tab(text: "Evidencias"),
                          Tab(text: "Comentarios"),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  // Tab 1: Detalles
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Descripción del caso',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5F6368),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ficha.descripcion,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1A1A1A),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _InfoSection(ficha: ficha),
                        const SizedBox(height: 20),
                        if (ficha.latitud != null && ficha.longitud != null)
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MapaOperativoView(
                                    ficha: ficha,
                                    esCreador: esCreador,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              height: 160,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.info, width: 1.5),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: Stack(
                                children: [
                                  IgnorePointer(
                                    child: Consumer<EvidenciaViewModel>(
                                      builder: (context, evidenciaVm, _) {
                                        return FlutterMap(
                                          options: MapOptions(
                                            initialCenter: LatLng(ficha.latitud!, ficha.longitud!),
                                            initialZoom: 15.0,
                                            interactionOptions: const InteractionOptions(
                                                flags: InteractiveFlag.none),
                                          ),
                                          children: [
                                            TileLayer(
                                              urlTemplate:
                                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                              userAgentPackageName: 'com.amigate.echoes',
                                            ),
                                            MarkerLayer(
                                              markers: [
                                                Marker(
                                                  point: LatLng(ficha.latitud!, ficha.longitud!),
                                                  width: 40,
                                                  height: 40,
                                                  child: const Icon(Icons.location_on,
                                                      color: Colors.red, size: 40),
                                                ),
                                                ...evidenciaVm.evidencias.where((e) => (esCreador || e.estado == 'approved') && e.lat != null && e.lng != null).map((evidencia) {
                                                  return Marker(
                                                    point: LatLng(evidencia.lat!, evidencia.lng!),
                                                    width: 30,
                                                    height: 30,
                                                    child: const Icon(Icons.camera_alt, color: Colors.blueAccent, size: 24),
                                                  );
                                                }),
                                              ],
                                            ),
                                          ],
                                        );
                                      }
                                    ),
                                  ),
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.1),
                                  ),
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.map, color: AppTheme.info),
                                          SizedBox(width: 8),
                                          Text(
                                            'Ver Mapa de Cuadrantes',
                                            style: TextStyle(
                                              color: AppTheme.primaryLight,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Tab 2: Evidencias
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: EvidenciasSection(
                      reporteId: widget.fichaId,
                      usuarioId: widget.currentUserId,
                      puedePublicar: ficha.estado.toLowerCase() == 'activo',
                      esCreador: esCreador,
                    ),
                  ),
                  // Tab 3: Comentarios
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildComentariosSection(vm),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }"""

new_code = code[:match.start()] + replacement + code[match.end():]

# Now append _SliverAppBarDelegate to the end
delegate_code = """

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
"""

new_code += delegate_code

with open('lib/views/detalle_ficha/detalle_ficha_view.dart', 'w', encoding='utf-8') as f:
    f.write(new_code)

print("Replaced successfully")
