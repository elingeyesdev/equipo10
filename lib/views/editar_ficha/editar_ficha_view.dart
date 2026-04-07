import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ficha_model.dart';
import '../../viewmodels/editar_ficha_viewmodel.dart';

class EditarFichaView extends StatefulWidget {
  final FichaModel ficha;

  const EditarFichaView({super.key, required this.ficha});

  @override
  State<EditarFichaView> createState() => _EditarFichaViewState();
}

class _EditarFichaViewState extends State<EditarFichaView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloCtrl;
  late TextEditingController _descripcionCtrl;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.ficha.titulo);
    _descripcionCtrl = TextEditingController(text: widget.ficha.descripcion);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditarFichaViewModel>().inicializar(widget.ficha);
    });
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _onGuardar() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<EditarFichaViewModel>();
    final success = await vm.editarFicha(
      fichaId: widget.ficha.id,
      titulo: _tituloCtrl.text,
      descripcion: _descripcionCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Ficha actualizada!'),
          backgroundColor: Color(0xFF1B5E20),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Error al actualizar.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditarFichaViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Ficha'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // — Selector de imagen —
              _ImagePickerSection(
                imageBytes: vm.imageBytes,
                fotoUrlExistente: vm.tieneImagenNueva ? null : vm.fotoUrlExistente,
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
                        'Editar datos del operativo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _tituloCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Título del operativo',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'El título es obligatorio'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descripcionCtrl,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          prefixIcon: Icon(Icons.description_outlined),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'La descripción es obligatoria'
                            : null,
                      ),
                      const SizedBox(height: 28),

                      vm.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              onPressed: _onGuardar,
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Guardar Cambios'),
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

class _ImagePickerSection extends StatelessWidget {
  final List<int>? imageBytes;
  final String? fotoUrlExistente;
  final bool tieneImagen;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _ImagePickerSection({
    required this.imageBytes,
    required this.fotoUrlExistente,
    required this.tieneImagen,
    required this.isLoading,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageContent;

    if (imageBytes != null) {
      // Nueva imagen seleccionada (preview en bytes)
      imageContent = Image.memory(
        imageBytes! as dynamic,
        fit: BoxFit.cover,
        width: double.infinity,
        gaplessPlayback: true,
      );
    } else if (fotoUrlExistente != null && fotoUrlExistente!.isNotEmpty) {
      // Imagen existente desde URL
      imageContent = Image.network(
        fotoUrlExistente!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image, size: 60, color: Color(0xFF4CAF50)),
        ),
      );
    } else {
      // Sin imagen
      imageContent = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xCCFFFFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_photo_alternate_outlined,
                size: 48, color: Color(0xFF1B5E20)),
          ),
          const SizedBox(height: 12),
          const Text('Toca para agregar una foto',
              style: TextStyle(
                  color: Color(0xFF1B5E20), fontWeight: FontWeight.w600)),
        ],
      );
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: isLoading ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: tieneImagen ? 280 : 200,
            width: double.infinity,
            color: const Color(0xFFE8F5E9),
            child: imageContent,
          ),
        ),
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
