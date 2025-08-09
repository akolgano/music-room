import '../core/navigation_core.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme_core.dart';

class DynamicThemeProvider with ChangeNotifier {
  Color _primaryColor = AppTheme.primary;
  Color _surfaceColor = AppTheme.surface;
  Color _backgroundColor = AppTheme.background;
  Color _onPrimaryColor = Colors.black;
  Color _onSurfaceColor = Colors.white;
  Color _accentColor = AppTheme.primary;
  
  bool _isExtracting = false;
  String? _currentImageUrl;
  final Map<String, ColorScheme> _colorCache = {};

  Color get primaryColor => _primaryColor;
  Color get surfaceColor => _surfaceColor;
  Color get backgroundColor => _backgroundColor;
  Color get onPrimaryColor => _onPrimaryColor;
  Color get onSurfaceColor => _onSurfaceColor;
  Color get accentColor => _accentColor;
  bool get isExtracting => _isExtracting;
  String? get currentImageUrl => _currentImageUrl;

  ThemeData get dynamicTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: _backgroundColor,
    cardColor: _surfaceColor,
    
    colorScheme: ColorScheme.dark(
      primary: _primaryColor,
      secondary: _accentColor,
      surface: _surfaceColor,
      error: AppTheme.error,
      onPrimary: _onPrimaryColor,
      onSecondary: _getContrastColor(_accentColor),
      onSurface: _onSurfaceColor,
      onError: Colors.white,
      primaryContainer: _primaryColor.withValues(alpha: 0.3),
      secondaryContainer: _accentColor.withValues(alpha: 0.3),
      surfaceContainerHighest: _surfaceColor.withValues(alpha: 0.8),
      outline: _primaryColor.withValues(alpha: 0.5),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: _backgroundColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: _primaryColor),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: _onPrimaryColor,
        minimumSize: const Size(88, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 4,
        shadowColor: _primaryColor.withValues(alpha: 0.3),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: _primaryColor),
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
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
    ),

    cardTheme: CardThemeData(
      color: _surfaceColor,
      elevation: 4,
      shadowColor: _primaryColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    iconTheme: IconThemeData(color: _primaryColor),
    primaryIconTheme: IconThemeData(color: _onPrimaryColor),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: _onPrimaryColor,
      elevation: 6,
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _surfaceColor,
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.white60,
      type: BottomNavigationBarType.fixed,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: _primaryColor,
      unselectedLabelColor: Colors.white70,
      indicatorColor: _primaryColor,
      indicatorSize: TabBarIndicatorSize.tab,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _primaryColor;
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _primaryColor.withValues(alpha: 0.5);
        return Colors.grey.withValues(alpha: 0.3);
      }),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _primaryColor;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(_onPrimaryColor),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: _primaryColor,
      inactiveTrackColor: _primaryColor.withValues(alpha: 0.3),
      thumbColor: _primaryColor,
      overlayColor: _primaryColor.withValues(alpha: 0.2),
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: _primaryColor,
      linearTrackColor: _primaryColor.withValues(alpha: 0.3),
      circularTrackColor: _primaryColor.withValues(alpha: 0.3),
    ),

    dividerTheme: DividerThemeData(
      color: _surfaceColor,
      thickness: 1,
    ),

    listTileTheme: ListTileThemeData(
      textColor: Colors.white,
      iconColor: _primaryColor,
      selectedColor: _primaryColor,
      selectedTileColor: _primaryColor.withValues(alpha: 0.1),
    ),
  );

  Future<void> extractAndApplyDominantColor(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      _resetToDefaultTheme();
      return;
    }

    if (_currentImageUrl == imageUrl && _colorCache.containsKey(imageUrl)) {
      _applyColorScheme(_colorCache[imageUrl]!);
      return;
    }

    _isExtracting = true;
    _currentImageUrl = imageUrl;
    notifyListeners();

    try {
      final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(imageUrl),
        size: const Size(100, 100),
        maximumColorCount: 32, 
      );

      final colorScheme = _generateColorScheme(paletteGenerator);
      _colorCache[imageUrl] = colorScheme;
      _applyColorScheme(colorScheme);
    } catch (e) {
      AppLogger.error('Error extracting color from image: ${e.toString()}', null, null, 'DynamicThemeProvider');
      _resetToDefaultTheme();
    }

    _isExtracting = false;
    notifyListeners();
  }

  ColorScheme _generateColorScheme(PaletteGenerator paletteGenerator) {
    Color primary = _selectBestColor(paletteGenerator);
    primary = _adjustColorForDarkTheme(primary);

    final HSLColor hslPrimary = HSLColor.fromColor(primary);
    
    final Color accent = _generateAccentColor(hslPrimary);
    final Color surface = _generateSurfaceColor(hslPrimary);

    return ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: surface,
      error: AppTheme.error,
      onPrimary: _getContrastColor(primary),
      onSecondary: _getContrastColor(accent),
      onSurface: Colors.white,
    );
  }

  void _applyColorScheme(ColorScheme colorScheme) {
    _primaryColor = colorScheme.primary;
    _accentColor = colorScheme.secondary;
    _surfaceColor = colorScheme.surface;
    _backgroundColor = colorScheme.surface;
    _onPrimaryColor = colorScheme.onPrimary;
    _onSurfaceColor = colorScheme.onSurface;
    notifyListeners();
  }

  Color _selectBestColor(PaletteGenerator paletteGenerator) {
    final colorCandidates = [
      paletteGenerator.vibrantColor?.color,
      paletteGenerator.lightVibrantColor?.color,
      paletteGenerator.darkVibrantColor?.color,
      paletteGenerator.dominantColor?.color,
      paletteGenerator.mutedColor?.color,
      paletteGenerator.lightMutedColor?.color,
      paletteGenerator.darkMutedColor?.color,
    ];

    for (final color in colorCandidates) {
      if (color != null && _isColorSuitable(color)) {
        return color;
      }
    }

    return AppTheme.primary; 
  }

  bool _isColorSuitable(Color color) {
    final HSLColor hsl = HSLColor.fromColor(color);
    return hsl.saturation >= 0.2 && 
           hsl.lightness >= 0.2 && 
           hsl.lightness <= 0.8;
  }

  Color _adjustColorForDarkTheme(Color color) {
    final HSLColor hslColor = HSLColor.fromColor(color);
    
    double saturation = hslColor.saturation;
    if (saturation < 0.4) {
      saturation = 0.6;
    }
    if (saturation > 0.9) {
      saturation = 0.8;
    }

    double lightness = hslColor.lightness;
    if (lightness < 0.4) {
      lightness = 0.5;
    } else if (lightness > 0.7) {
      lightness = 0.6;
    }

    return hslColor
        .withSaturation(saturation)
        .withLightness(lightness)
        .toColor();
  }

  Color _generateAccentColor(HSLColor primaryHsl) {
    double accentHue = (primaryHsl.hue + 180) % 360;
    return primaryHsl
        .withHue(accentHue)
        .withSaturation((primaryHsl.saturation * 0.8).clamp(0.3, 0.9))
        .withLightness((primaryHsl.lightness * 0.9).clamp(0.4, 0.7))
        .toColor();
  }

  Color _generateSurfaceColor(HSLColor primaryHsl) {
    return primaryHsl
        .withLightness((primaryHsl.lightness * 0.2).clamp(0.08, 0.15))
        .withSaturation((primaryHsl.saturation * 0.6).clamp(0.1, 0.8))
        .toColor();
  }

  void _resetToDefaultTheme() {
    _primaryColor = AppTheme.primary;
    _surfaceColor = AppTheme.surface;
    _backgroundColor = AppTheme.background;
    _accentColor = AppTheme.primary;
    _onPrimaryColor = Colors.black;
    _onSurfaceColor = Colors.white;
    _currentImageUrl = null;
    notifyListeners();
  }

  Color _getContrastColor(Color backgroundColor) {
    final double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  void setCustomColors({Color? primary, Color? surface, Color? background, Color? accent}) {
    if (primary != null) _primaryColor = primary;
    if (surface != null) _surfaceColor = surface;
    if (background != null) _backgroundColor = background;
    if (accent != null) _accentColor = accent;
    _onPrimaryColor = _getContrastColor(_primaryColor);
    _onSurfaceColor = _getContrastColor(_surfaceColor);
    notifyListeners();
  }

  void clearCache() {
    _colorCache.clear();
  }

  void resetTheme() {
    _resetToDefaultTheme();
  }

  Map<String, Color> get currentColors => {
    'primary': _primaryColor,
    'surface': _surfaceColor,
    'background': _backgroundColor,
    'accent': _accentColor,
    'onPrimary': _onPrimaryColor,
    'onSurface': _onSurfaceColor,
  };
}
