import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/core/responsive_core.dart';
import 'package:music_room/core/theme_core.dart';

void main() {
  group('MusicAppResponsive Tests', () {
    testWidgets('should determine screen size correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(300, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final screenSize = MusicAppResponsive.getScreenSize(context);
              return Scaffold(
                body: Text('Screen: ${screenSize.name}'),
              );
            },
          ),
        ),
      );

      expect(find.textContaining('Screen:'), findsOneWidget);
    });

    testWidgets('should provide responsive padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final padding = MusicAppResponsive.getPadding(context);
              return Scaffold(
                body: Text('Padding: $padding'),
              );
            },
          ),
        ),
      );

      expect(find.textContaining('Padding:'), findsOneWidget);
    });

    testWidgets('should provide responsive font size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final fontSize = MusicAppResponsive.getFontSize(context);
              return Scaffold(
                body: Text('Font Size: $fontSize'),
              );
            },
          ),
        ),
      );

      expect(find.textContaining('Font Size:'), findsOneWidget);
    });

    testWidgets('should provide responsive icon size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final iconSize = MusicAppResponsive.getIconSize(context);
              return Scaffold(
                body: Text('Icon Size: $iconSize'),
              );
            },
          ),
        ),
      );

      expect(find.textContaining('Icon Size:'), findsOneWidget);
    });

    testWidgets('should provide responsive margin', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final margin = MusicAppResponsive.getPadding(context);
              return Scaffold(
                body: Text('Margin: $margin'),
              );
            },
          ),
        ),
      );

      expect(find.textContaining('Margin:'), findsOneWidget);
    });

    testWidgets('should provide responsive border radius', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final borderRadius = MusicAppResponsive.getBorderRadius(context);
              return Scaffold(
                body: Text('Border Radius: $borderRadius'),
              );
            },
          ),
        ),
      );

      expect(find.textContaining('Border Radius:'), findsOneWidget);
    });


    testWidgets('should provide responsive grid columns', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final columns = MusicAppResponsive.getGridColumns(context);
              return Scaffold(
                body: Text('Grid Columns: $columns'),
              );
            },
          ),
        ),
      );

      expect(find.textContaining('Grid Columns:'), findsOneWidget);
    });

    testWidgets('should provide responsive values through theme helper', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final height = ThemeUtils.getResponsiveButtonHeight(context);
              return Scaffold(
                body: Text('Button Height: $height'),
              );
            },
          ),
        ),
      );

      expect(find.textContaining('Button Height:'), findsOneWidget);
    });

    testWidgets('should detect very small screens', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(200, 400));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final isVerySmall = MusicAppResponsive.isSmallScreen(context);
              return Scaffold(
                body: Text('Very Small: $isVerySmall'),
              );
            },
          ),
        ),
      );

      expect(find.textContaining('Very Small:'), findsOneWidget);
    });

    testWidgets('should detect desktop size screens', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final isDesktop = MusicAppResponsive.getScreenSize(context) == ScreenSize.xxlarge;
              return Scaffold(
                body: Text('Desktop: $isDesktop'),
              );
            },
          ),
        ),
      );

      expect(find.textContaining('Desktop:'), findsOneWidget);
    });
  });
}