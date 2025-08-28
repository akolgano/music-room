import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/providers/theme_providers.dart';
import 'package:music_room/core/theme_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('DynamicThemeProvider', () {
    late DynamicThemeProvider provider;

    setUp(() {
      provider = DynamicThemeProvider();
    });

    test('should initialize with default theme colors', () {
      expect(provider.primaryColor, equals(AppTheme.primary));
      expect(provider.surfaceColor, equals(AppTheme.surface));
      expect(provider.backgroundColor, equals(AppTheme.background));
      expect(provider.onPrimaryColor, equals(Colors.black));
      expect(provider.onSurfaceColor, equals(Colors.white));
      expect(provider.accentColor, equals(AppTheme.primary));
      expect(provider.isExtracting, isFalse);
      expect(provider.currentImageUrl, isNull);
    });

    test('should generate proper dynamic theme data', () {
      final themeData = provider.dynamicTheme;
      
      expect(themeData.useMaterial3, isTrue);
      expect(themeData.brightness, equals(Brightness.dark));
      expect(themeData.primaryColor, equals(provider.primaryColor));
      expect(themeData.scaffoldBackgroundColor, equals(provider.backgroundColor));
      expect(themeData.cardColor, equals(provider.surfaceColor));
    });

    test('should reset theme to defaults', () {
      provider.setCustomColors(
        primary: Colors.red,
        surface: Colors.blue,
        background: Colors.green,
        accent: Colors.yellow,
      );

      provider.resetTheme();

      expect(provider.primaryColor, equals(AppTheme.primary));
      expect(provider.surfaceColor, equals(AppTheme.surface));
      expect(provider.backgroundColor, equals(AppTheme.background));
      expect(provider.accentColor, equals(AppTheme.primary));
      expect(provider.onPrimaryColor, equals(Colors.black));
      expect(provider.onSurfaceColor, equals(Colors.white));
      expect(provider.currentImageUrl, isNull);
    });

    test('should set custom colors correctly', () {
      const customPrimary = Colors.red;
      const customSurface = Colors.blue;
      const customBackground = Colors.green;
      const customAccent = Colors.yellow;

      provider.setCustomColors(
        primary: customPrimary,
        surface: customSurface,
        background: customBackground,
        accent: customAccent,
      );

      expect(provider.primaryColor, equals(customPrimary));
      expect(provider.surfaceColor, equals(customSurface));
      expect(provider.backgroundColor, equals(customBackground));
      expect(provider.accentColor, equals(customAccent));
    });

    test('should calculate contrast colors correctly', () {
      provider.setCustomColors(primary: Colors.white);
      expect(provider.onPrimaryColor, equals(Colors.black));

      provider.setCustomColors(primary: Colors.black);
      expect(provider.onPrimaryColor, equals(Colors.white));
    });

    test('should clear color cache', () {
      provider.clearCache();
      expect(() => provider.clearCache(), returnsNormally);
    });

    test('should handle null/empty image URL in extractAndApplyDominantColor', () async {
      await provider.extractAndApplyDominantColor(null);
      expect(provider.primaryColor, equals(AppTheme.primary));

      await provider.extractAndApplyDominantColor('');
      expect(provider.primaryColor, equals(AppTheme.primary));
    });

    test('should update isExtracting state during color extraction', () async {
      bool wasExtracting = false;
      
      provider.addListener(() {
        if (provider.isExtracting) {
          wasExtracting = true;
        }
      });

      try {
        await provider.extractAndApplyDominantColor('https://invalid-url.com/image.jpg');
      } catch (e) {
        // Expected to throw exception for invalid URL
      }

      expect(provider.isExtracting, isFalse);
      expect(wasExtracting, isTrue);
    });

    group('Color suitability tests', () {
      test('should identify suitable colors', () {
        provider.setCustomColors(primary: const Color(0xFF808080));
        expect(provider.primaryColor, isNotNull);
      });
    });

    group('Theme data components', () {
      test('should have properly configured app bar theme', () {
        final themeData = provider.dynamicTheme;
        final appBarTheme = themeData.appBarTheme;

        expect(appBarTheme.backgroundColor, equals(provider.backgroundColor));
        expect(appBarTheme.foregroundColor, equals(Colors.white));
        expect(appBarTheme.elevation, equals(0));
        expect(appBarTheme.centerTitle, isFalse);
      });

      test('should have properly configured button themes', () {
        final themeData = provider.dynamicTheme;

        final elevatedButtonStyle = themeData.elevatedButtonTheme.style;
        expect(elevatedButtonStyle, isNotNull);

        final textButtonStyle = themeData.textButtonTheme.style;
        expect(textButtonStyle, isNotNull);

        final outlinedButtonStyle = themeData.outlinedButtonTheme.style;
        expect(outlinedButtonStyle, isNotNull);
      });

      test('should have properly configured input decoration theme', () {
        final themeData = provider.dynamicTheme;
        final inputTheme = themeData.inputDecorationTheme;

        expect(inputTheme.filled, isTrue);
        expect(inputTheme.fillColor, equals(provider.surfaceColor));
        expect(inputTheme.border, isA<OutlineInputBorder>());
      });

      test('should have properly configured card theme', () {
        final themeData = provider.dynamicTheme;
        final cardTheme = themeData.cardTheme;

        expect(cardTheme.color, equals(provider.surfaceColor));
        expect(cardTheme.elevation, equals(4));
        expect(cardTheme.shape, isA<RoundedRectangleBorder>());
      });

      test('should have properly configured bottom navigation theme', () {
        final themeData = provider.dynamicTheme;
        final bottomNavTheme = themeData.bottomNavigationBarTheme;

        expect(bottomNavTheme.backgroundColor, equals(provider.surfaceColor));
        expect(bottomNavTheme.selectedItemColor, equals(provider.primaryColor));
        expect(bottomNavTheme.type, equals(BottomNavigationBarType.fixed));
      });

      test('should have properly configured slider theme', () {
        final themeData = provider.dynamicTheme;
        final sliderTheme = themeData.sliderTheme;

        expect(sliderTheme.activeTrackColor, equals(provider.primaryColor));
        expect(sliderTheme.thumbColor, equals(provider.primaryColor));
      });
    });

    test('should notify listeners when colors change', () {
      var notificationCount = 0;
      provider.addListener(() => notificationCount++);

      provider.setCustomColors(primary: Colors.red);
      expect(notificationCount, equals(1));

      provider.resetTheme();
      expect(notificationCount, equals(2));
    });
  });
}