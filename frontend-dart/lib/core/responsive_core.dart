import 'package:flutter/material.dart';

enum ScreenSize { 
  tiny,
  small,
  medium,
  large,
  xlarge,
  xxlarge
}

class MusicAppResponsive {
  static const Map<ScreenSize, double> _breakpoints = {
    ScreenSize.tiny: 256,
    ScreenSize.small: 426,
    ScreenSize.medium: 640,
    ScreenSize.large: 854,
    ScreenSize.xlarge: 1280,
    ScreenSize.xxlarge: 1920,
  };

  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width <= _breakpoints[ScreenSize.tiny]!) return ScreenSize.tiny;
    if (width <= _breakpoints[ScreenSize.small]!) return ScreenSize.small;
    if (width <= _breakpoints[ScreenSize.medium]!) return ScreenSize.medium;
    if (width <= _breakpoints[ScreenSize.large]!) return ScreenSize.large;
    if (width <= _breakpoints[ScreenSize.xlarge]!) return ScreenSize.xlarge;
    return ScreenSize.xxlarge;
  }

  static T _getResponsiveValue<T>(BuildContext context, {
    required T tiny,
    required T small,
    required T medium,
    required T large,
    required T xlarge,
    required T xxlarge,
  }) {
    switch (getScreenSize(context)) {
      case ScreenSize.tiny: return tiny;
      case ScreenSize.small: return small;
      case ScreenSize.medium: return medium;
      case ScreenSize.large: return large;
      case ScreenSize.xlarge: return xlarge;
      case ScreenSize.xxlarge: return xxlarge;
    }
  }

  static double getFontSize(BuildContext context, {
    double tiny = 8.0,
    double small = 10.0,
    double medium = 12.0,
    double large = 14.0,
    double xlarge = 16.0,
    double xxlarge = 18.0,
  }) => _getResponsiveValue(context,
      tiny: tiny, small: small, medium: medium,
      large: large, xlarge: xlarge, xxlarge: xxlarge);


  static double getIconSize(BuildContext context, {
    double tiny = 12.0,
    double small = 16.0,
    double medium = 20.0,
    double large = 24.0,
    double xlarge = 28.0,
    double xxlarge = 32.0,
  }) => _getResponsiveValue(context,
      tiny: tiny, small: small, medium: medium,
      large: large, xlarge: xlarge, xxlarge: xxlarge);

  static double getButtonHeight(BuildContext context, {
    double tiny = 32.0,
    double small = 36.0,
    double medium = 40.0,
    double large = 44.0,
    double xlarge = 48.0,
    double xxlarge = 56.0,
  }) => _getResponsiveValue(context,
      tiny: tiny, small: small, medium: medium,
      large: large, xlarge: xlarge, xxlarge: xxlarge);

  static double getBorderRadius(BuildContext context, {
    double tiny = 2.0,
    double small = 4.0,
    double medium = 6.0,
    double large = 8.0,
    double xlarge = 12.0,
    double xxlarge = 16.0,
  }) => _getResponsiveValue(context,
      tiny: tiny, small: small, medium: medium,
      large: large, xlarge: xlarge, xxlarge: xxlarge);


  static int getGridColumns(BuildContext context, {
    int tiny = 1,
    int small = 1,
    int medium = 2,
    int large = 2,
    int xlarge = 3,
    int xxlarge = 4,
  }) => _getResponsiveValue(context,
      tiny: tiny, small: small, medium: medium,
      large: large, xlarge: xlarge, xxlarge: xxlarge);

  static bool isMobileSize(BuildContext context) {
    final size = getScreenSize(context);
    return size == ScreenSize.tiny || size == ScreenSize.small || size == ScreenSize.medium;
  }

  static bool isSmallScreen(BuildContext context) {
    final size = getScreenSize(context);
    return size == ScreenSize.tiny || size == ScreenSize.small;
  }

  static EdgeInsets getButtonPadding(BuildContext context, {
    EdgeInsets? tiny,
    EdgeInsets? small,
    EdgeInsets? medium,
    EdgeInsets? large,
    EdgeInsets? xlarge,
    EdgeInsets? xxlarge,
  }) {
    final defaults = {
      ScreenSize.tiny: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ScreenSize.small: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ScreenSize.medium: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ScreenSize.large: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ScreenSize.xlarge: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ScreenSize.xxlarge: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    };

    final values = {
      ScreenSize.tiny: tiny ?? defaults[ScreenSize.tiny]!,
      ScreenSize.small: small ?? defaults[ScreenSize.small]!,
      ScreenSize.medium: medium ?? defaults[ScreenSize.medium]!,
      ScreenSize.large: large ?? defaults[ScreenSize.large]!,
      ScreenSize.xlarge: xlarge ?? defaults[ScreenSize.xlarge]!,
      ScreenSize.xxlarge: xxlarge ?? defaults[ScreenSize.xxlarge]!,
    };

    return values[getScreenSize(context)]!;
  }

  static double getCardWidth(BuildContext context, {
    double? tiny,
    double? small,
    double? medium,
    double? large,
    double? xlarge,
    double? xxlarge,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final defaults = {
      ScreenSize.tiny: screenWidth * 0.9,
      ScreenSize.small: screenWidth * 0.85,
      ScreenSize.medium: screenWidth * 0.8,
      ScreenSize.large: screenWidth * 0.75,
      ScreenSize.xlarge: screenWidth * 0.7,
      ScreenSize.xxlarge: screenWidth * 0.65,
    };

    final values = {
      ScreenSize.tiny: tiny ?? defaults[ScreenSize.tiny]!,
      ScreenSize.small: small ?? defaults[ScreenSize.small]!,
      ScreenSize.medium: medium ?? defaults[ScreenSize.medium]!,
      ScreenSize.large: large ?? defaults[ScreenSize.large]!,
      ScreenSize.xlarge: xlarge ?? defaults[ScreenSize.xlarge]!,
      ScreenSize.xxlarge: xxlarge ?? defaults[ScreenSize.xxlarge]!,
    };

    return values[getScreenSize(context)]!;
  }

  static double getSpacing(BuildContext context, {
    double tiny = 4.0,
    double small = 6.0,
    double medium = 8.0,
    double large = 12.0,
    double xlarge = 16.0,
    double xxlarge = 20.0,
  }) => _getResponsiveValue(context,
      tiny: tiny, small: small, medium: medium,
      large: large, xlarge: xlarge, xxlarge: xxlarge);

}
