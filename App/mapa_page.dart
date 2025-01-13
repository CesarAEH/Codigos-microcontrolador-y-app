import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  final LatLng initialCenter;

  const MapScreen({
    super.key,
    required this.initialCenter,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<LatLng> routePoints = [];
  StreamSubscription<Position>? positionStream;
  late final MapController _mapController; // Controlador del mapa

  @override
  void initState() {
    super.initState();
    _mapController = MapController(); // Inicializa el controlador de mapa
    startTracking();
  }

  void startTracking() {
    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // actualiza cada 5 metros
      ),
    ).listen((Position position) {
      setState(() {
        routePoints.add(LatLng(position.latitude, position.longitude));
      });
    });
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController, // Controlador del mapa
        options: MapOptions(
          onMapReady: () {
            // Mueve el mapa al centro inicial y configura el nivel de zoom
            _mapController.move(widget.initialCenter, 13.0);
          },
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
            additionalOptions: const {
              'accessToken':
                  'pk.eyJ1IjoiY2VzbHkxMiIsImEiOiJjbTBkNDlkb24wNXN5MmtvZXd5M3hrb3A0In0.2E-cEAMQCOaurPkXWtb6ZQ', // Reemplaza con  token que van a usar
              'id': 'mapbox/streets-v12',
            },
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: widget.initialCenter,
                width: 80,
                height: 80.0,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40.0,
                ),
              ),
            ],
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints, // Los puntos de la ruta
                strokeWidth: 4.0, // Grosor de la línea de la ruta
                color: Colors.blue, // Color de la línea de la ruta
              ),
            ],
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              setState(() {
                routePoints
                    .clear(); // Limpia los puntos de ruta si deseas reiniciar el seguimiento
              });
            },
            backgroundColor: Colors.redAccent,
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
