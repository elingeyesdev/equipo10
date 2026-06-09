import 'package:http/http.dart' as http;

String encodePolyline(List<List<double>> coordinates) {
  int lastLat = 0;
  int lastLng = 0;
  final StringBuffer result = StringBuffer();
  for (final point in coordinates) {
    final int lat = (point[0] * 1e5).round();
    final int lng = (point[1] * 1e5).round();
    final int dLat = lat - lastLat;
    final int dLng = lng - lastLng;
    _encode(dLat, result);
    _encode(dLng, result);
    lastLat = lat;
    lastLng = lng;
  }
  return result.toString();
}

void _encode(int v, StringBuffer result) {
  v = v < 0 ? ~(v << 1) : v << 1;
  while (v >= 0x20) {
    result.write(String.fromCharCode((0x20 | (v & 0x1f)) + 63));
    v >>= 5;
  }
  result.write(String.fromCharCode(v + 63));
}

void main() async {
  String token = 'YOUR_MAPBOX_TOKEN_HERE';
  String baseUrl = 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/static';
  
  String polyStr = encodePolyline([[-12.0, -77.0], [-12.0, -77.1], [-12.1, -77.1], [-12.1, -77.0], [-12.0, -77.0]]);
  String path = 'path-2+2196F3-0.8+2196F3-0.15(%24%7BUri.encodeComponent(polyStr)%7D)';
  String pathEnc = Uri.encodeComponent(polyStr);
  
  String url = '$baseUrl/path-2+2196F3-0.8+2196F3-0.15($pathEnc)/auto/800x500@2x?padding=50&access_token=$token';
  
  print(url);
  var res = await http.get(Uri.parse(url));
  print(res.statusCode);
  if (res.statusCode != 200) print(res.body);
}
