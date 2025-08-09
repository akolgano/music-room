import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FormWidgets {
  
  static double _getScaledButtonHeight(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    const baseHeight = 40.0;
    return (baseHeight * textScaleFactor).clamp(32.0, 72.0);
  }
  
  
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
      style: Theme.of(context).textTheme.bodyLarge!,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Theme.of(context).colorScheme.primary) : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
        ),
        labelStyle: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        hintStyle: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.0.w, 
          vertical: 6.0.h
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
    final scaledHeight = _getScaledButtonHeight(context);
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    
    final content = isLoading 
      ? SizedBox(
          width: (16.0 * textScaleFactor).clamp(12.0, 24.0), 
          height: (16.0 * textScaleFactor).clamp(12.0, 24.0), 
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
              Icon(icon, size: (16.0 * textScaleFactor).clamp(14.0, 22.0)), 
              SizedBox(width: 8.0.w)
            ],
            Flexible(
              child: Text(
                text, 
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center, 
                maxLines: 1
              )
            ),
          ],
        );
    
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: theme.elevatedButtonTheme.style?.copyWith(
        minimumSize: WidgetStateProperty.all(Size(88 * textScaleFactor, scaledHeight)),
        padding: WidgetStateProperty.all(EdgeInsets.symmetric(
          horizontal: (16.0 * textScaleFactor).clamp(8.0, 24.0),
          vertical: (8.0 * textScaleFactor).clamp(4.0, 16.0),
        )),
      ),
      child: content,
    );
    
    return fullWidth ? SizedBox(
      width: double.infinity, 
      height: scaledHeight, 
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
    final scaledHeight = _getScaledButtonHeight(context);
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: (16.0 * textScaleFactor).clamp(14.0, 22.0)), 
          SizedBox(width: 6.0.w)
        ],
        Flexible(
          child: Text(
            text, 
            overflow: TextOverflow.visible,
            textAlign: TextAlign.center,
            maxLines: 1,
          )
        ),
      ],
    );
    
    final button = OutlinedButton(
      onPressed: onPressed, 
      style: theme.outlinedButtonTheme.style?.copyWith(
        minimumSize: WidgetStateProperty.all(Size(88 * textScaleFactor, scaledHeight)),
        padding: WidgetStateProperty.all(EdgeInsets.symmetric(
          horizontal: (16.0 * textScaleFactor).clamp(8.0, 24.0),
          vertical: (8.0 * textScaleFactor).clamp(4.0, 16.0),
        )),
      ),
      child: content,
    );
    
    return fullWidth ? SizedBox(
      width: double.infinity, 
      height: scaledHeight, 
      child: button
    ) : button;
  }
}