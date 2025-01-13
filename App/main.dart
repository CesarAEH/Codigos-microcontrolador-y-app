import 'package:flutter/material.dart';
import 'package:geolocator_app/home_page.dart';
import 'package:firebase_core/firebase_core.dart'; // Importar Firebase
import 'package:provider/provider.dart'; // Importar Provider
import 'matrix_provider.dart'; // Importar MatrixProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Inicializar Firebase
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MatrixProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Material App',
      debugShowCheckedModeBanner: false,
      home: HomePage(), // Pantalla principal que contiene las demás páginas
    );
  }
}
