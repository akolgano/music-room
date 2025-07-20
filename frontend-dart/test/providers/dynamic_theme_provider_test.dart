import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:music_room/providers/dynamic_theme_provider.dart';
import 'package:music_room/core/theme_utils.dart';

void main() {
  group('Dynamic Theme Provider Tests', () {
    late DynamicThemeProvider themeProvider;

    setUp(() {
      themeProvider = DynamicThemeProvider();
    });

    test('DynamicThemeProvider should extend ChangeNotifier', () {
      print('Testing: DynamicThemeProvider should extend ChangeNotifier');
      expect(themeProvider, isA<ChangeNotifier>());
    });

    test('DynamicThemeProvider should have initial default colors', () {
      print('Testing: DynamicThemeProvider should have initial default colors');
      expect(themeProvider.primaryColor, AppTheme.primary);
      expect(themeProvider.surfaceColor, AppTheme.surface);
      expect(themeProvider.backgroundColor, AppTheme.background);
      expect(themeProvider.onPrimaryColor, Colors.black);
      expect(themeProvider.onSurfaceColor, Colors.white);
      expect(themeProvider.accentColor, AppTheme.primary);
    });

    test('DynamicThemeProvider should provide extraction state', () {
      print('Testing: DynamicThemeProvider should provide extraction state');
      expect(themeProvider.isExtracting, false);
      expect(themeProvider.currentImageUrl, null);
    });

    test('DynamicThemeProvider should generate dynamic theme', () {
      print('Testing: DynamicThemeProvider should generate dynamic theme');
      final theme = themeProvider.dynamicTheme;
      
      expect(theme, isA<ThemeData>());
      expect(theme.useMaterial3, true);
      expect(theme.brightness, Brightness.dark);
      expect(theme.primaryColor, themeProvider.primaryColor);
      expect(theme.scaffoldBackgroundColor, themeProvider.backgroundColor);
    });

    test('DynamicThemeProvider should handle custom color setting', () {
      print('Testing: DynamicThemeProvider should handle custom color setting');
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
      print('Testing: DynamicThemeProvider should reset theme to defaults');
      themeProvider.setCustomColors(primary: Colors.red);
      expect(themeProvider.primaryColor, Colors.red);
      
      themeProvider.resetTheme();
      expect(themeProvider.primaryColor, AppTheme.primary);
      expect(themeProvider.currentImageUrl, null);
    });

    test('DynamicThemeProvider should provide current colors map', () {
      print('Testing: DynamicThemeProvider should provide current colors map');
      final colors = themeProvider.currentColors;
      
      expect(colors, isA<Map<String, Color>>());
      expect(colors.containsKey('primary'), true);
      expect(colors.containsKey('surface'), true);
      expect(colors.containsKey('background'), true);
      expect(colors.containsKey('accent'), true);
      expect(colors.containsKey('onPrimary'), true);
      expect(colors.containsKey('onSurface'), true);
    });

    test('DynamicThemeProvider should clear color cache', () {
      print('Testing: DynamicThemeProvider should clear color cache');
      themeProvider.clearCache();
      expect(themeProvider, isNotNull);
    });

    test('DynamicThemeProvider should handle null image URL extraction', () async {
      print('Testing: DynamicThemeProvider should handle null image URL extraction');
      await themeProvider.extractAndApplyDominantColor(null);
      expect(themeProvider.primaryColor, AppTheme.primary);
      expect(themeProvider.currentImageUrl, null);
    });

    test('DynamicThemeProvider should handle empty image URL extraction', () async {
      print('Testing: DynamicThemeProvider should handle empty image URL extraction');
      await themeProvider.extractAndApplyDominantColor('');
      expect(themeProvider.primaryColor, AppTheme.primary);
      expect(themeProvider.currentImageUrl, null);
    });
  });
}