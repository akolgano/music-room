import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:music_room/providers/theme_providers.dart';
import 'package:music_room/core/theme_core.dart';
void main() {
  group('Dynamic Theme Provider Tests', () {
    late DynamicThemeProvider themeProvider;
    setUp(() {
      themeProvider = DynamicThemeProvider();
    });
    test('DynamicThemeProvider should extend ChangeNotifier', () {
      expect(themeProvider, isA<ChangeNotifier>());
    });
    test('DynamicThemeProvider should have initial default colors', () {
      expect(themeProvider.primaryColor, AppTheme.primary);
      expect(themeProvider.surfaceColor, AppTheme.surface);
      expect(themeProvider.backgroundColor, AppTheme.background);
      expect(themeProvider.onPrimaryColor, Colors.black);
      expect(themeProvider.onSurfaceColor, Colors.white);
      expect(themeProvider.accentColor, AppTheme.primary);
    });
    test('DynamicThemeProvider should provide extraction state', () {
      expect(themeProvider.isExtracting, false);
      expect(themeProvider.currentImageUrl, null);
    });
    test('DynamicThemeProvider should generate dynamic theme', () {
      final theme = themeProvider.dynamicTheme;
      
      expect(theme, isA<ThemeData>());
      expect(theme.useMaterial3, true);
      expect(theme.brightness, Brightness.dark);
      expect(theme.primaryColor, themeProvider.primaryColor);
      expect(theme.scaffoldBackgroundColor, themeProvider.backgroundColor);
    });
    test('DynamicThemeProvider should handle custom color setting', () {
      const customPrimary = Colors.blue;
      const customSurface = Colors.grey;
      const customBackground = Colors.black87;
      const customAccent = Colors.lightBlue;
      
      themeProvider.setCustomColors(
        primary: customPrimary,
        surface: customSurface,
        background: customBackground,
        accent: customAccent,
      );
      
      expect(themeProvider.primaryColor, customPrimary);
      expect(themeProvider.surfaceColor, customSurface);
      expect(themeProvider.backgroundColor, customBackground);
      expect(themeProvider.accentColor, customAccent);
    });
    test('DynamicThemeProvider should reset theme to defaults', () {
      themeProvider.setCustomColors(primary: Colors.red);
      expect(themeProvider.primaryColor, Colors.red);
      
      themeProvider.resetTheme();
      expect(themeProvider.primaryColor, AppTheme.primary);
      expect(themeProvider.currentImageUrl, null);
    });
    test('DynamicThemeProvider should provide color properties', () {
      expect(themeProvider.primaryColor, isA<Color>());
      expect(themeProvider.surfaceColor, isA<Color>());
      expect(themeProvider.backgroundColor, isA<Color>());
      expect(themeProvider.accentColor, isA<Color>());
      expect(themeProvider.onPrimaryColor, isA<Color>());
      expect(themeProvider.onSurfaceColor, isA<Color>());
    });
    test('DynamicThemeProvider should clear color cache', () {
      themeProvider.clearCache();
      expect(themeProvider, isNotNull);
    });
    test('DynamicThemeProvider should handle null image URL extraction', () async {
      await themeProvider.extractAndApplyDominantColor(null);
      expect(themeProvider.primaryColor, AppTheme.primary);
      expect(themeProvider.currentImageUrl, null);
    });
    test('DynamicThemeProvider should handle empty image URL extraction', () async {
      await themeProvider.extractAndApplyDominantColor('');
      expect(themeProvider.primaryColor, AppTheme.primary);
      expect(themeProvider.currentImageUrl, null);
    });
  });
}