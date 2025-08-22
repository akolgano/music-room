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

    final result = await _showInputDialog(
      context: context,
      title: title,
      content: _buildTextForm(context, controller, formKey, hintText, maxLines, validator),
      onSave: () => _validateAndGetText(formKey, controller, context),
    );

    controller.dispose();
    return result;
  }

  static Future<String?> _showInputDialog({
    required BuildContext context,
    required String title,
    required Widget content,
    required VoidCallback onSave,
  }) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: _buildDialogTitle(context, title),
        content: content,
        actions: _buildDialogActions(context, onSave),
      ),
    );
  }

  static Widget _buildDialogTitle(BuildContext context, String title) {
    return Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface));
  }

  static Widget _buildTextForm(BuildContext context, TextEditingController controller, 
      GlobalKey<FormState> formKey, String? hintText, int maxLines, String? Function(String?)? validator) {
    return Form(
      key: formKey,
      child: TextFormField(
        controller: controller,
        decoration: _buildInputDecoration(context, hintText),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  static InputDecoration _buildInputDecoration(BuildContext context, String? hintText) {
    final borderRadius = BorderRadius.circular(8);
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: _createBorder(borderRadius, Colors.white.withValues(alpha: 0.3), 1),
      enabledBorder: _createBorder(borderRadius, Colors.white.withValues(alpha: 0.3), 1),
      focusedBorder: _createBorder(borderRadius, Theme.of(context).colorScheme.primary, 2),
      errorBorder: _createBorder(borderRadius, Theme.of(context).colorScheme.error, 2),
      focusedErrorBorder: _createBorder(borderRadius, Theme.of(context).colorScheme.error, 2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  static OutlineInputBorder _createBorder(BorderRadius borderRadius, Color color, double width) {
    return OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static List<Widget> _buildDialogActions(BuildContext context, VoidCallback onSave) {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
      ),
      ElevatedButton(
        onPressed: onSave,
        child: const Text('Save'),
      ),
    ];
  }

  static void _validateAndGetText(GlobalKey<FormState> formKey, TextEditingController controller, BuildContext context) {
    if (formKey.currentState?.validate() ?? true) {
      Navigator.pop(context, controller.text);
    }
  }

  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool isDangerous = false,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDangerous ? Colors.red : Theme.of(context).colorScheme.primary,
              foregroundColor: isDangerous ? Colors.white : Colors.black,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

}
