// lib/core/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF1DB954);
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF282828);
  static const surfaceVariant = Color(0xFF333333);
  static const onSurface = Color(0xFFFFFFFF);
  static const onSurfaceVariant = Color(0xFFB3B3B3);
  static const error = Color(0xFFE91429);
  static const success = Color(0xFF00C851);
  static const warning = Color(0xFFFF9F00);
  static const info = Color(0xFF2196F3);
  
  static const textPrimary = onSurface;
  static const textSecondary = onSurfaceVariant;
  static Color get textDisabled => onSurface.withOpacity(0.5);
  static Color get textSubtle => onSurface.withOpacity(0.7);

  static List<BoxShadow> get defaultShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get lightShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    cardColor: surface,
    
    colorScheme: const ColorScheme.dark(
      primary: primary,
      surface: surface,
      background: background,
      error: error,
      onPrimary: Colors.white,
      onSurface: onSurface,
      onBackground: Colors.white,
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        minimumSize: const Size(88, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 4,
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      labelStyle: const TextStyle(color: onSurfaceVariant),
      hintStyle: TextStyle(color: onSurface.withOpacity(0.6)),
    ),
    
    cardTheme: CardThemeData(
      color: surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );

  static ButtonStyle get fullWidthButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.black,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25),
    ),
    elevation: 4,
  );

  static ButtonStyle get dangerButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: error,
    foregroundColor: Colors.white,
    minimumSize: const Size(88, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25),
    ),
    elevation: 4,
  );
}
