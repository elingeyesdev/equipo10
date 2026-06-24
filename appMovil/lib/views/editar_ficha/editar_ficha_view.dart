import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/reporte_model.dart';
import '../../models/campo_categoria_model.dart';
import '../../models/campos_categoria.dart';
import '../../viewmodels/editar_ficha_viewmodel.dart';
import '../../theme/app_theme.dart';

class EditarFichaView extends StatefulWidget {
  final ReporteModel ficha;

  const EditarFichaView({super.key, required this.ficha});

  @override
  State<EditarFichaView> createState() => _EditarFichaViewState();
}

class _EditarFichaViewState extends State<EditarFichaView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _recompensaCtrl;
  late TextEditingController _direccionCtrl;
  DateTime? _fechaPerdida;

  // Controladores dinámicos para campos de texto de la categoría
  final Map<String, TextEditingController> _ctrlsDinamicos = {};
  // Estado de switches para campos booleanos
  final Map<String, bool> _switchDinamicos = {};
  // Valor seleccionado para campos de opciones
  final Map<String, String?> _opcionDinamica = {};

  List<CampoCategoria> _camposDinamicos = [];

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.ficha.titulo);
    _descripcionCtrl = TextEditingController(text: widget.ficha.descripcion);
    _telefonoCtrl =
        TextEditingController(text: widget.ficha.telefonoContacto ?? '');
    _recompensaCtrl =
        TextEditingController(text: widget.ficha.recompensa?.toString() ?? '');
    _direccionCtrl =
        TextEditingController(text: widget.ficha.direccionReferencia ?? '');

    if (widget.ficha.fechaPerdida != null) {
      _fechaPerdida = DateTime.tryParse(widget.ficha.fechaPerdida!);
    }

    if (widget.ficha.nombreCategoria != null) {
      _camposDinamicos =
          CamposCategoria.paraNombre(widget.ficha.nombreCategoria!);
      _inicializarCamposDinamicos();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditarFichaViewModel>().inicializar(widget.ficha);
    });
  }

  void _inicializarCamposDinamicos() {
    final charsActuales = widget.ficha.caracteristicas ?? {};

    for (final campo in _camposDinamicos) {
      final valorActual = charsActuales[campo.clave];

      switch (campo.tipo) {
        case TipoCampo.texto:
        case TipoCampo.numero:
          _ctrlsDinamicos[campo.clave] =
              TextEditingController(text: valorActual?.toString() ?? '');
          break;
        case TipoCampo.booleano:
          _switchDinamicos[campo.clave] =
              valorActual == true || valorActual == 'true' || valorActual == 1;
          break;
        case TipoCampo.opciones:
          _opcionDinamica[campo.clave] = valorActual?.toString();
          if (_opcionDinamica[campo.clave] != null &&
              !campo.opciones!.contains(_opcionDinamica[campo.clave])) {
            _opcionDinamica[campo.clave] = null;
          }
          break;
      }
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _telefonoCtrl.dispose();
    _recompensaCtrl.dispose();
    _direccionCtrl.dispose();
    for (final c in _ctrlsDinamicos.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaPerdida ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Fecha del incidente',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (picked != null) {
      setState(() => _fechaPerdida = picked);
      _formKey.currentState?.validate();
    }
  }

  Future<void> _onGuardar() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<EditarFichaViewModel>();

    // Volcar campos dinámicos al ViewModel
    for (final entry in _ctrlsDinamicos.entries) {
      vm.setCaracteristica(entry.key, entry.value.text.trim());
    }
    for (final entry in _switchDinamicos.entries) {
      vm.setCaracteristica(entry.key, entry.value.toString());
    }
    for (final entry in _opcionDinamica.entries) {
      vm.setCaracteristica(entry.key, entry.value);
    }

    final success = await vm.editarFicha(
      fichaId: widget.ficha.id,
      titulo: _tituloCtrl.text,
      descripcion: _descripcionCtrl.text,
      telefonoContacto: _telefonoCtrl.text.isEmpty ? null : _telefonoCtrl.text,
      recompensa: _recompensaCtrl.text.isEmpty
          ? null
          : double.tryParse(_recompensaCtrl.text),
      direccionReferencia:
          _direccionCtrl.text.isEmpty ? null : _direccionCtrl.text,
      fechaPerdida: _fechaPerdida?.toIso8601String(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Ficha actualizada exitosamente!'),
          backgroundColor: AppTheme.primary,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Error al actualizar la ficha.'),
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
        backgroundColor: AppTheme.surface,
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: AppTheme.darkDark),
        title: const Text(
          'Editar reporte',
          style: TextStyle(color: AppTheme.darkDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // — Selector de imagen —
              _ImagePickerSection(
                imageBytes: vm.imageBytes,
                fotoUrlExistente:
                    vm.tieneImagenNueva ? null : vm.fotoUrlExistente,
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
                      // ─── Sección: Datos generales ───
                      const _SectionHeader(label: 'Datos del reporte'),
                      const SizedBox(height: 16),

                      // Fecha del incidente (OBLIGATORIA)
                      FormField<DateTime>(
                        initialValue: _fechaPerdida,
                        validator: (_) => _fechaPerdida == null
                            ? 'La fecha del incidente es obligatoria'
                            : null,
                        builder: (state) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => _seleccionarFecha(context),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Fecha del incidente *',
                                  prefixIcon: const Icon(
                                      Icons.calendar_today,
                                      size: 18),
                                  errorText: state.errorText,
                                  errorStyle: const TextStyle(
                                      color: AppTheme.accentDark),
                                  floatingLabelStyle: const TextStyle(
                                      color: AppTheme.darkLight),
                                ),
                                child: Text(
                                  _fechaPerdida == null
                                      ? 'Seleccionar fecha'
                                      : '${_fechaPerdida!.day.toString().padLeft(2, '0')}/${_fechaPerdida!.month.toString().padLeft(2, '0')}/${_fechaPerdida!.year}',
                                  style: TextStyle(
                                    color: _fechaPerdida == null
                                        ? const Color(0xFF9E9E9E)
                                        : const Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Título
                      TextFormField(
                        controller: _tituloCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: 25,
                        decoration: const InputDecoration(
                          labelText: 'Título de la búsqueda',
                          hintText: 'Ej: Búsqueda de persona mayor en zona norte',
                          prefixIcon: Icon(Icons.title, size: 18),
                          floatingLabelStyle:
                              TextStyle(color: AppTheme.darkLight),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'El título es obligatorio';
                          if (v.trim().length < 5)
                            return 'El título debe tener al menos 5 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Descripción
                      TextFormField(
                        controller: _descripcionCtrl,
                        maxLines: 4,
                        maxLength: 150,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Descripción detallada',
                          hintText:
                              'Descripción física, última vez visto, ropa, etc.',
                          prefixIcon:
                              Icon(Icons.description_outlined, size: 18),
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(24)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(24)),
                            borderSide: BorderSide(color: AppTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(24)),
                            borderSide: BorderSide(
                                color: AppTheme.primaryBase, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(24)),
                            borderSide:
                                BorderSide(color: AppTheme.accentDark),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(24)),
                            borderSide: BorderSide(
                                color: AppTheme.accentDark, width: 2),
                          ),
                          errorStyle:
                              TextStyle(color: AppTheme.accentDark),
                          floatingLabelStyle:
                              TextStyle(color: AppTheme.darkLight),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'La descripción es obligatoria';
                          if (v.trim().length < 10)
                            return 'La descripción es muy corta';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // ─── Sección: Campos específicos de la categoría ───
                      if (_camposDinamicos.isNotEmpty) ...[
                        const _SectionHeader(label: 'Detalles de documentos'),
                        const SizedBox(height: 4),
                        const Text(
                          'Estos campos ayudan a identificar mejor lo reportado.',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF757575)),
                        ),
                        const SizedBox(height: 16),
                        ..._camposDinamicos.map((campo) => _CampoDinamico(
                              campo: campo,
                              ctrl: _ctrlsDinamicos[campo.clave],
                              switchValue: _switchDinamicos[campo.clave],
                              opcionValue: _opcionDinamica[campo.clave],
                              onTextChanged: (v) =>
                                  _ctrlsDinamicos[campo.clave]?.text = v,
                              onSwitchChanged: (v) => setState(
                                  () => _switchDinamicos[campo.clave] = v),
                              onOpcionChanged: (v) => setState(
                                  () => _opcionDinamica[campo.clave] = v),
                            )),
                        const SizedBox(height: 8),
                      ],

                      // ─── Sección: Datos opcionales ───
                      const _SectionHeader(label: 'Datos opcionales'),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _direccionCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: 75,
                        decoration: const InputDecoration(
                          labelText: 'Dirección o referencia',
                          hintText: 'Dirección o referencia',
                          prefixIcon: Icon(Icons.place, size: 18),
                          floatingLabelStyle:
                              TextStyle(color: AppTheme.darkLight),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _telefonoCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d\+\-\s\(\)]')),
                        ],
                        maxLength: 8,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono de contacto',
                          hintText: 'Ej: 71234567',
                          prefixIcon: Icon(Icons.phone, size: 18),
                          floatingLabelStyle:
                              TextStyle(color: AppTheme.darkLight),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return null; // Opcional
                          final digits = v.replaceAll(RegExp(r'\D'), '');
                          if (digits.length != 8) {
                            return 'El teléfono debe tener exactamente 8 dígitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Recompensa (solo lectura)
                      TextFormField(
                        controller: _recompensaCtrl,
                        readOnly: true,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Recompensa en Bs.',
                          prefixIcon: Icon(Icons.attach_money, size: 18),
                          filled: true,
                          fillColor: Color(0xFFF5F5F5),
                          floatingLabelStyle:
                              TextStyle(color: AppTheme.darkLight),
                        ),
                      ),
                      const SizedBox(height: 28),

                      vm.isLoading
                          ? const Center(
                              child: Column(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 8),
                                  Text('Guardando cambios...'),
                                ],
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _onGuardar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                ),
                                child: const Text(
                                  'Guardar cambios',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                      const SizedBox(height: 16),
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

// ──────────────────────────────────────────────────────────
// Widget: Encabezado de sección
// ──────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.primary,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Widget: Campo dinámico según tipo
// ──────────────────────────────────────────────────────────
class _CampoDinamico extends StatelessWidget {
  final CampoCategoria campo;
  final TextEditingController? ctrl;
  final bool? switchValue;
  final String? opcionValue;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<bool> onSwitchChanged;
  final ValueChanged<String?> onOpcionChanged;

  const _CampoDinamico({
    required this.campo,
    required this.ctrl,
    required this.switchValue,
    required this.opcionValue,
    required this.onTextChanged,
    required this.onSwitchChanged,
    required this.onOpcionChanged,
  });

  int _getMaxLength() {
    final lower = campo.etiqueta.toLowerCase();
    if (lower.contains('raza') || lower.contains('pelaje') || lower.contains('plumas')) return 25;
    if (lower.contains('nombre')) return 75;
    if (lower.contains('tipo')) return 50;
    if (lower.contains('marca') || lower.contains('modelo') || lower.contains('matrícula') || lower.contains('matricula')) return 30;
    if (lower.contains('color')) return 30;
    return 100;
  }

  @override
  Widget build(BuildContext context) {
    switch (campo.tipo) {
      case TipoCampo.texto:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: ctrl,
            textCapitalization: TextCapitalization.sentences,
            maxLength: _getMaxLength(),
            decoration: InputDecoration(
              labelText: campo.etiqueta,
              hintText: campo.hint,
              prefixIcon:
                  campo.icono != null ? Icon(campo.icono, size: 18) : null,
              floatingLabelStyle:
                  const TextStyle(color: AppTheme.darkLight),
            ),
            validator: campo.requerido
                ? (v) => (v == null || v.trim().isEmpty)
                    ? '${campo.etiqueta} es requerido'
                    : null
                : null,
          ),
        );

      case TipoCampo.numero:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 3,
            decoration: InputDecoration(
              labelText: campo.etiqueta,
              hintText: campo.hint,
              prefixIcon:
                  campo.icono != null ? Icon(campo.icono, size: 18) : null,
              floatingLabelStyle:
                  const TextStyle(color: AppTheme.darkLight),
            ),
            validator: campo.requerido
                ? (v) => (v == null || v.trim().isEmpty)
                    ? '${campo.etiqueta} es requerido'
                    : null
                : null,
          ),
        );

      case TipoCampo.opciones:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<String>(
            value: opcionValue,
            decoration: InputDecoration(
              labelText: campo.etiqueta,
              prefixIcon:
                  campo.icono != null ? Icon(campo.icono, size: 18) : null,
              floatingLabelStyle:
                  const TextStyle(color: AppTheme.darkLight),
            ),
            hint: const Text('Seleccionar'),
            items: campo.opciones!
                .map((op) => DropdownMenuItem(value: op, child: Text(op)))
                .toList(),
            onChanged: onOpcionChanged,
            validator: campo.requerido
                ? (v) => v == null ? '${campo.etiqueta} es requerido' : null
                : null,
          ),
        );

      case TipoCampo.booleano:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SwitchListTile(
              title: Text(campo.etiqueta,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              secondary: campo.icono != null
                  ? Icon(campo.icono, color: AppTheme.primary)
                  : null,
              value: switchValue ?? false,
              activeColor: AppTheme.primary,
              onChanged: onSwitchChanged,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        );
    }
  }
}

// ──────────────────────────────────────────────────────────
// Widget: Selector y preview de imagen
// ──────────────────────────────────────────────────────────
class _ImagePickerSection extends StatelessWidget {
  final Uint8List? imageBytes;
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
      imageContent = Image.memory(
        imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        gaplessPlayback: true,
      );
    } else if (fotoUrlExistente != null && fotoUrlExistente!.isNotEmpty) {
      imageContent = CachedNetworkImage(
        imageUrl: fotoUrlExistente!,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, __) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image, size: 60, color: AppTheme.success),
        ),
      );
    } else {
      imageContent = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xCCFFFFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, size: 48, color: AppTheme.primary),
          ),
          const SizedBox(height: 12),
          const Text(
            'Toca para agregar una foto',
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
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
            decoration:
                const BoxDecoration(color: AppTheme.background),
            child: imageContent,
          ),
        ),
        if (tieneImagen)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xA6000000)],
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: isLoading ? null : onTap,
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cambiar foto'),
                  ),
                  TextButton(
                    onPressed: isLoading ? null : onClear,
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: AppTheme.darkDark,
                    ),
                    child: const Text('Quitar'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
