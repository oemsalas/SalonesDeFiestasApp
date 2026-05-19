import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/salon_model.dart';

class ApiService {
  static const String _baseUrl = 'http://159.112.149.218/api';
  //static const String _baseUrl = 'http://192.168.2.140:8080/api';

  static const Duration _timeout = Duration(seconds: 15);

  // ─── Salones cercanos ────────────────────────────────────────────────────

  static Future<List<Salon>> obtenerSalonesCercanos({
    required double lat,
    required double lon,
    double radioKm = 10,
  }) async {
    final uri = Uri.parse('$_baseUrl/v1/salones/cercanos').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'radioKm': radioKm.toString(),
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: _headers,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((j) => Salon.fromJson(j as Map<String, dynamic>)).toList();
      } else {
        throw ApiException(
          'Error al obtener salones: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error de conexión: $e', 0);
    }
  }

  // ─── Consultar disponibilidad ────────────────────────────────────────────

  static Future<List<DisponibilidadResponse>> consultarDisponibilidad(
    ConsultaDisponibilidadRequest request,
  ) async {
    final uri = Uri.parse('$_baseUrl/v1/salones/disponibilidad');

    try {
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode(request.toJson()),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((j) => DisponibilidadResponse.fromJson(j as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          'Error al consultar disponibilidad: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error de conexión: $e', 0);
    }
  }

  // ─── Obtener todos los salones ───────────────────────────────────────────

  static Future<List<Salon>> listarSalones() async {
    final uri = Uri.parse('$_baseUrl/v1/salones');

    try {
      final response = await http.get(
        uri,
        headers: _headers,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((j) => Salon.fromJson(j as Map<String, dynamic>)).toList();
      } else {
        throw ApiException(
          'Error al listar salones: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error de conexión: $e', 0);
    }
  }

  // ─── Obtener salón por ID ────────────────────────────────────────────────

  static Future<Salon> obtenerSalon(int id) async {
    final uri = Uri.parse('$_baseUrl/v1/salones/$id');

    try {
      final response = await http.get(
        uri,
        headers: _headers,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        return Salon.fromJson(json.decode(response.body) as Map<String, dynamic>);
      } else {
        throw ApiException(
          'Salón no encontrado',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error de conexión: $e', 0);
    }
  }

  // ─── Imágenes ────────────────────────────────────────────────────────────

  /// Retorna la URL base para usarla en widgets de imagen
  static String get baseUrl => _baseUrl;

  /// Lista los metadatos de imágenes activas de un salón
  static Future<List<ImagenSalon>> listarImagenes(int salonId) async {
    final uri = Uri.parse('$_baseUrl/v1/salones/$salonId/imagenes');
    try {
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((j) => ImagenSalon.fromJson(j as Map<String, dynamic>))
            .toList()
          ..sort((a, b) {
            // Principal primero, luego por orden
            if (a.esPrincipal && !b.esPrincipal) return -1;
            if (!a.esPrincipal && b.esPrincipal) return 1;
            return (a.orden ?? 999).compareTo(b.orden ?? 999);
          });
      } else {
        throw ApiException('Error al obtener imágenes: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error de conexión: $e', 0);
    }
  }

  /// URL para cargar directamente la imagen binaria
  static String urlImagen(int salonId, int imagenId) =>
      '$_baseUrl/v1/salones/$salonId/imagenes/$imagenId/archivo';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}

class ApiException implements Exception {
  final String mensaje;
  final int statusCode;

  ApiException(this.mensaje, this.statusCode);

  @override
  String toString() => mensaje;
}
