import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FormWidgets {
  static ColorScheme _colorScheme(BuildContext context) => Theme.of(context).colorScheme;
  
  static double _responsiveValue(double value) => value.sp;
  static double _responsiveWidth(double value) => value.w;
  static double _responsiveHeight(double value) => value.h;
  
  static TextStyle _primaryStyle(BuildContext context) => Theme.of(context).textTheme.bodyLarge!;
  
  static OutlineInputBorder _createBorder(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8.0),
    borderSide: BorderSide(color: color, width: width),
  );

  static Widget textField({
    required BuildContext context, 
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    bool obscureText = false,
    String? Function(String?)? validator, 
    ValueChanged<String>? onChanged, 
    ValueChanged<String>? onFieldSubmitted,
    int minLines = 1, 
    int maxLines = 1
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      minLines: minLines, 
      maxLines: maxLines,
      style: _primaryStyle(context),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: _colorScheme(context).primary) : null,
        filled: true,
        fillColor: _colorScheme(context).surface,
        border: _createBorder(Colors.white.withValues(alpha: 0.3), 1),
        enabledBorder: _createBorder(Colors.white.withValues(alpha: 0.3), 1),
        focusedBorder: _createBorder(_colorScheme(context).primary, 2),
        errorBorder: _createBorder(_colorScheme(context).error, 2),
        focusedErrorBorder: _createBorder(_colorScheme(context).error, 2),
        disabledBorder: _createBorder(Colors.grey.withValues(alpha: 0.2), 1),
        labelStyle: TextStyle(fontSize: 16, color: _colorScheme(context).onSurface.withValues(alpha: 0.7)),
        hintStyle: TextStyle(fontSize: 14, color: _colorScheme(context).onSurface.withValues(alpha: 0.5)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _responsiveWidth(16.0), 
          vertical: _responsiveHeight(6.0)
        ),
      ),
    );
  }

  static Widget primaryButton({
    required BuildContext context,
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
  }) {
    final theme = Theme.of(context);
    final content = isLoading 
      ? SizedBox(
          width: _responsiveWidth(16.0), 
          height: _responsiveHeight(16.0), 
          child: CircularProgressIndicator(
            strokeWidth: 2, 
            color: theme.colorScheme.onPrimary
          )
        )
      : Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: _responsiveValue(16.0)), 
              SizedBox(width: _responsiveWidth(8.0))
            ],
            Flexible(
              child: Text(
                text, 
                style: TextStyle(fontSize: _responsiveValue(14.0)), 
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center, 
                maxLines: 1
              )
            ),
          ],
        );
    
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: theme.elevatedButtonTheme.style,
      child: content,
    );
    
    return fullWidth ? SizedBox(
      width: double.infinity, 
      height: _responsiveHeight(40.0), 
      child: button
    ) : button;
  }

  static Widget secondaryButton({
    required BuildContext context, 
    required String text, 
    required VoidCallback? onPressed, 
    IconData? icon, 
    bool fullWidth = true,
  }) {
    final theme = Theme.of(context);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: _responsiveValue(16.0)), 
          SizedBox(width: _responsiveWidth(6.0))
        ],
        Flexible(
          child: Text(
            text, 
            style: TextStyle(fontSize: _responsiveValue(13.0)), 
            overflow: TextOverflow.visible,
            textAlign: TextAlign.center,
            maxLines: 1,
          )
        ),
      ],
    );
    
    final button = OutlinedButton(
      onPressed: onPressed, 
      style: theme.outlinedButtonTheme.style,
      child: content,
    );
    
    return fullWidth ? SizedBox(
      width: double.infinity, 
      height: _responsiveHeight(40.0), 
      child: button
    ) : button;
  }
}