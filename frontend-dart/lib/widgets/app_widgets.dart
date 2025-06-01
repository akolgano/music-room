// lib/widgets/app_widgets.dart
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/dimensions.dart';
import '../core/app_strings.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;

  const AppButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isSecondary) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading 
            ? const SizedBox(
                width: AppDimensions.iconSmall,
                height: AppDimensions.iconSmall,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon ?? Icons.check),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white),
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading 
          ? const SizedBox(
              width: AppDimensions.iconSmall,
              height: AppDimensions.iconSmall,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            )
          : Icon(icon ?? Icons.check, size: AppDimensions.iconSmall),
      label: Text(text),
      style: AppTheme.fullWidthButtonStyle,
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  const AppCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color ?? AppTheme.surface,
      margin: margin ?? EdgeInsets.all(AppDimensions.paddingMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(AppDimensions.paddingMedium),
        child: child,
      ),
    );
  }
}

class AppListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Widget? trailing;

  const AppListTile({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(AppDimensions.paddingSmall),
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Icon(
          icon, 
          color: iconColor ?? AppTheme.primary,
          size: AppDimensions.iconMedium,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null 
          ? Text(
              subtitle!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: AppDimensions.textSmall,
              ),
            )
          : null,
      trailing: trailing ?? Icon(
        Icons.chevron_right,
        color: Colors.white.withOpacity(0.5),
      ),
      onTap: onTap,
    );
  }
}

class AppSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const AppSection({
    Key? key,
    required this.title,
    required this.children,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding ?? EdgeInsets.only(
            left: AppDimensions.paddingSmall, 
            bottom: AppDimensions.paddingSmall,
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: AppDimensions.textLarge,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ),
        ...children,
        SizedBox(height: AppDimensions.paddingMedium),
      ],
    );
  }
}

class AppBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;

  const AppBadge({
    Key? key,
    required this.text,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSmall,
        vertical: AppDimensions.paddingXSmall,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? AppTheme.primary,
          fontSize: AppDimensions.textSmall,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
