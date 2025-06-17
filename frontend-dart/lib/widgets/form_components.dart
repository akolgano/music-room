// lib/widgets/form_components.dart
import 'package:flutter/material.dart';
import '../core/consolidated_core.dart';
import 'app_widgets.dart';

class FormComponents {
  static Widget textField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    bool obscureText = false,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    int minLines = 1,
    int maxLines = 1,
  }) => AppWidgets.textField(
    controller: controller,
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    obscureText: obscureText,
    validator: validator,
    onChanged: onChanged,
    minLines: minLines,
    maxLines: maxLines,
  );

  static Widget button({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
  }) => AppWidgets.primaryButton(
    text: text,
    onPressed: onPressed,
    icon: icon,
    isLoading: isLoading,
    fullWidth: fullWidth,
  );

  static Widget switchTile({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String title,
    String? subtitle,
    IconData? icon,
  }) => AppWidgets.switchTile(
    value: value,
    onChanged: onChanged,
    title: title,
    subtitle: subtitle,
    icon: icon,
  );
}
