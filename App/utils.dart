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
