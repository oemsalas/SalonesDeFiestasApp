import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  /// Retorna la posición actual del dispositivo.
  /// Lanza [LocationException] si no se puede obtener.
  static Future<LatLng> obtenerPosicionActual() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'El servicio de ubicación está desactivado. '
        'Por favor activalo en la configuración del dispositivo.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          'Permiso de ubicación denegado. '
          'La app necesita acceso a tu ubicación para mostrar salones cercanos.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Permiso de ubicación denegado permanentemente. '
        'Por favor habilitalo desde Configuración → Apps → Salon Mapa.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      throw LocationException('No se pudo obtener la ubicación: $e');
    }
  }

  /// Calcula la distancia en km entre dos puntos
  static double calcularDistanciaKm(LatLng desde, LatLng hasta) {
    const Distance distance = Distance();
    final metros = distance.as(LengthUnit.Meter, desde, hasta);
    return metros / 1000;
  }
}

class LocationException implements Exception {
  final String mensaje;
  LocationException(this.mensaje);

  @override
  String toString() => mensaje;
}
