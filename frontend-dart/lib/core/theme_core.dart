import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'responsive_core.dart' show MusicAppResponsive;

class ThemeUtils {


  static double getResponsivePadding(BuildContext context) {
    return MusicAppResponsive.getSpacing(context,
      tiny: 2.0, small: 4.0, medium: 6.0, 
      large: 8.0, xlarge: 12.0, xxlarge: 16.0
    );
  }

  static double getResponsiveMargin(BuildContext context) {
    return MusicAppResponsive.getSpacing(context,
      tiny: 1.0, small: 2.0, medium: 4.0,
      large: 6.0, xlarge: 8.0, xxlarge: 12.0
    );
  }

  static double getResponsiveBorderRadius(BuildContext context) {
    return MusicAppResponsive.getBorderRadius(context,
      tiny: 3.0, small: 4.0, medium: 6.0,
      large: 8.0, xlarge: 12.0, xxlarge: 16.0
    );
  }

  static double getResponsiveIconSize(BuildContext context) {
    return MusicAppResponsive.getIconSize(context,
      tiny: 14.0, small: 18.0, medium: 20.0,
      large: 24.0, xlarge: 28.0, xxlarge: 32.0
    );
  }

  static double getResponsiveButtonHeight(BuildContext context) {
    return MusicAppResponsive.getButtonHeight(context);
  }


  static TextStyle getHeadingStyle(BuildContext context) {
    final fontSize = MusicAppResponsive.getFontSize(context,
      tiny: 14.0, small: 16.0, medium: 18.0,
      large: 20.0, xlarge: 22.0, xxlarge: 24.0
    );
    return TextStyle(
      color: Theme.of(context).colorScheme.onSurface, 
      fontSize: fontSize, 
      fontWeight: FontWeight.bold
    );
  }

  static TextStyle getSubheadingStyle(BuildContext context) {
    final fontSize = MusicAppResponsive.getFontSize(context,
      tiny: 12.0, small: 13.0, medium: 14.0,
      large: 16.0, xlarge: 17.0, xxlarge: 18.0
    );
    return TextStyle(
      color: Theme.of(context).colorScheme.onSurface, 
      fontSize: fontSize, 
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle getBodyStyle(BuildContext context) {
    final fontSize = MusicAppResponsive.getFontSize(context,
      tiny: 10.0, small: 11.0, medium: 12.0,
      large: 14.0, xlarge: 15.0, xxlarge: 16.0
    );
    return TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: fontSize,
    );
  }

  static TextStyle getCaptionStyle(BuildContext context) {
    final fontSize = MusicAppResponsive.getFontSize(context,
      tiny: 8.0, small: 9.0, medium: 10.0,
      large: 12.0, xlarge: 13.0, xxlarge: 14.0
    );
    return TextStyle(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      fontSize: fontSize,
    );
  }

  static ButtonStyle getPrimaryButtonStyle(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    final baseHeight = getResponsiveButtonHeight(context);
    final scaledHeight = (baseHeight * textScaleFactor).clamp(32.0, 72.0);
    
    return ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primary, 
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      elevation: 4.0,
      shadowColor: AppTheme.primary.withValues(alpha: 0.3), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(getResponsiveBorderRadius(context))),
      minimumSize: Size(MusicAppResponsive.getFontSize(context,
        tiny: 60.0, small: 70.0, medium: 80.0,
        large: 88.0, xlarge: 96.0, xxlarge: 104.0
      ) * textScaleFactor, scaledHeight),
      padding: EdgeInsets.symmetric(
        horizontal: MusicAppResponsive.getButtonPadding(context).horizontal * textScaleFactor,
        vertical: MusicAppResponsive.getButtonPadding(context).vertical * textScaleFactor,
      ).clamp(
        const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
      ),
    );
  }

  static ButtonStyle getSecondaryButtonStyle(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    final baseHeight = getResponsiveButtonHeight(context);
    final scaledHeight = (baseHeight * textScaleFactor).clamp(32.0, 72.0);
    
    return OutlinedButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      side: BorderSide(color: AppTheme.primary), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(getResponsiveBorderRadius(context))),
      minimumSize: Size(MusicAppResponsive.getFontSize(context,
        tiny: 60.0, small: 70.0, medium: 80.0,
        large: 88.0, xlarge: 96.0, xxlarge: 104.0
      ) * textScaleFactor, scaledHeight),
      padding: EdgeInsets.symmetric(
        horizontal: MusicAppResponsive.getButtonPadding(context).horizontal * textScaleFactor,
        vertical: MusicAppResponsive.getButtonPadding(context).vertical * textScaleFactor,
      ).clamp(
        const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
      ),
    );
  }

  static Color getColorFromString(String id) {
    int hashValue = id.hashCode.abs();
    return Colors.primaries[hashValue % Colors.primaries.length];
  }

  static InputDecoration getThemedInputDecoration(BuildContext context, {required String labelText, 
    String? hintText, 
    IconData? prefixIcon
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.primary) : null, 
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
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
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
      ),
      labelStyle: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
      hintStyle: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
    );
  }
}

class AppTheme {
  static const primary = Color(0xFF1DB954);
  static const primaryDark = Color(0xFF1AA34A);
  static const primaryLight = Color(0xFF2EF564);
  static const primaryPulse = Color(0xFF0F7A2E);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: primary)),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white, 
          side: BorderSide(color: primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
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



  static Widget buildHeaderCard({required Widget child}) => Card(
    color: surface,
    elevation: 8,
    margin: EdgeInsets.all(kIsWeb ? 8 : 8.w),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kIsWeb ? 16 : 16.r)  
    ),
    child: Padding(padding: EdgeInsets.all(kIsWeb ? 12 : 12.w), child: child),
  );

  static Widget buildFormCard({required String title, IconData? titleIcon, required Widget child}) => Card(
    color: surface,
    elevation: 4,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r)
    ),
    child: Padding(
      padding: EdgeInsets.all(kIsWeb ? 10 : 10.w), 
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
    ),
  );
}
