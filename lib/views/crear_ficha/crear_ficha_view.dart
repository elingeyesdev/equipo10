import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../viewmodels/crear_ficha_viewmodel.dart';

class CrearFichaView extends StatefulWidget {
  const CrearFichaView({super.key});

  @override
  State<CrearFichaView> createState() => _CrearFichaViewState();
}

class _CrearFichaViewState extends State<CrearFichaView> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _onCrear() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? '';

    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: no hay sesión activa.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final vm = context.read<CrearFichaViewModel>();
    final success = await vm.crearFicha(
      creadoPor: currentUserId,
      titulo: _tituloCtrl.text,
      descripcion: _descripcionCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Ficha creada exitosamente!'),
          backgroundColor: Color(0xFF1B5E20),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Error al crear la ficha.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CrearFichaViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Desaparecido'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // — Selector de imagen mejorado —
              _ImagePickerSection(
                imageBytes: vm.imageBytes,
                tieneImagen: vm.tieneImagen,
                isLoading: vm.isLoading,
                onTap: vm.seleccionarImagen,
                onClear: vm.limpiarImagen,
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Datos del operativo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Título
                      TextFormField(
                        controller: _tituloCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Título del operativo',
                          hintText: 'Ej: Búsqueda de persona mayor en zona norte',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'El título es obligatorio'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Descripción
                      TextFormField(
                        controller: _descripcionCtrl,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          hintText:
                              'Descripción física, última vez visto, ropa, etc.',
                          prefixIcon: Icon(Icons.description_outlined),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'La descripción es obligatoria'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Placeholder mapa
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00BCD4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.map_outlined, color: Color(0xFF00BCD4)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                // TODO: El equipo implementará el Mapa Interactivo aquí.
                                'Ubicación: por implementar (Mapa Interactivo)',
                                style: TextStyle(
                                    color: Color(0xFF0277BD), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      vm.isLoading
                          ? const Center(
                              child: Column(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 8),
                                  Text('Subiendo ficha...'),
                                ],
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: _onCrear,
                              icon: const Icon(Icons.send),
                              label: const Text('Publicar Ficha'),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget reutilizable para seleccionar y previsualizar imagen.
class _ImagePickerSection extends StatelessWidget {
  final List<int>? imageBytes;
  final bool tieneImagen;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _ImagePickerSection({
    required this.imageBytes,
    required this.tieneImagen,
    required this.isLoading,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Contenedor de imagen / placeholder
        GestureDetector(
          onTap: isLoading ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: tieneImagen ? 280 : 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
            ),
            child: tieneImagen && imageBytes != null
                ? Image.memory(
                    imageBytes! as dynamic,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    gaplessPlayback: true,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xCCFFFFFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Toca para agregar una foto',
                        style: TextStyle(
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'JPG, PNG — recomendado',
                        style:
                            TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),

        // Overlay con botones cuando hay imagen
        if (tieneImagen)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xA6000000),
                  ],
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: isLoading ? null : onTap,
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    label: const Text('Cambiar foto',
                        style: TextStyle(color: Colors.white)),
                  ),
                  TextButton.icon(
                    onPressed: isLoading ? null : onClear,
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Color(0xFFEF9A9A)),
                    label: const Text('Quitar',
                        style: TextStyle(color: Color(0xFFEF9A9A))),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
