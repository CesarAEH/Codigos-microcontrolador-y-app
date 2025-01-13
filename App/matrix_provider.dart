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

import 'package:flutter/material.dart';

class MatrixProvider with ChangeNotifier {
  List<List<double>> matrixData = List.generate(8, (_) => List.filled(8, 0.0));
  double averageHeight = 0.0;

  // Método para actualizar los datos de la matriz
  void updateMatrixData(List<List<double>> newData) {
    matrixData = newData;
    _calculateAverageHeight(); // Calcular el promedio cuando se actualizan los datos
    notifyListeners();
  }

  // Método para calcular el promedio de la altura
  void _calculateAverageHeight() {
    double totalHeight = 0.0;
    int count = 0;

    for (var row in matrixData) {
      for (var value in row) {
        totalHeight += value;
        count++;
      }
    }

    averageHeight = count > 0 ? totalHeight / count : 0.0;
  }

  // Método para actualizar el promedio de altura
  void updateAverageHeight(double newAverageHeight) {
    averageHeight = newAverageHeight;
    notifyListeners();
  }

  // Obtener el promedio de altura
  double getAverageHeight() {
    return averageHeight;
  }
}
