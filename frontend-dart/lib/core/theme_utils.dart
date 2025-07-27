import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ThemeUtils {
  static Color getPrimary(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color getSurface(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color getBackground(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color getOnSurface(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color getOnPrimary(BuildContext context) => Theme.of(context).colorScheme.onPrimary;
  static Color getError(BuildContext context) => Theme.of(context).colorScheme.error;
  static Color getSecondary(BuildContext context) => Theme.of(context).colorScheme.secondary;

  static bool isSmallMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width <= 360;
  }

  static bool isMobile(BuildContext context) {
    return ResponsiveBreakpoints.of(context).isMobile || isSmallMobile(context);
  }

  static bool isTablet(BuildContext context) {
    return ResponsiveBreakpoints.of(context).isTablet;
  }

  static bool isDesktop(BuildContext context) {
    return ResponsiveBreakpoints.of(context).isDesktop;
  }

  static double getResponsivePadding(BuildContext context) {
    if (isSmallMobile(context)) return 4.0;
    if (isMobile(context)) return 8.0;
    if (isTablet(context)) return 12.0;
    return 16.0;
  }

  static double getResponsiveMargin(BuildContext context) {
    if (isSmallMobile(context)) return 2.0;
    if (isMobile(context)) return 4.0;
    if (isTablet(context)) return 8.0;
    return 12.0;
  }

  static double getResponsiveBorderRadius(BuildContext context) {
    if (isSmallMobile(context)) return 6.0;
    if (isMobile(context)) return 8.0;
    if (isTablet(context)) return 12.0;
    return 16.0;
  }

  static double getResponsiveIconSize(BuildContext context) {
    if (isSmallMobile(context)) return 20.0;
    if (isMobile(context)) return 24.0;
    if (isTablet(context)) return 28.0;
    return 32.0;
  }

  static double getResponsiveButtonHeight(BuildContext context) {
    if (isSmallMobile(context)) return 40.0;
    if (isMobile(context)) return 48.0;
    if (isTablet(context)) return 52.0;
    return 56.0;
  }

  static EdgeInsets getResponsiveCardPadding(BuildContext context) {
    final padding = getResponsivePadding(context);
    return EdgeInsets.all(padding);
  }

  static EdgeInsets getResponsiveCardMargin(BuildContext context) {
    final margin = getResponsiveMargin(context);
    return EdgeInsets.all(margin);
  }

  static int getResponsiveGridColumns(BuildContext context) {
    if (isSmallMobile(context)) return 1;
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4;
  }

  static TextStyle getHeadingStyle(BuildContext context) {
    final fontSize = isSmallMobile(context) ? 18.0 : (isMobile(context) ? 20.0 : 24.0);
    return TextStyle(
      color: getOnSurface(context), 
      fontSize: fontSize, 
      fontWeight: FontWeight.bold
    );
  }

  static TextStyle getSubheadingStyle(BuildContext context) {
    final fontSize = isSmallMobile(context) ? 14.0 : (isMobile(context) ? 16.0 : 18.0);
    return TextStyle(
      color: getOnSurface(context), 
      fontSize: fontSize, 
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle getBodyStyle(BuildContext context) {
    final fontSize = isSmallMobile(context) ? 12.0 : (isMobile(context) ? 14.0 : 16.0);
    return TextStyle(
      color: getOnSurface(context),
      fontSize: fontSize,
    );
  }

  static TextStyle getCaptionStyle(BuildContext context) {
    final fontSize = isSmallMobile(context) ? 10.0 : (isMobile(context) ? 12.0 : 14.0);
    return TextStyle(
      color: getOnSurface(context).withValues(alpha: 0.7),
      fontSize: fontSize,
    );
  }

  static BoxDecoration getCardDecoration(BuildContext context, {double? borderRadius}) => BoxDecoration(
    color: getSurface(context),
    borderRadius: BorderRadius.circular(borderRadius ?? getResponsiveBorderRadius(context)),
    boxShadow: [
      BoxShadow(
        color: AppTheme.primary.withValues(alpha: 0.1), 
        blurRadius: isSmallMobile(context) ? 4 : 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static ButtonStyle getPrimaryButtonStyle(BuildContext context) => ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primary, 
    foregroundColor: getOnPrimary(context),
    elevation: isSmallMobile(context) ? 2 : 4,
    shadowColor: AppTheme.primary.withValues(alpha: 0.3), 
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(getResponsiveBorderRadius(context))),
    minimumSize: Size(88, getResponsiveButtonHeight(context)),
  );

  static ButtonStyle getSecondaryButtonStyle(BuildContext context) => OutlinedButton.styleFrom(
    foregroundColor: getOnSurface(context),
    side: BorderSide(color: AppTheme.primary), 
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(getResponsiveBorderRadius(context))),
    minimumSize: Size(88, getResponsiveButtonHeight(context)),
  );

  static Future<T?> showThemedDialog<T>({
    required BuildContext context,
    required Widget child,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context),
        child: child,
      ),
    );
  }

  static Future<T?> showThemedBottomSheet<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: getSurface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: builder(context),
      ),
    );
  }

  static LinearGradient createThemeGradient(BuildContext context, {bool reverse = false}) {
    final background = getBackground(context);
    return LinearGradient(
      begin: reverse ? Alignment.bottomCenter : Alignment.topCenter,
      end: reverse ? Alignment.topCenter : Alignment.bottomCenter,
      colors: [
        AppTheme.primary.withValues(alpha: 0.8), 
        AppTheme.primary.withValues(alpha: 0.4), 
        background,
      ],
    );
  }

  static Widget buildThemedCard({
    required BuildContext context,
    required Widget child,
    EdgeInsets? margin,
    EdgeInsets? padding,
    double? elevation,
    double? borderRadius,
  }) {
    return Card(
      color: getSurface(context),
      elevation: elevation ?? (isSmallMobile(context) ? 2 : 4),
      margin: margin ?? getResponsiveCardMargin(context),
      shadowColor: AppTheme.primary.withValues(alpha: 0.2), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius ?? getResponsiveBorderRadius(context))),
      child: Padding(padding: padding ?? getResponsiveCardPadding(context), child: child),
    );
  }

  static Widget buildThemedHeaderCard({required BuildContext context, required Widget child}) => buildThemedCard(
    context: context,
    child: child, 
    elevation: 8
  );

  static InputDecoration getThemedInputDecoration(BuildContext context, {required String labelText, 
    String? hintText, 
    IconData? prefixIcon
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.primary) : null, 
      filled: true,
      fillColor: getSurface(context),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), 
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1)
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), 
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1)
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), 
        borderSide: BorderSide(color: AppTheme.primary, width: 2)
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: getError(context), width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: getError(context), width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
      ),
      labelStyle: TextStyle(fontSize: 16, color: getOnSurface(context).withValues(alpha: 0.7)),
      hintStyle: TextStyle(fontSize: 14, color: getOnSurface(context).withValues(alpha: 0.5)),
    );
  }
}

class AppTheme {
  static const primary = Color(0xFF1DB954);
  static const primaryDark = Color(0xFF1AA34A);
  static const background = Color(0xFF121212);
  static const backgroundDark = Color(0xFF0A0A0A);
  static const surface = Color(0xFF282828);
  static const surfaceDark = Color(0xFF1E1E1E);
  static const surfaceVariant = Color(0xFF333333);
  static const onSurface = Color(0xFFFFFFFF);
  static const onSurfaceVariant = Color(0xFFB3B3B3);
  static const textSecondary = Color(0xFFB3B3B3);
  static const error = Color(0xFFE91429);
  static const success = Color(0xFF00C851);

  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [background, backgroundDark],
  );

  static LinearGradient get surfaceGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceDark],
  );

  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static LinearGradient get cardGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      surface,
      surfaceDark,
      surface.withValues(alpha: 0.8),
    ],
  );

  static ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true, 
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: background,
        error: error,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background, 
        foregroundColor: Colors.white, 
        elevation: 0,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.black,
          minimumSize: const Size(88, 40), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: primary)),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: primary)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1)
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6), 
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1)
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
        ),
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
      ),
      cardTheme: CardThemeData(color: surface,
        elevation: 2,
        shadowColor: primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      ),
      iconTheme: IconThemeData(color: primary),
      primaryIconTheme: const IconThemeData(color: Colors.white),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        elevation: 6,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: Colors.white60,
        type: BottomNavigationBarType.fixed,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: Colors.white70,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary.withValues(alpha: 0.5);
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.black),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: primary.withValues(alpha: 0.3),
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.2),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primary.withValues(alpha: 0.3),
        circularTrackColor: primary.withValues(alpha: 0.3),
      ),
      dividerTheme: DividerThemeData(color: surface, thickness: 1),
      listTileTheme: ListTileThemeData(textColor: Colors.white, iconColor: primary, selectedColor: primary,
        selectedTileColor: primary.withValues(alpha: 0.1),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
        bodySmall: TextStyle(fontSize: 12, color: Colors.white70),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white),
      ),
    );
  }

  static ThemeData get darkTheme => _buildTheme();

  static InputDecoration getInputDecoration({required String labelText, String? hintText, IconData? prefixIcon}) => InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: onSurfaceVariant) : null,
    filled: true,
    fillColor: surfaceVariant,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1)
    ),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r), 
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1)
    ),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kIsWeb ? 8 : 8.r), 
      borderSide: const BorderSide(color: primary, width: 2)
    ),
    labelStyle: TextStyle(fontSize: kIsWeb ? 16 : 16.sp, color: onSurfaceVariant),
    hintStyle: TextStyle(fontSize: kIsWeb ? 14 : 14.sp, color: onSurfaceVariant.withValues(alpha: 0.7)),
  );

  static Widget _buildCard({
    required Widget child, 
    EdgeInsets? margin, 
    EdgeInsets? padding, 
    double? elevation, double? borderRadius
  }) => Card(
    color: surface,
    elevation: elevation ?? 4,
    margin: margin ?? EdgeInsets.all(kIsWeb ? 8 : 8.w),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius ?? (kIsWeb ? 16 : 16.r))  
    ),
    child: Padding(padding: padding ?? EdgeInsets.all(kIsWeb ? 12 : 12.w), child: child),
  );

  static Widget buildHeaderCard({required Widget child}) => _buildCard(child: child, elevation: 8);

  static Widget buildFormCard({required String title, IconData? titleIcon, required Widget child}) => _buildCard(
    borderRadius: kIsWeb ? 12 : 12.r,
    padding: EdgeInsets.all(kIsWeb ? 10 : 10.w),
    margin: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (titleIcon != null) ...[
              Icon(titleIcon, color: primary, size: kIsWeb ? 20 : 20.sp), 
              SizedBox(width: kIsWeb ? 4 : 4.w)
            ],
            Flexible(
              child: Text(title, 
                style: TextStyle(fontSize: kIsWeb ? 18 : 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ), 
            ),
          ],
        ),
        SizedBox(height: kIsWeb ? 8 : 8.h), 
        child,
      ],
    ),
  );
}
