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

  static double getFontSize(BuildContext context, {
    double tiny = 8.0,
    double small = 10.0,
    double medium = 12.0,
    double large = 14.0,
    double xlarge = 16.0,
    double xxlarge = 18.0,
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

  static double getPadding(BuildContext context, {
    double tiny = 2.0,
    double small = 4.0,
    double medium = 6.0,
    double large = 8.0,
    double xlarge = 12.0,
    double xxlarge = 16.0,
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

  static double getMargin(BuildContext context, {
    double tiny = 1.0,
    double small = 2.0,
    double medium = 4.0,
    double large = 6.0,
    double xlarge = 8.0,
    double xxlarge = 12.0,
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

  static double getIconSize(BuildContext context, {
    double tiny = 12.0,
    double small = 16.0,
    double medium = 20.0,
    double large = 24.0,
    double xlarge = 28.0,
    double xxlarge = 32.0,
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

  static double getButtonHeight(BuildContext context, {
    double tiny = 28.0,
    double small = 32.0,
    double medium = 36.0,
    double large = 40.0,
    double xlarge = 48.0,
    double xxlarge = 56.0,
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

  static double getBorderRadius(BuildContext context, {
    double tiny = 2.0,
    double small = 4.0,
    double medium = 6.0,
    double large = 8.0,
    double xlarge = 12.0,
    double xxlarge = 16.0,
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

  static double getElevation(BuildContext context, {
    double tiny = 1.0,
    double small = 2.0,
    double medium = 3.0,
    double large = 4.0,
    double xlarge = 6.0,
    double xxlarge = 8.0,
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

  static int getGridColumns(BuildContext context, {
    int tiny = 1,
    int small = 1,
    int medium = 2,
    int large = 2,
    int xlarge = 3,
    int xxlarge = 4,
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


  static bool isVerySmall(BuildContext context) {
    final size = getScreenSize(context);
    return size == ScreenSize.tiny || size == ScreenSize.small;
  }

  static bool isMobileSize(BuildContext context) {
    final size = getScreenSize(context);
    return size == ScreenSize.tiny || size == ScreenSize.small || size == ScreenSize.medium;
  }

  static bool isTabletSize(BuildContext context) {
    final size = getScreenSize(context);
    return size == ScreenSize.large || size == ScreenSize.xlarge;
  }

  static bool isDesktopSize(BuildContext context) {
    return getScreenSize(context) == ScreenSize.xxlarge;
  }


}
