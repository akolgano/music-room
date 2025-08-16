import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FormWidgets {
  
  

  static Widget buildButton({
    required BuildContext context,
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
    bool isSecondary = false,
  }) {
    final theme = Theme.of(context);
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    final scaledHeight = (40.0 * textScaleFactor).clamp(32.0, 72.0);
    
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
    
    final button = isSecondary 
      ? OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: theme.outlinedButtonTheme.style?.copyWith(
            minimumSize: WidgetStateProperty.all(Size(88 * textScaleFactor, scaledHeight)),
            padding: WidgetStateProperty.all(EdgeInsets.symmetric(
              horizontal: (16.0 * textScaleFactor).clamp(8.0, 24.0),
              vertical: (8.0 * textScaleFactor).clamp(4.0, 16.0),
            )),
          ),
          child: content,
        )
      : ElevatedButton(
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

}