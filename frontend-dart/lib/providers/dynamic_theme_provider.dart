// lib/providers/dynamic_theme_provider.dart
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/app_core.dart';

class DynamicThemeProvider with ChangeNotifier {
  Color _primaryColor = AppTheme.primary;
  Color _surfaceColor = AppTheme.surface;
  Color _backgroundColor = AppTheme.background;
  bool _isExtracting = false;
  final Map<String, Color> _colorCache = {};

  Color get primaryColor => _primaryColor;
  Color get surfaceColor => _surfaceColor;
  Color get backgroundColor => _backgroundColor;
  bool get isExtracting => _isExtracting;

  ThemeData get dynamicTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: _backgroundColor,
    cardColor: _surfaceColor,
    colorScheme: ColorScheme.dark(
      primary: _primaryColor,
      surface: _surfaceColor,
      background: _backgroundColor,
      error: AppTheme.error,
      onPrimary: _getContrastColor(_primaryColor),
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _backgroundColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: _getContrastColor(_primaryColor),
        minimumSize: const Size(88, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 4,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.error, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
    ),
    cardTheme: CardThemeData(
      color: _surfaceColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );

  Future<void> extractAndApplyDominantColor(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      _resetToDefaultTheme();
      return;
    }

    if (_colorCache.containsKey(imageUrl)) {
      _applyColor(_colorCache[imageUrl]!);
      return;
    }

    _isExtracting = true;
    notifyListeners();

    try {
      final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(imageUrl),
        size: const Size(100, 100),
        maximumColorCount: 20,
      );

      Color dominantColor = _selectBestColor(paletteGenerator);
      _colorCache[imageUrl] = dominantColor;
      _applyColor(dominantColor);
    } catch (e) {
      print('Error extracting color from image: $e');
      _resetToDefaultTheme();
    }

    _isExtracting = false;
    notifyListeners();
  }

  Color _selectBestColor(PaletteGenerator paletteGenerator) {
    Color? selectedColor;

    if (paletteGenerator.dominantColor != null) {
      selectedColor = paletteGenerator.dominantColor!.color;
    } else if (paletteGenerator.vibrantColor != null) {
      selectedColor = paletteGenerator.vibrantColor!.color;
    } else if (paletteGenerator.lightVibrantColor != null) {
      selectedColor = paletteGenerator.lightVibrantColor!.color;
    } else if (paletteGenerator.darkVibrantColor != null) {
      selectedColor = paletteGenerator.darkVibrantColor!.color;
    } else if (paletteGenerator.mutedColor != null) {
      selectedColor = paletteGenerator.mutedColor!.color;
    } else if (paletteGenerator.lightMutedColor != null) {
      selectedColor = paletteGenerator.lightMutedColor!.color;
    } else if (paletteGenerator.darkMutedColor != null) {
      selectedColor = paletteGenerator.darkMutedColor!.color;
    }

    selectedColor ??= AppTheme.primary;
    return _adjustColorForDarkTheme(selectedColor);
  }

  Color _adjustColorForDarkTheme(Color color) {
    final HSLColor hslColor = HSLColor.fromColor(color);
    
    double saturation = hslColor.saturation;
    if (saturation < 0.3) {
      saturation = 0.5;
    }
    
    double lightness = hslColor.lightness;
    if (lightness < 0.4) {
      lightness = 0.5;
    } else if (lightness > 0.7) {
      lightness = 0.6;
    }

    return hslColor.withSaturation(saturation).withLightness(lightness).toColor();
  }

  void _applyColor(Color color) {
    _primaryColor = color;
    
    final HSLColor hslPrimary = HSLColor.fromColor(color);
    
    _surfaceColor = hslPrimary
        .withLightness((hslPrimary.lightness * 0.3).clamp(0.1, 0.2))
        .withSaturation((hslPrimary.saturation * 0.6).clamp(0.1, 0.8))
        .toColor();
    
    _backgroundColor = hslPrimary
        .withLightness((hslPrimary.lightness * 0.15).clamp(0.05, 0.12))
        .withSaturation((hslPrimary.saturation * 0.4).clamp(0.1, 0.6))
        .toColor();
    
    notifyListeners();
  }

  void _resetToDefaultTheme() {
    _primaryColor = AppTheme.primary;
    _surfaceColor = AppTheme.surface;
    _backgroundColor = AppTheme.background;
    notifyListeners();
  }

  Color _getContrastColor(Color backgroundColor) {
    final double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  void clearCache() {
    _colorCache.clear();
  }

  void resetTheme() {
    _resetToDefaultTheme();
  }
}
