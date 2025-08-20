import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ColorPalette {
  final Color? dominantColor;
  final Color? vibrantColor;
  final Color? darkVibrantColor;
  final Color? lightVibrantColor;
  final Color? mutedColor;
  final Color? darkMutedColor;
  final Color? lightMutedColor;

  const ColorPalette({
    this.dominantColor,
    this.vibrantColor,
    this.darkVibrantColor,
    this.lightVibrantColor,
    this.mutedColor,
    this.darkMutedColor,
    this.lightMutedColor,
  });
}

class ColorPaletteService {
  static const int _maxColorCount = 32;
  static const int _targetPixels = 10000;

  static Future<ColorPalette> extractColorsFromImageProvider(
    ImageProvider imageProvider, {
    Size? targetSize,
    int maximumColorCount = _maxColorCount,
  }) async {
    try {
      final ui.Image image = await _loadImageFromProvider(imageProvider);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      
      if (byteData == null) {
        return const ColorPalette();
      }

      final List<Color> extractedColors = _extractColors(byteData, maximumColorCount);
      return _generatePalette(extractedColors);
    } catch (e) {
      return const ColorPalette();
    }
  }

  static Future<ui.Image> _loadImageFromProvider(ImageProvider imageProvider) async {
    final ImageStream stream = imageProvider.resolve(const ImageConfiguration());
    final Completer<ui.Image> completer = Completer<ui.Image>();
    
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (exception, stackTrace) {
        completer.completeError(exception);
        stream.removeListener(listener);
      },
    );
    
    stream.addListener(listener);
    return completer.future;
  }

  static List<Color> _extractColors(ByteData byteData, int maxColors) {
    final Uint8List pixels = byteData.buffer.asUint8List();
    final Map<int, int> colorCounts = {};

    final int sampleRate = (pixels.length / 4 / _targetPixels).ceil().clamp(1, 10);
    
    for (int i = 0; i < pixels.length; i += 4 * sampleRate) {
      if (i + 3 < pixels.length) {
        final int r = pixels[i];
        final int g = pixels[i + 1];
        final int b = pixels[i + 2];
        final int a = pixels[i + 3];
        
        if (a < 128) continue;
        
        final int quantizedR = (r ~/ 32) * 32;
        final int quantizedG = (g ~/ 32) * 32;
        final int quantizedB = (b ~/ 32) * 32;
        
        final int colorValue = (quantizedR << 16) | (quantizedG << 8) | quantizedB;
        colorCounts[colorValue] = (colorCounts[colorValue] ?? 0) + 1;
      }
    }

    final List<MapEntry<int, int>> sortedColors = colorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedColors
        .take(maxColors)
        .map((entry) => Color(0xFF000000 | entry.key))
        .toList();
  }

  static ColorPalette _generatePalette(List<Color> colors) {
    if (colors.isEmpty) return const ColorPalette();

    final colorVariants = _ColorVariants();
    
    for (final color in colors) {
      final hsl = HSLColor.fromColor(color);
      _assignColorToVariant(color, hsl, colorVariants);
    }

    return ColorPalette(
      dominantColor: colors.first,
      vibrantColor: colorVariants.vibrant,
      darkVibrantColor: colorVariants.darkVibrant,
      lightVibrantColor: colorVariants.lightVibrant,
      mutedColor: colorVariants.muted,
      darkMutedColor: colorVariants.darkMuted,
      lightMutedColor: colorVariants.lightMuted,
    );
  }

  static void _assignColorToVariant(Color color, HSLColor hsl, _ColorVariants variants) {
    if (hsl.saturation > 0.6) {
      _assignVibrantColor(color, hsl, variants);
    } else if (hsl.saturation < 0.4) {
      _assignMutedColor(color, hsl, variants);
    }
  }

  static void _assignVibrantColor(Color color, HSLColor hsl, _ColorVariants variants) {
    if (variants.vibrant == null) {
      variants.vibrant = color;
    } else if (hsl.lightness > 0.6 && variants.lightVibrant == null) {
      variants.lightVibrant = color;
    } else if (hsl.lightness < 0.4 && variants.darkVibrant == null) {
      variants.darkVibrant = color;
    }
  }

  static void _assignMutedColor(Color color, HSLColor hsl, _ColorVariants variants) {
    if (variants.muted == null) {
      variants.muted = color;
    } else if (hsl.lightness > 0.6 && variants.lightMuted == null) {
      variants.lightMuted = color;
    } else if (hsl.lightness < 0.4 && variants.darkMuted == null) {
      variants.darkMuted = color;
    }
  }
}

class _ColorVariants {
  Color? vibrant;
  Color? darkVibrant;
  Color? lightVibrant;
  Color? muted;
  Color? darkMuted;
  Color? lightMuted;
}