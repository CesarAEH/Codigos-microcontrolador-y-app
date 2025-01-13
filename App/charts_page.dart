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
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class ChartsPage extends StatefulWidget {
  const ChartsPage({Key? key}) : super(key: key);

  @override
  _ChartsPageState createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage>
    with AutomaticKeepAliveClientMixin {
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
  double temperature = 0.0; // Inicialización con valor predeterminado
  double humidity = 0.0; // Inicialización con valor predeterminado
  List<FlSpot> temperatureData = [];
  List<FlSpot> humidityData = [];
  int timestamp = 0;
  late DatabaseReference tempyHumRef;
  late StreamSubscription<DatabaseEvent> tempyHumSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    tempyHumRef = databaseReference.child('TempyHum');
    _listenToFirebase();
  }

  void _listenToFirebase() async {
    tempyHumSubscription = tempyHumRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          // Validación para evitar NullException si los valores no existen en Firebase
          temperature = (data['temperature'] as num?)?.toDouble() ?? 0.0;
          humidity = (data['humidity'] as num?)?.toDouble() ?? 0.0;

          temperatureData.add(FlSpot(timestamp.toDouble(), temperature));
          humidityData.add(FlSpot(timestamp.toDouble(), humidity));

          // Imprime los datos recibidos para depuración
          print(
              'Data received - Temperature: $temperature, Humidity: $humidity');

          if (temperatureData.length > 100) {
            temperatureData.removeAt(0);
          }
          if (humidityData.length > 100) {
            humidityData.removeAt(0);
          }

          timestamp++;
        });
      } else {
        print("No data received from Firebase.");
      }
    });
  }

  void _resetCharts() {
    setState(() {
      temperatureData.clear();
      humidityData.clear();
      timestamp = 0;
    });
  }

  @override
  void dispose() {
    tempyHumSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráficos de Temperatura y Humedad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCharts,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                'Temperature: ${temperature.toStringAsFixed(2)} °C',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              temperatureData.isNotEmpty
                  ? _buildLineChart(
                      temperatureData, Colors.red, 'Temperatura (°C)')
                  : const Text('Cargando datos...'),
              const SizedBox(height: 20),
              Text(
                'Humidity: ${humidity.toStringAsFixed(2)} %',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              humidityData.isNotEmpty
                  ? _buildLineChart(humidityData, Colors.blue, 'Humedad (%)')
                  : const Text('Cargando humedad...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<FlSpot> data, Color color, String label) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 250,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 5,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                isCurved: false, // Desactiva la curva para mejorar rendimiento
                spots: data,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.3),
                      color.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
