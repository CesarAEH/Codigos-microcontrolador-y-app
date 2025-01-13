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
import 'package:geolocator_app/charts_page.dart';
import 'package:geolocator_app/mapa_page.dart';
import 'package:geolocator_app/firebase_page.dart';
import 'package:geolocator_app/profile_page.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'utils.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator_app/localitation_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  LatLng? initialCenter;
  bool showMap = false;
  late LocationService _locationService;
  List<String> logData = [];
  String? fileContent;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    _readDataFromFile();
  }

  // Función para leer el contenido del archivo de registro
  Future<void> _readDataFromFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/registro_datos.txt';
    final file = File(filePath);

    if (await file.exists()) {
      String content = await file.readAsString();
      setState(() {
        fileContent = content;
      });
    } else {
      setState(() {
        fileContent = 'No hay datos guardados aún.';
      });
    }
  }

  // Función para obtener la ubicación actual y mostrar el mapa
  void _getCurrentLocationAndShowMap() async {
    final position = await getCurrentLocation(context, _locationService);
    if (position != null) {
      setState(() {
        initialCenter = position;
        showMap = true;
        logData.add("Ubicación obtenida: $position");
      });
    }
  }

  // Función para exportar el archivo de la matriz a Descargas
  Future<void> _exportMatrixDataToDownloads(BuildContext context) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/matriz_datos.txt';
    final file = File(filePath);

    if (await file.exists()) {
      final downloadsDirectory = Directory('/storage/emulated/0/Download');
      final downloadFilePath = '${downloadsDirectory.path}/matriz_datos.txt';

      await file.copy(downloadFilePath);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Datos de la matriz exportados a Descargas')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos para exportar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lista de pantallas para la navegación
    final List<Widget> _screens = [
      const ChartsPage(),
      const FirebasePage(),
      showMap && initialCenter != null
          ? Column(
              children: [
                Expanded(
                  child: MapScreen(initialCenter: initialCenter!),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showMap = false;
                    });
                  },
                  child: const Text('Reiniciar mapa'),
                ),
              ],
            )
          : Center(
              child: ElevatedButton(
                onPressed: _getCurrentLocationAndShowMap,
                child: const Text('Obtener mapa'),
              ),
            ),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Aplicación de Mapas"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: GNav(
        gap: 8,
        backgroundColor: Colors.white,
        color: Colors.black,
        activeColor: Colors.white,
        tabBackgroundColor: Colors.blueAccent,
        padding: const EdgeInsets.all(16),
        selectedIndex: _currentIndex,
        onTabChange: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        tabs: const [
          GButton(icon: Icons.home, text: 'Home'),
          GButton(icon: Icons.info, text: 'Firebase'),
          GButton(icon: Icons.map, text: 'Map'),
          GButton(icon: Icons.person, text: 'Profile'),
        ],
      ),
    );
  }
}
