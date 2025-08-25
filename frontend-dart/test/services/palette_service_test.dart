import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:music_room/services/palette_service.dart';

void main() {
  group('ColorPalette', () {
    test('should create ColorPalette with default null values', () {
      const palette = ColorPalette();
      
      expect(palette.dominantColor, isNull);
      expect(palette.vibrantColor, isNull);
      expect(palette.darkVibrantColor, isNull);
      expect(palette.lightVibrantColor, isNull);
      expect(palette.mutedColor, isNull);
      expect(palette.darkMutedColor, isNull);
      expect(palette.lightMutedColor, isNull);
    });

    test('should create ColorPalette with specified colors', () {
      const palette = ColorPalette(
        dominantColor: Colors.blue,
        vibrantColor: Colors.red,
      );
      
      expect(palette.dominantColor, equals(Colors.blue));
      expect(palette.vibrantColor, equals(Colors.red));
      expect(palette.darkVibrantColor, isNull);
    });
  });

  group('ColorPaletteService', () {
    test('extractColorsFromImageProvider should return ColorPalette', () async {
      const imageProvider = AssetImage('assets/test_image.png');
      
      final result = await ColorPaletteService.extractColorsFromImageProvider(imageProvider);
      
      expect(result, isA<ColorPalette>());
    });

    test('extractColorsFromImageProvider should handle errors gracefully', () async {
      const imageProvider = AssetImage('nonexistent.png');
      
      final result = await ColorPaletteService.extractColorsFromImageProvider(imageProvider);
      
      expect(result, isA<ColorPalette>());
    });
  });
}