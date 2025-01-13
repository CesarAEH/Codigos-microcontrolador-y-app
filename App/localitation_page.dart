// Este código utiliza dependencias bajo las siguientes licencias de código abierto:
// - Licencia BSD (Flutter): Permite su uso, modificación y distribución siempre que se mantenga la licencia original.
// - Licencia Apache 2.0 (latlong2): Permite el uso, distribución y modificación con ciertas condiciones como la atribución.
// - Licencia MIT (Google Nav Bar, path_provider): Permite el uso, modificación y distribución sin restricciones adicionales.
//
// Por favor, consulta los términos específicos de cada licencia para más detalles:
// Flutter: https://github.com/flutter/flutter/blob/master/LICENSE
// Latlong2: https://pub.dev/packages/latlong2/license
// Google Nav Bar: https://pub.dev/packages/google_nav_bar/license
// Path Provider: https://pub.dev/packages/path_provider/license
//

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  Future<LatLng> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica si los servicios de ubicación están habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Los servicios de ubicación están deshabilitados.');
    }

    // Verifica el permiso de ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Los permisos de ubicación están denegados.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Maneja el caso en el que los permisos están permanentemente denegados
      return Future.error(
          'Los permisos de ubicación están permanentemente denegados, no podemos solicitar permisos.');
    }

    // Obtiene la posición actual y la convierte a LatLng
    Position position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }
}
