import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/reporte_model.dart';
import '../../models/evidencia_model.dart';
import '../../services/encuesta_service.dart';
import '../../services/evidencia_service.dart';
import '../../services/reporte_service.dart';

class EncuestaDialog extends StatefulWidget {
  final ReporteModel reporte;
  final String usuarioId;

  /// true = coordinador que cerró la búsqueda; false = voluntario participante.
  final bool isCoordinador;

  const EncuestaDialog({
    super.key,
    required this.reporte,
    required this.usuarioId,
    this.isCoordinador = false,
  });

  static Future<void> show(
    BuildContext context,
    ReporteModel reporte,
    String usuarioId, {
    bool isCoordinador = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EncuestaDialog(
        reporte: reporte,
        usuarioId: usuarioId,
        isCoordinador: isCoordinador,
      ),
    );
  }

  @override
  State<EncuestaDialog> createState() => _EncuestaDialogState();
}

class _EncuestaDialogState extends State<EncuestaDialog> {
  int _puntuacion = 0;
  final _comentarioCtrl = TextEditingController();
  bool _isLoading = false;
  final _encuestaService = EncuestaService();
  final _evidenciaService = EvidenciaService();
  final _reporteService = ReporteService();

  List<EvidenciaModel> _evidenciasAprobadas = [];
  String? _heroeSeleccionado;
  bool _cargandoEvidencias = false;

  @override
  void initState() {
    super.initState();
    if (widget.isCoordinador) {
      _cargarEvidencias();
    }
  }

  Future<void> _cargarEvidencias() async {
    setState(() => _cargandoEvidencias = true);
    try {
      final evs = await _evidenciaService.obtenerEvidenciasAdmin(widget.reporte.id);
      if (mounted) {
        setState(() {
          _evidenciasAprobadas = evs.where((e) => e.estado == 'approved').toList();
        });
      }
    } catch (e) {
      debugPrint("Error al cargar evidencias: $e");
    } finally {
      if (mounted) setState(() => _cargandoEvidencias = false);
    }
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_puntuacion == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona al menos una estrella antes de enviar.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.isCoordinador) {
        final comentarioTexto = _comentarioCtrl.text.trim();
        await _reporteService.marcarResuelto(
          widget.reporte.id,
          resueltoPor: _heroeSeleccionado == 'nadie' 
              ? null 
              : (_heroeSeleccionado == 'admin' ? widget.usuarioId : _heroeSeleccionado),
          historiaExito: comentarioTexto.isNotEmpty ? comentarioTexto : null,
          justificacion: comentarioTexto.isNotEmpty ? comentarioTexto : null,
        );
      }

      final exito = await _encuestaService.enviarEncuesta(
        reporteId: widget.reporte.id,
        usuarioId: widget.usuarioId,
        puntuacion: _puntuacion,
        comentario: _comentarioCtrl.text.trim().isNotEmpty
            ? _comentarioCtrl.text.trim()
            : null,
      );

      if (!mounted) return;
      
      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gracias por tus comentarios.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo enviar la encuesta (sin conexión). Se guardará para después.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.reporte.titulo;
    final String descripcion = widget.isCoordinador
        ? 'El operativo "$titulo" ha sido cerrado. ¿Qué tal salió la coordinación? Tu evaluación ayuda a mejorar el sistema.'
        : 'Participaste en la búsqueda "$titulo". Cuéntanos tu experiencia como voluntario para seguir mejorando.';

    // Extraer usuarios únicos de evidencias
    final Map<String, String> usuariosUnicos = {};
    for (var ev in _evidenciasAprobadas) {
      if (ev.nombreUsuario != null) {
        usuariosUnicos[ev.usuarioId] = ev.nombreUsuario!;
      }
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.isCoordinador ? 'Cierre de Operativo' : 'Operativo Finalizado',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(descripcion,
                style: const TextStyle(fontSize: 13, height: 1.4)),
            const SizedBox(height: 20),
            const Text(
              '¿Qué tan satisfecho/a estás con el operativo?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 10),
            // Estrellas — FittedBox evita overflow en pantallas pequeñas
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => _puntuacion = index + 1),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    icon: Icon(
                      index < _puntuacion
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber.shade700,
                      size: 34,
                    ),
                  );
                }),
              ),
            ),
            if (_puntuacion > 0) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  [
                    '',
                    'Muy mal',
                    'Regular',
                    'Bien',
                    'Muy bien',
                    'Excelente'
                  ][_puntuacion],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            
            if (widget.isCoordinador) ...[
              const SizedBox(height: 16),
              const Text(
                '¿Quién fue el Héroe?',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              if (_cargandoEvidencias)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  value: _heroeSeleccionado,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: const Text('Selecciona a un voluntario', overflow: TextOverflow.ellipsis),
                  items: [
                    const DropdownMenuItem(
                      value: 'nadie',
                      child: Text('Nadie / Volvió a casa / Lo encontré yo', overflow: TextOverflow.ellipsis),
                    ),
                    ...usuariosUnicos.entries.map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value, overflow: TextOverflow.ellipsis),
                    )).toList(),
                  ],
                  onChanged: (val) => setState(() => _heroeSeleccionado = val),
                ),
            ],

            const SizedBox(height: 16),
            Text(
              widget.isCoordinador ? 'Historia de Éxito / Comentario:' : 'Comentario (opcional):',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comentarioCtrl,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: widget.isCoordinador ? 'Cuenta el final feliz...' : '¿Algo que mejorar?',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [

        ElevatedButton(
          onPressed: _isLoading ? null : _enviar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Enviar'),
        ),
      ],
    );
  }
}
