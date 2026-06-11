import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'descargador_interface.dart';

class DescargadorMobile implements DescargadorInterface {
  final Dio _dio = Dio();

  @override
  Future<void> descargarArchivo(String url, String nombreArchivo) async {
    final directory = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final String path = '${directory.path}/$nombreArchivo';
    await _dio.download(url, path);
  }

  @override
  Future<void> descargarTexto(
      String contenido, String nombreArchivo, String mimeType) async {
    final directory = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final String path = '${directory.path}/$nombreArchivo';
    final file = File(path);
    await file.writeAsString(contenido);
  }
}

DescargadorInterface obtenerDescargador() => DescargadorMobile();
