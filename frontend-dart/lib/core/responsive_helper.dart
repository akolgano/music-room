// lib/core/responsive_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ResponsiveHelper {
  static double fontSize(BuildContext context, double size) {
    if (ResponsiveBreakpoints.of(context).isMobile) {
      return size.sp;
    }
    return size;
  }

  static double spacing(BuildContext context, double size) {
    if (ResponsiveBreakpoints.of(context).isMobile) {
      return size.w;
    }
    return size;
  }

  static double borderRadius(BuildContext context, double radius) {
    if (ResponsiveBreakpoints.of(context).isMobile) {
      return radius.r;
    }
    return radius;
  }

  static double iconSize(BuildContext context, double size) {
    if (ResponsiveBreakpoints.of(context).isMobile) {
      return size.sp;
    }
    return size;
  }

  static EdgeInsets padding(BuildContext context, double size) {
    if (ResponsiveBreakpoints.of(context).isMobile) {
      return EdgeInsets.all(size.w);
    }
    return EdgeInsets.all(size);
  }

  static EdgeInsets symmetricPadding(
    BuildContext context, {
    required double horizontal,
    required double vertical,
  }) {
    if (ResponsiveBreakpoints.of(context).isMobile) {
      return EdgeInsets.symmetric(
        horizontal: horizontal.w,
        vertical: vertical.h,
      );
    }
    return EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: vertical,
    );
  }

  static bool isMobile(BuildContext context) {
    return ResponsiveBreakpoints.of(context).isMobile;
  }

  static bool isTablet(BuildContext context) {
    return ResponsiveBreakpoints.of(context).isTablet;
  }

  static bool isDesktop(BuildContext context) {
    return ResponsiveBreakpoints.of(context).isDesktop;
  }

  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}

class R {
  static BuildContext? _context;

  static void init(BuildContext context) {
    _context = context;
    if (!ScreenUtil().screenWidth.isFinite) {
      ScreenUtil.init(context);
    }
  }

  static double h(double height) {
    if (_context != null && ResponsiveBreakpoints.of(_context!).isMobile) {
      return height.h;
    }
    return height;
  }

  static double w(double width) {
    if (_context != null && ResponsiveBreakpoints.of(_context!).isMobile) {
      return width.w;
    }
    return width;
  }

  static double s(double size) {
    if (_context != null && ResponsiveBreakpoints.of(_context!).isMobile) {
      return size.sp;
    }
    return size;
  }

  static double r(double radius) {
    if (_context != null && ResponsiveBreakpoints.of(_context!).isMobile) {
      return radius.r;
    }
    return radius;
  }

  static EdgeInsets p(double padding) {
    if (_context != null && ResponsiveBreakpoints.of(_context!).isMobile) {
      return EdgeInsets.all(padding.w);
    }
    return EdgeInsets.all(padding);
  }

  static EdgeInsets sym({required double h, required double v}) {
    if (_context != null && ResponsiveBreakpoints.of(_context!).isMobile) {
      return EdgeInsets.symmetric(horizontal: h.w, vertical: v.h);
    }
    return EdgeInsets.symmetric(horizontal: h, vertical: v);
  }

  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    if (_context != null && ResponsiveBreakpoints.of(_context!).isMobile) {
      return EdgeInsets.only(
        left: left.w,
        top: top.h,
        right: right.w,
        bottom: bottom.h,
      );
    }
    return EdgeInsets.only(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }
}
