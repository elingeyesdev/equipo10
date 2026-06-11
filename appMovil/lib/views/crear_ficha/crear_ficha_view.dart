import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/campo_categoria_model.dart';
import '../../models/campos_categoria.dart';
import '../../viewmodels/crear_ficha_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'lpp_picker_view.dart';
import '../../theme/app_theme.dart';

class CrearFichaView extends StatefulWidget {
  const CrearFichaView({super.key});

  @override
  State<CrearFichaView> createState() => _CrearFichaViewState();
}

class _CrearFichaViewState extends State<CrearFichaView> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _recompensaCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  DateTime? _fechaPerdida;

  // Controladores dinámicos para campos de texto de la categoría
  final Map<String, TextEditingController> _ctrlsDinamicos = {};
  // Estado de switches para campos booleanos
  final Map<String, bool> _switchDinamicos = {};
  // Valor seleccionado para campos de opciones
  final Map<String, String?> _opcionDinamica = {};

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

  /// Reconstruye los controladores dinámicos al cambiar de categoría.
  void _reiniciarCamposDinamicos(List<CampoCategoria> campos) {
    for (final c in _ctrlsDinamicos.values) {
      c.dispose();
    }
    _ctrlsDinamicos.clear();
    _switchDinamicos.clear();
    _opcionDinamica.clear();

    for (final campo in campos) {
      switch (campo.tipo) {
        case TipoCampo.texto:
        case TipoCampo.numero:
          _ctrlsDinamicos[campo.clave] = TextEditingController();
          break;
        case TipoCampo.booleano:
          _switchDinamicos[campo.clave] = false;
          break;
        case TipoCampo.opciones:
          _opcionDinamica[campo.clave] = null;
          break;
      }
    }
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
      // Revalida el FormField de fecha para que el error desaparezca inmediatamente
      _formKey.currentState?.validate();
    }
  }

  Future<void> _onCrear() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUserId = context.read<AuthViewModel>().currentUserId ?? '';
    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: no hay sesión activa.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final vm = context.read<CrearFichaViewModel>();

    // Volcar campos dinámicos al ViewModel
    for (final entry in _ctrlsDinamicos.entries) {
      vm.setCaracteristica(entry.key, entry.value.text.trim());
    }
    for (final entry in _switchDinamicos.entries) {
      vm.setCaracteristica(entry.key, entry.value);
    }
    for (final entry in _opcionDinamica.entries) {
      vm.setCaracteristica(entry.key, entry.value);
    }

    final success = await vm.crearFicha(
      creadoPor: currentUserId,
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
          content: Text('¡Reporte publicado exitosamente!'),
          backgroundColor: AppTheme.primary,
        ),
      );
      setState(() {
        _tituloCtrl.clear();
        _descripcionCtrl.clear();
        _telefonoCtrl.clear();
        _recompensaCtrl.clear();
        _direccionCtrl.clear();
        _fechaPerdida = null;
        _ctrlsDinamicos.forEach((_, c) => c.clear());
        _switchDinamicos.updateAll((_, __) => false);
        _opcionDinamica.updateAll((_, __) => null);
      });
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Error al crear el reporte.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CrearFichaViewModel>();

    // Obtener categoría seleccionada y sus campos dinámicos
    final catActual = vm.categorias.isEmpty
        ? null
        : vm.categorias.firstWhere(
            (c) => c.id == vm.categoriaSeleccionadaId,
            orElse: () => vm.categorias.first,
          );
    final camposDinamicos = catActual == null
        ? <CampoCategoria>[]
        : CamposCategoria.paraNombre(catActual.nombre);

    return Scaffold(
      appBar: AppBar(title: const Text('Reportar Desaparecido')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // — Selector de imagen —
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
                      // ─── Sección: Datos generales ───
                      _SectionHeader(
                          label: 'Datos de la búsqueda',
                          icon: Icons.info_outline),
                      const SizedBox(height: 16),

                      // Dropdown de Categoría
                      if (vm.categorias.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          value: vm.categoriaSeleccionadaId,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: vm.categorias.map((cat) {
                            return DropdownMenuItem(
                                value: cat.id, child: Text(cat.nombre));
                          }).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            final nombreNueva = vm.categorias
                                .firstWhere((c) => c.id == val)
                                .nombre;
                            final nuevasCampos =
                                CamposCategoria.paraNombre(nombreNueva);
                            setState(
                                () => _reiniciarCamposDinamicos(nuevasCampos));
                            vm.seleccionarCategoria(val);
                          },
                          validator: (val) =>
                              val == null ? 'Seleccione una categoría' : null,
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        const Center(child: CircularProgressIndicator()),
                        const SizedBox(height: 16),
                      ],

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
                                  prefixIcon: const Icon(Icons.calendar_today),
                                  errorText: state.errorText,
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
                        maxLength: 200,
                        decoration: const InputDecoration(
                          labelText: 'Título de la búsqueda',
                          hintText:
                              'Ej: Búsqueda de persona mayor en zona norte',
                          prefixIcon: Icon(Icons.title),
                          counterText: '',
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
                        maxLength: 1000,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Descripción detallada',
                          hintText:
                              'Descripción física, última vez visto, ropa, etc.',
                          prefixIcon: Icon(Icons.description_outlined),
                          alignLabelWithHint: true,
                          counterText: '',
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
                      if (camposDinamicos.isNotEmpty) ...[
                        _SectionHeader(
                          label:
                              'Detalles de ${catActual?.nombre ?? 'Categoría'}',
                          icon: Icons.list_alt_outlined,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Estos campos ayudan a identificar mejor lo reportado.',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF757575)),
                        ),
                        const SizedBox(height: 16),
                        ...camposDinamicos.map((campo) => _CampoDinamico(
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
                      _SectionHeader(
                          label: 'Datos Opcionales', icon: Icons.tune),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _direccionCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Dirección o Referencia',
                          hintText: 'Ej: Cerca del parque X',
                          prefixIcon: Icon(Icons.place),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Teléfono con validación
                      TextFormField(
                        controller: _telefonoCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d\+\-\s\(\)]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Teléfono de contacto',
                          hintText: 'Ej: +591 71234567',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return null; // Opcional
                          final digits = v.replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 7 || digits.length > 15) {
                            return 'Número inválido (entre 7 y 15 dígitos)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Recompensa con validación numérica
                      TextFormField(
                        controller: _recompensaCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Recompensa en Bs.',
                          hintText: 'Ej: 500',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final val = double.tryParse(v);
                          if (val == null) return 'Ingresa un monto válido';
                          if (val < 0)
                            return 'La recompensa no puede ser negativa';
                          if (val > 1000000) return 'Monto demasiado alto';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 16, color: Colors.deepOrange),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Atención: El monto de la recompensa no podrá ser modificado posteriormente.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.deepOrange.shade700,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ─── Sección: Ubicación ───
                      _SectionHeader(
                          label: 'Ubicación del incidente',
                          icon: Icons.map_outlined),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LPPPickerView()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: vm.latitudLPP != null
                                ? AppTheme.primary.withValues(alpha: 0.06)
                                : const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: vm.latitudLPP != null
                                  ? AppTheme.success
                                  : AppTheme.info,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.map_outlined,
                                color: vm.latitudLPP != null
                                    ? AppTheme.primary
                                    : AppTheme.info,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  vm.latitudLPP != null
                                      ? 'Ubicación marcada: ${vm.latitudLPP!.toStringAsFixed(4)}, ${vm.longitudLPP!.toStringAsFixed(4)}'
                                      : 'Toca aquí para marcar la ubicación en el mapa',
                                  style: TextStyle(
                                    color: vm.latitudLPP != null
                                        ? AppTheme.primary
                                        : AppTheme.primaryLight,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (vm.latitudLPP != null)
                                const Icon(Icons.check_circle,
                                    color: AppTheme.success),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Botón publicar
                      vm.isLoading
                          ? const Center(
                              child: Column(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 8),
                                  Text('Publicando reporte...'),
                                ],
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _onCrear,
                                icon: const Icon(Icons.send),
                                label: const Text(
                                  'Publicar Reporte',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
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
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    switch (campo.tipo) {
      case TipoCampo.texto:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: ctrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: campo.etiqueta,
              hintText: campo.hint,
              prefixIcon: campo.icono != null ? Icon(campo.icono) : null,
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
            decoration: InputDecoration(
              labelText: campo.etiqueta,
              hintText: campo.hint,
              prefixIcon: campo.icono != null ? Icon(campo.icono) : null,
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
              prefixIcon: campo.icono != null ? Icon(campo.icono) : null,
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
        GestureDetector(
          onTap: isLoading ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: tieneImagen ? 280 : 200,
            width: double.infinity,
            decoration:
                BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.06)),
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
                          color: AppTheme.primary,
                        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
