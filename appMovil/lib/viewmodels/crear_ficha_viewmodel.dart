import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/reporte_service.dart';
import '../services/categoria_service.dart';
import '../models/categoria_model.dart';
import 'package:dio/dio.dart'; // Para FormData si subimos archivo.

class CrearFichaViewModel extends ChangeNotifier {
  final ReporteService _reporteService = ReporteService();
  final CategoriaService _categoriaService = CategoriaService();
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _xFile;
  Uint8List? _imageBytes; // Usado para preview en web y mobile
  bool _isLoading = false;
  String? _errorMessage;

  double? _latitudLPP;
  double? _longitudLPP;
  List<dynamic>?
  _cuadrantes; // Mantenido temporalmente para compatibilidad LPP, pero ya no se envía

  List<CategoriaModel> categorias = [];
  String? categoriaSeleccionadaId;

  /// Mapa clave→valor con los campos dinámicos de la categoría seleccionada.
  final Map<String, dynamic> caracteristicas = {};

  Uint8List? get imageBytes => _imageBytes;
  bool get tieneImagen => _xFile != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double? get latitudLPP => _latitudLPP;
  double? get longitudLPP => _longitudLPP;

  CrearFichaViewModel() {
    _cargarCategorias();
  }

  static const _ordenCategorias = [
    'Personas', 'Mascotas', 'Documentos', 'Electrónicos',
    'Llaves', 'Ropa/Accesorios', 'Vehículos', 'Otros',
  ];

  Future<void> _cargarCategorias() async {
    _setLoading(true);
    try {
      final raw = await _categoriaService.obtenerCategorias();
      raw.sort((a, b) {
        final ia = _ordenCategorias.indexOf(a.nombre);
        final ib = _ordenCategorias.indexOf(b.nombre);
        final ra = ia == -1 ? _ordenCategorias.length : ia;
        final rb = ib == -1 ? _ordenCategorias.length : ib;
        return ra.compareTo(rb);
      });
      categorias = raw;
      if (categorias.isNotEmpty) {
        categoriaSeleccionadaId = categorias.first.id;
      }
      _errorMessage = null;
    } catch (e) {
      debugPrint('[CrearFichaVM] Error al cargar categorías: $e');
      _errorMessage = 'No se pudieron cargar las categorías. Toca para reintentar.';
    } finally {
      _setLoading(false);
    }
  }

  /// Permite reintentar la carga de categorías desde la UI si falló.
  Future<void> reintentarCargaCategorias() => _cargarCategorias();

  void seleccionarCategoria(String id) {
    categoriaSeleccionadaId = id;
    caracteristicas.clear(); // Limpiar campos al cambiar categoría
    notifyListeners();
  }

  void setCaracteristica(String clave, dynamic valor) {
    if (valor == null || (valor is String && valor.trim().isEmpty)) {
      caracteristicas.remove(clave);
    } else {
      caracteristicas[clave] = valor;
    }
    // No llamamos notifyListeners() aquí para evitar rebuilds innecesarios
  }

  void setUbicacion(double lat, double lng, List<dynamic> cuadrantesGenerados) {
    _latitudLPP = lat;
    _longitudLPP = lng;
    _cuadrantes = cuadrantesGenerados;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Abre la galería y convierte la imagen a bytes (compatible web + mobile).
  Future<void> seleccionarImagen() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        _xFile = picked;
        _imageBytes = await picked.readAsBytes();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error al seleccionar imagen: $e';
      notifyListeners();
    }
  }

  void limpiarImagen() {
    _xFile = null;
    _imageBytes = null;
    notifyListeners();
  }

  /// Crea la ficha: sube imagen si existe, luego guarda en BD.
  Future<bool> crearFicha({
    required String creadoPor,
    required String titulo,
    required String descripcion,
    String? telefonoContacto,
    double? recompensa,
    String? direccionReferencia,
    String? fechaPerdida,
  }) async {
    if (titulo.trim().isEmpty || descripcion.trim().isEmpty) {
      _errorMessage = 'El título y la descripción son obligatorios.';
      notifyListeners();
      return false;
    }

    if (categoriaSeleccionadaId == null) {
      _errorMessage = 'Selecciona una categoría.';
      notifyListeners();
      return false;
    }

    if (_latitudLPP == null || _longitudLPP == null) {
      _errorMessage = 'Debes seleccionar una ubicación en el mapa.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;
    try {
      String? fotoUrl;
      if (_xFile != null) {
        // En _reporteService ya está usando _api.client.post con FormData.
        // Pero requiere que le pasemos el _xFile de image_picker en Flutter
        fotoUrl = await _reporteService.subirImagen(_xFile!);
      }

      await _reporteService.crearReporte(
        usuarioId: creadoPor,
        categoriaId: categoriaSeleccionadaId!,
        titulo: titulo.trim(),
        descripcion: descripcion.trim(),
        latitud: _latitudLPP!,
        longitud: _longitudLPP!,
        cuadranteId: (_cuadrantes != null && _cuadrantes!.isNotEmpty)
            ? _cuadrantes!.first.toString()
            : null,
        fotoUrl: fotoUrl,
        telefonoContacto: telefonoContacto,
        recompensa: recompensa,
        direccionReferencia: direccionReferencia,
        fechaPerdida: fechaPerdida,
        caracteristicasExtra: caracteristicas.isNotEmpty
            ? Map<String, dynamic>.from(caracteristicas)
            : null,
      );

      // Reset form on success
      _xFile = null;
      _imageBytes = null;
      _latitudLPP = null;
      _longitudLPP = null;
      _cuadrantes = null;
      caracteristicas.clear();
      if (categorias.isNotEmpty) categoriaSeleccionadaId = categorias.first.id;

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
}