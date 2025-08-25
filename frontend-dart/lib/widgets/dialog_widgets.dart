import 'package:flutter/material.dart';

class DialogWidgets {
  static Future<String?> showTextInputDialog(
    BuildContext context, {
    required String title,
    String? initialValue,
    String? hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final defaultBorder = _border(8, Colors.white.withValues(alpha: 0.3), 1);
        return AlertDialog(
          backgroundColor: scheme.surface,
          title: Text(title, style: TextStyle(color: scheme.onSurface)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                filled: true,
                fillColor: scheme.surface,
                border: defaultBorder,
                enabledBorder: defaultBorder,
                focusedBorder: _border(8, scheme.primary, 2),
                errorBorder: _border(8, scheme.error, 2),
                focusedErrorBorder: _border(8, scheme.error, 2),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: TextStyle(color: scheme.onSurface),
              maxLines: maxLines,
              validator: validator,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7))),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? true) Navigator.pop(ctx, controller.text);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  static OutlineInputBorder _border(double radius, Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: BorderSide(color: color, width: width),
  );

  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool isDangerous = false,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async => await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final onSurface = Theme.of(ctx).colorScheme.onSurface;
      return AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: Text(title, style: TextStyle(color: onSurface)),
        content: Text(message, style: TextStyle(color: onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText, style: TextStyle(color: onSurface.withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: isDangerous ? ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ) : null,
            child: Text(confirmText),
          ),
        ],
      );
    },
  ) ?? false;
}