import 'package:flutter/material.dart';
import 'campo_categoria_model.dart';

/// Define los campos específicos para cada categoría de reporte.
/// La clave de cada Map es el nombre normalizado (minúsculas, sin tildes)
/// que coincide con lo que el backend espera en `caracteristicas`.
class CamposCategoria {
  static const Map<String, List<CampoCategoria>> _campos = {
    'personas': [
      CampoCategoria(
        clave: 'edad_aproximada',
        etiqueta: 'Edad aproximada',
        tipo: TipoCampo.numero,
        hint: 'Ej: 35',
        icono: Icons.cake_outlined,
      ),
      CampoCategoria(
        clave: 'sexo',
        etiqueta: 'Sexo',
        tipo: TipoCampo.opciones,
        opciones: ['Masculino', 'Femenino', 'No especificado'],
        icono: Icons.person_outline,
      ),
      CampoCategoria(
        clave: 'estatura',
        etiqueta: 'Estatura (cm)',
        tipo: TipoCampo.numero,
        hint: 'Ej: 170',
        icono: Icons.height,
      ),
      CampoCategoria(
        clave: 'ropa_que_vestia',
        etiqueta: 'Ropa que vestía',
        tipo: TipoCampo.texto,
        hint: 'Ej: Camiseta roja, pantalón azul',
        icono: Icons.checkroom_outlined,
      ),
      CampoCategoria(
        clave: 'senas_particulares',
        etiqueta: 'Señas particulares',
        tipo: TipoCampo.texto,
        hint: 'Ej: Cicatriz en mejilla, usa gafas',
        icono: Icons.face_outlined,
      ),
    ],

    'mascotas': [
      CampoCategoria(
        clave: 'especie',
        etiqueta: 'Especie',
        tipo: TipoCampo.opciones,
        opciones: ['Perro', 'Gato', 'Ave', 'Otro'],
        requerido: true,
        icono: Icons.pets,
      ),
      CampoCategoria(
        clave: 'raza',
        etiqueta: 'Raza',
        tipo: TipoCampo.texto,
        hint: 'Ej: Labrador, Mestizo',
        icono: Icons.pets,
      ),
      CampoCategoria(
        clave: 'color_pelaje',
        etiqueta: 'Color de pelaje / plumas',
        tipo: TipoCampo.texto,
        hint: 'Ej: Marrón con blanco',
        icono: Icons.palette_outlined,
      ),
      CampoCategoria(
        clave: 'tenia_collar',
        etiqueta: '¿Tenía collar?',
        tipo: TipoCampo.booleano,
        icono: Icons.radio_button_checked,
      ),
      CampoCategoria(
        clave: 'esterilizado',
        etiqueta: '¿Está esterilizado/a?',
        tipo: TipoCampo.booleano,
        icono: Icons.medical_services_outlined,
      ),
    ],

    'documentos': [
      CampoCategoria(
        clave: 'tipo_documento',
        etiqueta: 'Tipo de documento',
        tipo: TipoCampo.opciones,
        opciones: ['Carnet de identidad', 'Pasaporte', 'Licencia de conducir', 'Otro'],
        requerido: true,
        icono: Icons.badge_outlined,
      ),
      CampoCategoria(
        clave: 'nombre_en_documento',
        etiqueta: 'Nombre en el documento',
        tipo: TipoCampo.texto,
        hint: 'Ej: Juan Pérez López',
        icono: Icons.person_outline,
      ),
    ],

    'electrónicos': [
      CampoCategoria(
        clave: 'tipo_electronico',
        etiqueta: 'Tipo de dispositivo',
        tipo: TipoCampo.opciones,
        opciones: ['Celular', 'Laptop', 'Tablet', 'Cámara', 'Otro'],
        requerido: true,
        icono: Icons.devices_outlined,
      ),
      CampoCategoria(
        clave: 'marca',
        etiqueta: 'Marca',
        tipo: TipoCampo.texto,
        hint: 'Ej: Samsung, Apple, Lenovo',
        icono: Icons.business_outlined,
      ),
      CampoCategoria(
        clave: 'modelo',
        etiqueta: 'Modelo',
        tipo: TipoCampo.texto,
        hint: 'Ej: Galaxy S22, iPhone 14',
        icono: Icons.smartphone,
      ),
      CampoCategoria(
        clave: 'color',
        etiqueta: 'Color',
        tipo: TipoCampo.texto,
        hint: 'Ej: Negro, Plateado',
        icono: Icons.palette_outlined,
      ),
      CampoCategoria(
        clave: 'imei',
        etiqueta: 'IMEI / Número de serie (opcional)',
        tipo: TipoCampo.texto,
        hint: 'Solo para celulares',
        icono: Icons.pin_outlined,
      ),
    ],

    'vehículos': [
      CampoCategoria(
        clave: 'tipo_vehiculo',
        etiqueta: 'Tipo de vehículo',
        tipo: TipoCampo.opciones,
        opciones: ['Automóvil', 'Motocicleta', 'Bicicleta', 'Camión', 'Otro'],
        requerido: true,
        icono: Icons.directions_car_outlined,
      ),
      CampoCategoria(
        clave: 'placa',
        etiqueta: 'Placa / Matrícula',
        tipo: TipoCampo.texto,
        hint: 'Ej: 1234-ABC',
        icono: Icons.pin_outlined,
      ),
      CampoCategoria(
        clave: 'marca',
        etiqueta: 'Marca',
        tipo: TipoCampo.texto,
        hint: 'Ej: Toyota, Honda',
        icono: Icons.business_outlined,
      ),
      CampoCategoria(
        clave: 'color',
        etiqueta: 'Color',
        tipo: TipoCampo.texto,
        hint: 'Ej: Rojo, Blanco',
        icono: Icons.palette_outlined,
      ),
    ],

    'ropa/accesorios': [
      CampoCategoria(
        clave: 'tipo_prenda',
        etiqueta: 'Tipo de prenda/accesorio',
        tipo: TipoCampo.texto,
        hint: 'Ej: Chaqueta, Bolso, Reloj',
        icono: Icons.checkroom_outlined,
      ),
      CampoCategoria(
        clave: 'color',
        etiqueta: 'Color',
        tipo: TipoCampo.texto,
        hint: 'Ej: Azul marino',
        icono: Icons.palette_outlined,
      ),
      CampoCategoria(
        clave: 'marca',
        etiqueta: 'Marca (si aplica)',
        tipo: TipoCampo.texto,
        hint: 'Ej: Nike, Adidas',
        icono: Icons.business_outlined,
      ),
    ],

    'llaves': [
      CampoCategoria(
        clave: 'tipo_llave',
        etiqueta: 'Tipo de llave',
        tipo: TipoCampo.opciones,
        opciones: ['Casa/Departamento', 'Vehículo', 'Oficina/Negocio', 'Otra'],
        icono: Icons.key_outlined,
      ),
      CampoCategoria(
        clave: 'tiene_llavero',
        etiqueta: '¿Tiene llavero identificable?',
        tipo: TipoCampo.booleano,
        icono: Icons.label_outlined,
      ),
      CampoCategoria(
        clave: 'descripcion_llavero',
        etiqueta: 'Descripción del llavero',
        tipo: TipoCampo.texto,
        hint: 'Ej: Llavero rojo con figura de perro',
        icono: Icons.description_outlined,
      ),
    ],
  };

  /// Retorna los campos para la categoría dada (por nombre normalizado).
  /// Si no hay campos específicos, retorna lista vacía.
  static List<CampoCategoria> paraNombre(String nombreCategoria) {
    final clave = nombreCategoria.toLowerCase().trim();
    return _campos[clave] ?? [];
  }
}
