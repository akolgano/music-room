// lib/core/app_theme.dart
import 'package:flutter/material.dart';

class AppDimens {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusBtn = 25.0;
  
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
  static const double iconXxl = 64.0;
  static const double iconXxxl = 80.0;
  
  static const double btnHeight = 50.0;
  static const double btnHeightSm = 40.0;
  static const double btnHeightLg = 60.0;
  
  static const double albumArtSm = 50.0;
  static const double albumArtMd = 100.0;
  static const double albumArtLg = 200.0;
  static const double albumArtXl = 320.0;
  static const double miniPlayerHeight = 64.0;
  static const double playBtnSize = 64.0;
  
  static const double textXs = 12.0;
  static const double textSm = 14.0;
  static const double textMd = 16.0;
  static const double textLg = 18.0;
  static const double textXl = 20.0;
  static const double textTitle = 24.0;
  static const double textHeading = 32.0;
}

class AppColors {
  static const Color primary = Color(0xFF1DB954);
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF282828);
  static const Color surfaceVariant = Color(0xFF333333);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFB3B3B3);
  static const Color error = Color(0xFFE91429);
  static const Color success = Color(0xFF00C851);
  static const Color warning = Color(0xFFFF9F00);
  static const Color info = Color(0xFF2196F3);
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF1AAE4F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static const primary = AppColors.primary;
  static const background = AppColors.background;
  static const surface = AppColors.surface;
  static const surfaceVariant = AppColors.surfaceVariant;
  static const onSurface = AppColors.onSurface;
  static const onSurfaceVariant = AppColors.onSurfaceVariant;
  static const error = AppColors.error;
  static const success = AppColors.success;
  static const warning = AppColors.warning;
  static const info = AppColors.info;
  
  static const textPrimary = AppColors.onSurface;
  static const textSecondary = AppColors.onSurfaceVariant;
  static Color get textDisabled => AppColors.onSurface.withOpacity(0.5);
  static Color get textSubtle => AppColors.onSurface.withOpacity(0.7);

  static List<BoxShadow> get defaultShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get lightShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: AppDimens.sm,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get heroShadow => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.3),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
    ...defaultShadow,
  ];

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.surface,
    
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.surface,
      background: AppColors.background,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSurface: AppColors.onSurface,
      onBackground: Colors.white,
    ),
    
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: AppDimens.textLg,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        minimumSize: Size(88, AppDimens.btnHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusBtn),
        ),
        elevation: 4,
        textStyle: TextStyle(
          fontSize: AppDimens.textSm,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white),
        minimumSize: Size(88, AppDimens.btnHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusBtn),
        ),
        textStyle: TextStyle(
          fontSize: AppDimens.textSm,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: Size(88, AppDimens.btnHeightSm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        textStyle: TextStyle(
          fontSize: AppDimens.textSm,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.sm,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
      hintStyle: TextStyle(
        color: AppColors.onSurface.withOpacity(0.6),
      ),
    ),
    
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      margin: EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.sm,
      ),
    ),
    
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppDimens.md,
        vertical: AppDimens.sm,
      ),
      minVerticalPadding: AppDimens.sm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
    ),
    
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.black,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
      ),
    ),
    
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
    ),
    
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      elevation: 8,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: AppDimens.textLg,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(
        color: AppColors.onSurfaceVariant,
        fontSize: AppDimens.textSm,
      ),
    ),
    
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXl),
        ),
      ),
      elevation: 8,
    ),
    
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.onSurfaceVariant,
      indicatorColor: AppColors.primary,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(
        fontSize: AppDimens.textSm,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: AppDimens.textSm,
        fontWeight: FontWeight.normal,
      ),
    ),
    
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.onSurface.withOpacity(0.7),
      thumbColor: Colors.white,
      overlayColor: AppColors.primary.withOpacity(0.1),
      trackHeight: 3.0,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
    ),
    
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.white;
        }
        return AppColors.onSurfaceVariant;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary;
        }
        return AppColors.surfaceVariant;
      }),
    ),
    
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary;
        }
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.all(Colors.black),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
    ),
  );

  static ButtonStyle get fullWidthButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.black,
    minimumSize: Size(double.infinity, AppDimens.btnHeight),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimens.radiusBtn),
    ),
    elevation: 4,
    textStyle: TextStyle(
      fontSize: AppDimens.textSm,
      fontWeight: FontWeight.w600,
    ),
  );

  static ButtonStyle get dangerButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: Colors.white,
    minimumSize: Size(88, AppDimens.btnHeight),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimens.radiusBtn),
    ),
    elevation: 4,
    textStyle: TextStyle(
      fontSize: AppDimens.textSm,
      fontWeight: FontWeight.w600,
    ),
  );
}

class AppDimensions {
  static const double paddingXSmall = AppDimens.xs;
  static const double paddingSmall = AppDimens.sm;
  static const double paddingMedium = AppDimens.md;
  static const double paddingLarge = AppDimens.lg;
  static const double paddingXLarge = AppDimens.xl;
  
  static const double radiusSmall = AppDimens.radiusSm;
  static const double radiusMedium = AppDimens.radiusMd;
  static const double radiusLarge = AppDimens.radiusLg;
  static const double radiusXLarge = AppDimens.radiusXl;
  static const double radiusButton = AppDimens.radiusBtn;
  
  static const double iconSmall = AppDimens.iconSm;
  static const double iconMedium = AppDimens.iconMd;
  static const double iconLarge = AppDimens.iconLg;
  static const double iconXLarge = AppDimens.iconXl;
  static const double iconXXLarge = AppDimens.iconXxl;
  static const double iconXXXLarge = AppDimens.iconXxxl;
  
  static const double buttonHeight = AppDimens.btnHeight;
  static const double buttonHeightSmall = AppDimens.btnHeightSm;
  static const double buttonHeightLarge = AppDimens.btnHeightLg;
  
  static const double avatarSmall = 32.0;
  static const double avatarMedium = 50.0;
  static const double avatarLarge = 80.0;
  static const double avatarXLarge = 100.0;
  
  static const double albumArtSmall = AppDimens.albumArtSm;
  static const double albumArtMedium = AppDimens.albumArtMd;
  static const double albumArtLarge = AppDimens.albumArtLg;
  static const double albumArtXLarge = AppDimens.albumArtXl;
  
  static const double textSmall = AppDimens.textXs;
  static const double textMedium = AppDimens.textSm;
  static const double textLarge = AppDimens.textMd;
  static const double textXLarge = AppDimens.textLg;
  static const double textXXLarge = AppDimens.textXl;
  static const double textTitle = AppDimens.textTitle;
  static const double textHeading = AppDimens.textHeading;
}
