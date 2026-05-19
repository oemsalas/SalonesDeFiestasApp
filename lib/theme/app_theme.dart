import 'package:flutter/material.dart';

class AppTheme {
  // Paleta principal: dorado elegante sobre oscuro
  static const Color fondoOscuro = Color(0xFF0F0E17);
  static const Color fondoTarjeta = Color(0xFF1A1925);
  static const Color fondoSuperficie = Color(0xFF252336);
  static const Color dorado = Color(0xFFE8B94F);
  static const Color doradoClaro = Color(0xFFF5D48A);
  static const Color doradoOscuro = Color(0xFFA87C2A);
  static const Color acento = Color(0xFFFF6B6B);
  static const Color acentoVerde = Color(0xFF4ECDC4);
  static const Color textoClaro = Color(0xFFF2EFE9);
  static const Color textoSecundario = Color(0xFF9B98AD);
  static const Color borde = Color(0xFF2E2B3F);

  static ThemeData get tema => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: fondoOscuro,
        colorScheme: const ColorScheme.dark(
          primary: dorado,
          secondary: acentoVerde,
          surface: fondoTarjeta,
          error: acento,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: fondoOscuro,
          foregroundColor: textoClaro,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textoClaro,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: fondoTarjeta,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: borde, width: 1),
          ),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: dorado,
          inactiveTrackColor: borde,
          thumbColor: dorado,
          overlayColor: Color(0x33E8B94F),
          valueIndicatorColor: dorado,
          valueIndicatorTextStyle: TextStyle(color: fondoOscuro),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: dorado,
            foregroundColor: fondoOscuro,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: fondoSuperficie,
          selectedColor: dorado.withOpacity(0.2),
          side: const BorderSide(color: borde),
          labelStyle: const TextStyle(color: textoClaro, fontSize: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      );
}
