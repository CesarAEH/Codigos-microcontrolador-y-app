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
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'matrix_provider.dart';
import 'utils.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isSaving = false;
  File? _file;

  @override
  void initState() {
    super.initState();
    _initializeFile();
  }

  Future<void> _initializeFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/datos_continuos.txt';
    _file = File(filePath);

    // Reiniciar el archivo al inicio
    await _file!.writeAsString('');
  }

  void _startSavingData(BuildContext context) {
    setState(() {
      _isSaving = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guardado continuo iniciado')),
    );
  }

  Future<void> _exportDataToDownloads(BuildContext context) async {
    setState(() {
      _isSaving = false;
    });

    if (_file != null && await _file!.exists()) {
      final downloadsDirectory = Directory('/storage/emulated/0/Download');
      final downloadFilePath = '${downloadsDirectory.path}/datos_continuos.txt';

      await _file!.copy(downloadFilePath);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos exportados a Descargas')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos para exportar')),
      );
    }
  }

  Future<void> _saveDataContinuously(BuildContext context) async {
    if (_isSaving && _file != null) {
      final matrixProvider =
          Provider.of<MatrixProvider>(context, listen: false);
      final matrixText = convertMatrixToText(matrixProvider.matrixData);

      // Guardar los datos en el archivo
      await _file!.writeAsString('$matrixText;\n', mode: FileMode.append);

      // Continuar guardando cada segundo
      Future.delayed(const Duration(seconds: 1), () {
        if (_isSaving) {
          _saveDataContinuously(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Matriz de datos recibida (4x4):",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Consumer<MatrixProvider>(
                builder: (context, matrixProvider, child) {
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: 16,
                    itemBuilder: (context, index) {
                      int row = index ~/ 4;
                      int col = index % 4;
                      double value = matrixProvider.matrixData[row][col];

                      // Mostrar el valor exacto recibido por los sensores
                      String displayValue = value.toStringAsFixed(2);

                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.2),
                          border: Border.all(color: Colors.blueAccent),
                        ),
                        child: Text(
                          displayValue,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Consumer<MatrixProvider>(
              builder: (context, matrixProvider, child) {
                return Text(
                  "Altura promedio respecto al piso: ${matrixProvider.getAverageHeight().toStringAsFixed(2)} mm",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                );
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _startSavingData(context);
                  _saveDataContinuously(context);
                },
                child: const Text('Iniciar guardado continuo'),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _exportDataToDownloads(context);
                },
                child: const Text('Exportar datos a Descargas'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
