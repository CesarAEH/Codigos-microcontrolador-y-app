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
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'package:provider/provider.dart';
import 'matrix_provider.dart';

// Variable global para almacenar los datos de la matriz 4x4
List<List<double>> globalMatrixData =
    List.generate(4, (_) => List.filled(4, 0.0));

class FirebasePage extends StatefulWidget {
  const FirebasePage({super.key});

  @override
  _FirebasePageState createState() => _FirebasePageState();
}

class _FirebasePageState extends State<FirebasePage> {
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
  late Scene _scene;
  List<Object> objectsInScene = [];
  double adjustedAverageHeight = 0.0; // Altura promedio

  @override
  void initState() {
    super.initState();
    _listenToFirebase();
  }

  void _listenToFirebase() {
    databaseReference.child('sensors').onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        Map data = Map.from(event.snapshot.value as Map);

        // Crear una matriz 4x4
        List<List<double>> updatedMatrixData =
            List.generate(4, (_) => List.filled(4, 0.0));

        try {
          // Definir la altura del sensor en milímetros
          const double sensorHeightInMm = 1020.0;

          // Llenar la matriz 4x4 con las alturas relativas al piso
          for (int y = 0; y < 4; y++) {
            for (int x = 0; x < 4; x++) {
              if (data.containsKey('distance${y * 4 + x}')) {
                double measuredDistance =
                    (data['distance${y * 4 + x}'] as num).toDouble();

                // Altura relativa al piso (altura del sensor menos distancia medida)
                double relativeHeight = sensorHeightInMm - measuredDistance;

                // Asegurar que no haya valores negativos
                updatedMatrixData[y][x] =
                    relativeHeight > 0 ? relativeHeight : 0.0;
              }
            }
          }

          double totalHeight = 0.0;
          int validValuesCount = 0;
          for (var row in updatedMatrixData) {
            for (var value in row) {
              if (value > 1.0) {
                totalHeight += value;
                validValuesCount++;
              }
            }
          }

          // Evitar división por cero
          double averageHeight =
              validValuesCount > 0 ? totalHeight / validValuesCount : 0.0;

          // Altura promedio ajustada
          adjustedAverageHeight = averageHeight * 0.1;

          // Actualizar el estado global de la matriz y el promedio
          final matrixProvider =
              Provider.of<MatrixProvider>(context, listen: false);
          matrixProvider.updateMatrixData(updatedMatrixData);
          matrixProvider.updateAverageHeight(averageHeight);

          setState(() {
            globalMatrixData = updatedMatrixData;
            _update3DMap();
          });
        } catch (e) {
          print('Error al procesar los datos: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa 3D de Distancia (4x4)'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Altura promedio respecto al piso: ${adjustedAverageHeight.toStringAsFixed(2)} cm",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Center(
              child: SizedBox(
                height: 400,
                child: Cube(
                  onSceneCreated: (Scene scene) {
                    _scene = scene;
                    _update3DMap();
                    _scene.camera.position.z = 80;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _update3DMap() {
    for (var object in objectsInScene) {
      _scene.world.remove(object);
    }
    objectsInScene.clear();

    final Object map3D = create3DMap(globalMatrixData);
    _scene.world.add(map3D);
    objectsInScene.add(map3D);
  }

  Object create3DMap(List<List<double>> matrixData) {
    final Object map3D = Object();
    const double cubeSize = 10.0;
    const double minCubeHeight = 0.1; // Altura mínima para graficar (en cm)

    for (int y = 0; y < matrixData.length; y++) {
      for (int x = 0; x < matrixData[y].length; x++) {
        double height = matrixData[y][x] / 10.0; // Convertir de mm a cm
        if (height < minCubeHeight) {
          height = minCubeHeight;
        }

        String fileName;
        if (height > 15) {
          fileName = 'assets/cubo/cubo_azul.obj'; // Altura alta
        } else if (height > 10) {
          fileName = 'assets/cubo/cubo_verde.obj'; // Altura media
        } else if (height > 5) {
          fileName = 'assets/cubo/cubo_amarillo.obj'; // Altura baja
        } else {
          fileName = 'assets/cubo/cubo_rojo.obj'; // Muy baja
        }

        final Object cube = Object(
          scale: Vector3(cubeSize, height, cubeSize),
          position:
              Vector3(x * (cubeSize + 1.0), height / 2, y * (cubeSize + 1.0)),
          fileName: fileName,
        );

        map3D.add(cube);
      }
    }

    return map3D;
  }
}
