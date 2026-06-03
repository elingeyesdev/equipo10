import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reporte_model.dart';
import '../../viewmodels/detalle_ficha_viewmodel.dart';
import '../../viewmodels/perfil_viewmodel.dart';
import '../../theme/app_theme.dart';
import 'bienvenida_operativo_view.dart';

/// Bottom Sheet que muestra el resumen del operativo y recoge la información
/// opcional del voluntario antes de confirmar la vinculación.
class UnirseBottomSheet extends StatefulWidget {
  final ReporteModel ficha;
  final String usuarioId;
  final int voluntariosActivos;

  const UnirseBottomSheet({
    super.key,
    required this.ficha,
    required this.usuarioId,
    required this.voluntariosActivos,
  });

  /// Muestra el bottom sheet y retorna true si el usuario se unió exitosamente.
  static Future<bool?> show(
    BuildContext context, {
    required ReporteModel ficha,
    required String usuarioId,
    required int voluntariosActivos,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UnirseBottomSheet(
        ficha: ficha,
        usuarioId: usuarioId,
        voluntariosActivos: voluntariosActivos,
      ),
    );
  }

  @override
  State<UnirseBottomSheet> createState() => _UnirseBottomSheetState();
}

class _UnirseBottomSheetState extends State<UnirseBottomSheet> {
  // ── Estado del formulario ──────────────────────────────────────────────────
  Set<String> _habilidadesSeleccionadas = {};
  bool _tieneVehiculo = false;
  final TextEditingController _vehiculoCtrl = TextEditingController();
  String? _disponibilidadSeleccionada;
  bool _aceptoResponsabilidad = false;
  bool _isLoading = false;

  static const _opcionesDisponibilidad = ['1 hora', '2 horas', '4 horas', 'Todo el día'];

  @override
  void initState() {
    super.initState();
    // Pre-cargar habilidades del perfil si están disponibles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final perfil = context.read<PerfilViewModel>().perfil;
      if (perfil != null && perfil.habilidades.isNotEmpty) {
        setState(() {
          _habilidadesSeleccionadas = perfil.habilidades.toSet();
        });
      }
    });
  }

  @override
  void dispose() {
    _vehiculoCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmarUnirse() async {
    if (!_aceptoResponsabilidad) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar la responsabilidad para continuar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final vm = context.read<DetalleFichaViewModel>();

    final success = await vm.unirseABusqueda(
      widget.ficha.id,
      widget.usuarioId,
      habilidadesOfrecidas: _habilidadesSeleccionadas.toList(),
      tieneVehiculo: _tieneVehiculo,
      tipoVehiculo: _tieneVehiculo ? _vehiculoCtrl.text.trim() : null,
      disponibilidadHoras: _disponibilidadSeleccionada,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      // Cerrar el bottom sheet y abrir la pantalla de bienvenida
      Navigator.of(context).pop(true);
      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => BienvenidaOperativoView(
            ficha: widget.ficha,
            usuarioId: widget.usuarioId,
          ),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'Error al unirse. Intenta de nuevo.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<PerfilViewModel>().perfil;
    final habilidadesPerfil = perfil?.habilidades ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Handle ─────────────────────────────────────────────────────
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),

            // ── Contenido scrollable ────────────────────────────────────────
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // Título
                  const Text(
                    'Unirse al operativo',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Revisa los detalles y completa tu información antes de confirmar.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  // ── Resumen del operativo ──────────────────────────────
                  _ResumenOperativo(
                    ficha: widget.ficha,
                    voluntariosActivos: widget.voluntariosActivos,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // ── Sección: Habilidades ───────────────────────────────
                  const _SectionTitle(
                    icon: Icons.star_outline,
                    label: 'Habilidades que aportarás',
                    subtitle: 'Selecciona las que aplican para este operativo',
                  ),
                  const SizedBox(height: 12),
                  if (habilidadesPerfil.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'No tienes habilidades registradas. Puedes añadirlas en tu perfil → Tu Actividad.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: habilidadesPerfil.map((hab) {
                        final selected = _habilidadesSeleccionadas.contains(hab);
                        return FilterChip(
                          label: Text(hab),
                          selected: selected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _habilidadesSeleccionadas.add(hab);
                              } else {
                                _habilidadesSeleccionadas.remove(hab);
                              }
                            });
                          },
                          selectedColor: AppTheme.primary.withOpacity(0.12),
                          checkmarkColor: AppTheme.primary,
                          labelStyle: TextStyle(
                            color: selected ? AppTheme.primary : AppTheme.textSecondary,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: selected ? AppTheme.primary : const Color(0xFFE0E0E0),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // ── Sección: Vehículo ──────────────────────────────────
                  const _SectionTitle(
                    icon: Icons.directions_car_outlined,
                    label: '¿Tienes vehículo disponible?',
                    subtitle: 'Ayuda al coordinador a asignarte la zona correcta',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Switch(
                        value: _tieneVehiculo,
                        onChanged: (val) => setState(() => _tieneVehiculo = val),
                        activeColor: AppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _tieneVehiculo ? 'Sí, tengo vehículo' : 'No, iré a pie',
                        style: TextStyle(
                          color: _tieneVehiculo ? AppTheme.primary : AppTheme.textSecondary,
                          fontWeight: _tieneVehiculo ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  if (_tieneVehiculo) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _vehiculoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de vehículo (opcional)',
                        hintText: 'Ej: Camioneta 4x4, Moto, Bicicleta...',
                        prefixIcon: Icon(Icons.commute_outlined),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // ── Sección: Disponibilidad ────────────────────────────
                  const _SectionTitle(
                    icon: Icons.schedule_outlined,
                    label: '¿Cuánto tiempo puedes dedicar?',
                    subtitle: 'Estimado aproximado',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _opcionesDisponibilidad.map((opcion) {
                      final selected = _disponibilidadSeleccionada == opcion;
                      return ChoiceChip(
                        label: Text(opcion),
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            _disponibilidadSeleccionada = val ? opcion : null;
                          });
                        },
                        selectedColor: AppTheme.primary.withOpacity(0.12),
                        checkmarkColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: selected ? AppTheme.primary : AppTheme.textSecondary,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: selected ? AppTheme.primary : const Color(0xFFE0E0E0),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // ── Checkbox de responsabilidad ────────────────────────
                  _ResponsabilidadCheckbox(
                    value: _aceptoResponsabilidad,
                    onChanged: (val) => setState(() => _aceptoResponsabilidad = val ?? false),
                  ),
                  const SizedBox(height: 24),

                  // ── Botón confirmar ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _confirmarUnirse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _aceptoResponsabilidad
                            ? AppTheme.primary
                            : const Color(0xFFBDBDBD),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.group_add),
                      label: Text(
                        _isLoading ? 'Uniéndome...' : 'Confirmar y unirme',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets internos ───────────────────────────────────────────────────────────

class _ResumenOperativo extends StatelessWidget {
  final ReporteModel ficha;
  final int voluntariosActivos;

  const _ResumenOperativo({
    required this.ficha,
    required this.voluntariosActivos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.radar, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ficha.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (ficha.nombreCategoria != null)
                      Text(
                        ficha.nombreCategoria!,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                icon: Icons.group_outlined,
                label: '$voluntariosActivos voluntario${voluntariosActivos != 1 ? 's' : ''}',
              ),
              const SizedBox(width: 8),
              const _InfoChip(
                icon: Icons.circle,
                label: 'Activo',
                color: AppTheme.success,
              ),
              if (ficha.cuadranteLatMin != null) ...[
                const SizedBox(width: 8),
                const _InfoChip(
                  icon: Icons.map_outlined,
                  label: 'Zona asignada',
                ),
              ],
            ],
          ),
          if (ficha.descripcion.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              ficha.descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = AppTheme.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResponsabilidadCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _ResponsabilidadCheckbox({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value
              ? AppTheme.success.withOpacity(0.06)
              : const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? AppTheme.success : const Color(0xFFFF9800),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.success,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Entiendo mi responsabilidad',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Debo acudir al área designada por el coordinador, mantener el GPS activo durante la búsqueda y reportar cualquier hallazgo inmediatamente.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
