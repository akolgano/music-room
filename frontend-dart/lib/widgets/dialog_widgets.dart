import 'package:flutter/material.dart';

class DialogWidgets {
  static ColorScheme _getColorScheme(BuildContext context) => Theme.of(context).colorScheme;
  static Color _getPrimary(BuildContext context) => _getColorScheme(context).primary;
  static Color _getSurface(BuildContext context) => _getColorScheme(context).surface;
  static Color _getBackground(BuildContext context) => _getColorScheme(context).surface;
  static Color _getOnSurface(BuildContext context) => _getColorScheme(context).onSurface;
  static Color _getError(BuildContext context) => _getColorScheme(context).error;

  static OutlineInputBorder _createBorder(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: color, width: width),
      );

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
      builder: (context) => AlertDialog(
        backgroundColor: _getSurface(context),
        title: Text(title, style: TextStyle(color: _getOnSurface(context))),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: _getBackground(context),
              border: _createBorder(Colors.white.withValues(alpha: 0.3), 1),
              enabledBorder: _createBorder(Colors.white.withValues(alpha: 0.3), 1),
              focusedBorder: _createBorder(_getPrimary(context), 2),
              errorBorder: _createBorder(_getError(context), 2),
              focusedErrorBorder: _createBorder(_getError(context), 2),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: TextStyle(color: _getOnSurface(context)),
            maxLines: maxLines, validator: validator,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _getOnSurface(context).withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? true) Navigator.pop(context, controller.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
    
    return result;
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
        backgroundColor: _getSurface(context),
        title: Text(title, style: TextStyle(color: _getOnSurface(context))),
        content: Text(message, style: TextStyle(color: _getOnSurface(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText, style: TextStyle(color: _getOnSurface(context).withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDangerous ? Colors.red : _getPrimary(context),
              foregroundColor: isDangerous ? Colors.white : Colors.black,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<int?> showSelectionDialog<T>({
    required BuildContext context, 
    required String title,
    required List<T> items,
    required String Function(T) itemTitle,
  }) async {
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurface(context),
        title: Text(title, style: TextStyle(color: _getOnSurface(context))),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(itemTitle(items[index]), style: TextStyle(color: _getOnSurface(context))),
              onTap: () => Navigator.pop(context, index),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _getOnSurface(context).withValues(alpha: 0.7))),
          ),
        ],
      ),
    );
  }
}
