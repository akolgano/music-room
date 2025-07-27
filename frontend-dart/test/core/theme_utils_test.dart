import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/core/theme_utils.dart';
void main() {
  group('Theme Utils Tests', () {
    test('AppTheme should provide dark theme data', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme, isA<ThemeData>());
      expect(darkTheme.brightness, Brightness.dark);
    });
    test('AppTheme should have consistent color schemes', () {
      final darkTheme = AppTheme.darkTheme;
      
      expect(darkTheme.colorScheme, isA<ColorScheme>());
      expect(darkTheme.colorScheme.brightness, Brightness.dark);
    });
    test('AppTheme should handle Material 3 design', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.useMaterial3, true);
    });
    test('AppTheme should provide app bar theme', () {
      final theme = AppTheme.darkTheme;
      expect(theme.appBarTheme, isA<AppBarTheme>());
    });
    test('AppTheme should provide text theme', () {
      final theme = AppTheme.darkTheme;
      expect(theme.textTheme, isA<TextTheme>());
    });
    test('AppTheme should have correct primary color', () {
      expect(AppTheme.primary, const Color(0xFF1DB954));
    });
    test('AppTheme should have correct background color', () {
      expect(AppTheme.background, const Color(0xFF121212));
    });
    test('AppTheme should have correct surface color', () {
      expect(AppTheme.surface, const Color(0xFF282828));
    });
  });
}
