import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/mapa_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const SalonMapaApp());
}

class SalonMapaApp extends StatelessWidget {
  const SalonMapaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salones Cercanos',
      theme: AppTheme.tema,
      debugShowCheckedModeBanner: false,
      home: const MapaScreen(),
    );
  }
}
