// lib/core/theme_utils.dart
import 'package:flutter/material.dart';
import '../providers/dynamic_theme_provider.dart';
import '../core/core.dart';

class ThemeUtils {
  static Color getPrimary(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color getSurface(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color getBackground(BuildContext context) => Theme.of(context).colorScheme.background;
  static Color getOnSurface(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color getOnPrimary(BuildContext context) => Theme.of(context).colorScheme.onPrimary;
  static Color getError(BuildContext context) => Theme.of(context).colorScheme.error;
  static Color getSecondary(BuildContext context) => Theme.of(context).colorScheme.secondary;

  static TextStyle getHeadingStyle(BuildContext context) => TextStyle(
    color: getOnSurface(context), fontSize: 24, fontWeight: FontWeight.bold
  );

  static TextStyle getSubheadingStyle(BuildContext context) => TextStyle(
    color: getOnSurface(context), fontSize: 18, fontWeight: FontWeight.w600,
  );

  static TextStyle getBodyStyle(BuildContext context) => TextStyle(
    color: getOnSurface(context),
    fontSize: 16,
  );

  static TextStyle getCaptionStyle(BuildContext context) => TextStyle(
    color: getOnSurface(context).withOpacity(0.7),
    fontSize: 14,
  );

  static BoxDecoration getCardDecoration(BuildContext context, {double? borderRadius}) => BoxDecoration(
    color: getSurface(context),
    borderRadius: BorderRadius.circular(borderRadius ?? 12),
    boxShadow: [
      BoxShadow(
        color: AppTheme.primary.withOpacity(0.1), 
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static ButtonStyle getPrimaryButtonStyle(BuildContext context) => ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primary, 
    foregroundColor: getOnPrimary(context),
    elevation: 4,
    shadowColor: AppTheme.primary.withOpacity(0.3), 
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
  );

  static ButtonStyle getSecondaryButtonStyle(BuildContext context) => OutlinedButton.styleFrom(
    foregroundColor: getOnSurface(context),
    side: BorderSide(color: AppTheme.primary), 
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  static void animateThemeChange(DynamicThemeProvider themeProvider, String? imageUrl) {
    if (imageUrl != null) {
      themeProvider.extractAndApplyDominantColor(imageUrl);
    }
  }

  static LinearGradient createThemeGradient(BuildContext context, {bool reverse = false}) {
    final background = getBackground(context);
    return LinearGradient(
      begin: reverse ? Alignment.bottomCenter : Alignment.topCenter,
      end: reverse ? Alignment.topCenter : Alignment.bottomCenter,
      colors: [
        AppTheme.primary.withOpacity(0.8), 
        AppTheme.primary.withOpacity(0.4), 
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
      elevation: elevation ?? 4,
      margin: margin ?? const EdgeInsets.all(16),
      shadowColor: AppTheme.primary.withOpacity(0.2), 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 16)
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(24), 
        child: child
      ),
    );
  }

  static Widget buildThemedHeaderCard({
    required BuildContext context,
    required Widget child
  }) => buildThemedCard(
    context: context,
    child: child, 
    elevation: 8
  );

  static InputDecoration getThemedInputDecoration(
    BuildContext context, {
    required String labelText, 
    String? hintText, 
    IconData? prefixIcon
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.primary) : null, 
      filled: true,
      fillColor: getSurface(context),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.primary, width: 2)),
      labelStyle: TextStyle(fontSize: 16, color: getOnSurface(context).withOpacity(0.7)),
      hintStyle: TextStyle(fontSize: 14, color: getOnSurface(context).withOpacity(0.5)),
    );
  }
}
