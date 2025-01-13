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

import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:geolocator_app/localitation_page.dart';

// Función para convertir la matriz a texto
String convertMatrixToText(List<List<double>> matrixData) {
  List<String> lines = [];
  for (List<double> row in matrixData) {
    lines.add(row.map((e) => e.toStringAsFixed(2)).join(', '));
  }
  return lines.join('\n');
}

// Función para obtener la ubicación actual
Future<LatLng?> getCurrentLocation(
    BuildContext context, LocationService locationService) async {
  try {
    print("Obteniendo ubicación...");
    LatLng position = await locationService.determinePosition();
    print("Ubicación obtenida: $position");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Ubicación obtenida: $position")),
    );
    return position;
  } catch (e) {
    print('Error al obtener la ubicación: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al obtener la ubicación: $e')),
    );
    return null;
  }
}
