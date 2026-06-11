import 'package:flutter/material.dart';

enum TipoCampo { texto, numero, opciones, booleano }

/// Define un campo dinámico del formulario según la categoría.
class CampoCategoria {
  final String clave; // clave que se guarda en reporte_caracteristicas
  final String etiqueta; // Label visible al usuario
  final TipoCampo tipo;
  final bool requerido;
  final List<String>? opciones; // Para tipo == opciones
  final String? hint;
  final IconData? icono;

  const CampoCategoria({
    required this.clave,
    required this.etiqueta,
    required this.tipo,
    this.requerido = false,
    this.opciones,
    this.hint,
    this.icono,
  });
}
