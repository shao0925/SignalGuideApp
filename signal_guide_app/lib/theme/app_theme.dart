import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData nrtcTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00704A)),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF00704A),
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00704A),
        foregroundColor: Colors.white,
      ),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    useMaterial3: true,
  );
}
