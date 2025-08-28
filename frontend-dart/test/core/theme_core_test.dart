import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/core/theme_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
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

    test('AppTheme should provide error color', () {
      expect(AppTheme.error, isA<Color>());
    });

    test('AppTheme should provide success color', () {
      expect(AppTheme.success, isA<Color>());
    });

    test('AppTheme dark theme should have proper elevation overlay', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.applyElevationOverlayColor, true);
    });

    test('AppTheme dark theme should have proper card theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.cardTheme, isA<CardTheme>());
      expect(darkTheme.cardTheme.color, isNotNull);
    });

    test('AppTheme should have proper elevated button theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.elevatedButtonTheme, isA<ElevatedButtonThemeData>());
    });

    test('AppTheme should have proper text button theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.textButtonTheme, isA<TextButtonThemeData>());
    });

    test('AppTheme should have proper outlined button theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.outlinedButtonTheme, isA<OutlinedButtonThemeData>());
    });

    test('AppTheme should have proper input decoration theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.inputDecorationTheme, isA<InputDecorationTheme>());
    });

    test('AppTheme should have proper scaffold background color', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.scaffoldBackgroundColor, isA<Color>());
    });

    test('AppTheme should have proper divider theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.dividerTheme, isA<DividerThemeData>());
    });

    test('AppTheme should have proper icon theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.iconTheme, isA<IconThemeData>());
      expect(darkTheme.primaryIconTheme, isA<IconThemeData>());
    });

    test('AppTheme should have proper list tile theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.listTileTheme, isA<ListTileThemeData>());
    });

    test('AppTheme should have proper checkbox theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.checkboxTheme, isA<CheckboxThemeData>());
    });

    test('AppTheme should have proper radio theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.radioTheme, isA<RadioThemeData>());
    });

    test('AppTheme should have proper switch theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.switchTheme, isA<SwitchThemeData>());
    });

    test('AppTheme should have proper bottom navigation bar theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.bottomNavigationBarTheme, isA<BottomNavigationBarThemeData>());
    });

    test('AppTheme should have proper tab bar theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.tabBarTheme, isA<TabBarTheme>());
    });

    test('AppTheme should have proper bottom sheet theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.bottomSheetTheme, isA<BottomSheetThemeData>());
    });

    test('AppTheme should have proper snack bar theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.snackBarTheme, isA<SnackBarThemeData>());
    });

    test('AppTheme should have proper dialog theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.dialogTheme, isA<DialogTheme>());
    });

    test('AppTheme should have proper floating action button theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.floatingActionButtonTheme, isA<FloatingActionButtonThemeData>());
    });

    test('AppTheme should have proper navigation rail theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.navigationRailTheme, isA<NavigationRailThemeData>());
    });

    test('AppTheme should have proper drawer theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.drawerTheme, isA<DrawerThemeData>());
    });

    test('AppTheme should have proper tooltip theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.tooltipTheme, isA<TooltipThemeData>());
    });

    test('AppTheme should have proper popup menu theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.popupMenuTheme, isA<PopupMenuThemeData>());
    });

    test('AppTheme should have proper banner theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.bannerTheme, isA<MaterialBannerThemeData>());
    });

    test('AppTheme should have proper chip theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.chipTheme, isA<ChipThemeData>());
    });

    test('AppTheme should have proper data table theme', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.dataTableTheme, isA<DataTableThemeData>());
    });
  });
}
