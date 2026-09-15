import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'services/database_service.dart';

void main() async {

  // 1. Asegura que Flutter esté listo
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Enciende la base de datos
  await DatabaseService.initialize();
  
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Gastos',
      debugShowCheckedModeBanner: false, // Oculta la etiqueta de "DEBUG"
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF6F6F6), // Fondo de tu paleta
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}