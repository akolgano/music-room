// lib/utils/consolidated_utils.dart
import 'package:flutter/material.dart';
import '../core/app_core.dart';

class FormUtils {
  static String? validateRequired(String? value, [String? fieldName]) =>
      value?.isEmpty ?? true ? 'Please enter ${fieldName ?? 'this field'}' : null;

  static String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter an email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? value, [int minLength = 8]) {
    if (value?.isEmpty ?? true) return 'Please enter password';
    if (value!.length < minLength) return 'Password must be at least $minLength characters';
    return null;
  }

  static String? validateUsername(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter a username';
    if (value!.length < 3) return 'Username must be at least 3 characters';
    if (value.length > 30) return 'Username must be less than 30 characters';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  static String? validatePlaylistName(String? value) =>
      value?.isEmpty ?? true ? 'Please enter a playlist name' : null;

  static Widget buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool obscureText = false,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    obscureText: obscureText,
    validator: validator,
    onChanged: onChanged,
    maxLines: maxLines,
    style: const TextStyle(color: Colors.white),
    decoration: AppTheme.getInputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon,
    ),
  );

  static Widget buildSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String title,
    String? subtitle,
    IconData? icon,
  }) => SwitchListTile(
    value: value,
    onChanged: onChanged,
    title: Text(title, style: const TextStyle(color: Colors.white)),
    subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey)) : null,
    secondary: icon != null ? Icon(icon, color: AppTheme.primary) : null,
    activeColor: AppTheme.primary,
    contentPadding: EdgeInsets.zero,
  );

  static Widget buildButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isPrimary = true,
    bool fullWidth = true,
  }) {
    final child = isLoading 
      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
      : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, size: 16),
            if (icon != null) const SizedBox(width: 8),
            Text(text),
          ],
        );

    final button = isPrimary
      ? ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.black,
          ),
          child: child,
        )
      : OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primary,
            side: const BorderSide(color: AppTheme.primary),
          ),
          child: child,
        );

    return fullWidth ? SizedBox(width: double.infinity, height: 50, child: button) : button;
  }
}

class DialogUtils {
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
    IconData? icon,
  }) => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: isDangerous ? Colors.red : AppTheme.primary),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white))),
        ],
      ),
      content: Text(message, style: const TextStyle(color: Colors.white)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(cancelText)),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDangerous ? TextButton.styleFrom(foregroundColor: Colors.red) : null,
          child: Text(confirmText),
        ),
      ],
    ),
  );

  static Future<String?> showTextInputDialog(
    BuildContext context, {
    required String title,
    String? initialValue,
    String? hintText,
    String? labelText,
    bool obscureText = false,
    String? Function(String?)? validator,
    IconData? icon,
    int maxLines = 1,
  }) => showDialog<String>(
    context: context,
    builder: (ctx) => _TextInputDialog(
      title: title,
      initialValue: initialValue,
      hintText: hintText,
      labelText: labelText,
      obscureText: obscureText,
      validator: validator,
      icon: icon,
      maxLines: maxLines,
    ),
  );

  static Future<Map<String, String>?> showMultiInputDialog({
    required BuildContext context,
    required String title,
    required List<InputField> fields,
    IconData? icon,
  }) => showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => _MultiInputDialog(title: title, fields: fields, icon: icon),
  );

  static Future<int?> showSelectionDialog<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T) itemTitle,
    String Function(T)? itemSubtitle,
    Widget Function(T)? itemLeading,
    String? emptyMessage,
    IconData? icon,
  }) {
    if (items.isEmpty) {
      showInfoDialog(context: context, title: 'No Options Available', message: emptyMessage ?? 'No items to select from.');
      return Future.value(null);
    }

    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            if (icon != null) ...[Icon(icon, color: AppTheme.primary), const SizedBox(width: 8)],
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: itemLeading?.call(item) ?? CircleAvatar(backgroundColor: AppTheme.primary, child: Text('${index + 1}')),
                title: Text(itemTitle(item), style: const TextStyle(color: Colors.white)),
                subtitle: itemSubtitle != null ? Text(itemSubtitle(item), style: const TextStyle(color: Colors.grey)) : null,
                onTap: () => Navigator.of(context).pop(index),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))],
      ),
    );
  }

  static Future<void> showInfoDialog({
    required BuildContext context,
    required String title,
    String? message,
    List<String>? points,
    String? tip,
    VoidCallback? onAction,
    String? actionText,
    IconData? icon,
  }) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Row(
        children: [
          if (icon != null) ...[Icon(icon, color: AppTheme.primary), const SizedBox(width: 8)],
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null) Text(message, style: const TextStyle(color: Colors.white)),
          if (points != null) ...points.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('• $point', style: const TextStyle(color: Colors.grey)),
          )),
          if (tip != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: AppTheme.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tip, style: const TextStyle(color: AppTheme.primary, fontSize: 12))),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        if (onAction != null && actionText != null)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onAction();
            },
            child: Text(actionText),
          ),
      ],
    ),
  );

  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? details,
    VoidCallback? onRetry,
    String? retryText,
  }) => showInfoDialog(
    context: context,
    title: title,
    message: message,
    icon: Icons.error_outline,
    points: details != null ? [details] : null,
    onAction: onRetry,
    actionText: retryText ?? 'Retry',
  );

  static Future<void> showFeatureComingSoon(BuildContext context, [String? feature]) => showInfoDialog(
    context: context,
    title: 'Coming Soon',
    message: feature != null ? '$feature is coming soon!' : 'This feature is coming soon!',
    icon: Icons.construction,
  );
}

class InputField {
  final String key;
  final String label;
  final String? hint;
  final String? initialValue;
  final bool obscureText;
  final int maxLines;
  final String? Function(String?)? validator;

  const InputField({
    required this.key,
    required this.label,
    this.hint,
    this.initialValue,
    this.obscureText = false,
    this.maxLines = 1,
    this.validator,
  });
}

class _TextInputDialog extends StatefulWidget {
  final String title;
  final String? initialValue;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final String? Function(String?)? validator;
  final IconData? icon;
  final int maxLines;

  const _TextInputDialog({
    required this.title,
    this.initialValue,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.validator,
    this.icon,
    this.maxLines = 1,
  });

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;
  late final GlobalKey<FormState> _formKey;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _formKey = GlobalKey<FormState>();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppTheme.surface,
    title: Row(
      children: [
        if (widget.icon != null) ...[Icon(widget.icon, color: AppTheme.primary), const SizedBox(width: 8)],
        Expanded(child: Text(widget.title, style: const TextStyle(color: Colors.white))),
      ],
    ),
    content: Form(
      key: _formKey,
      child: FormUtils.buildField(
        controller: _controller,
        label: widget.labelText ?? '',
        hint: widget.hintText,
        obscureText: widget.obscureText,
        maxLines: widget.maxLines,
        validator: widget.validator,
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
      TextButton(
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            Navigator.of(context).pop(_controller.text);
          }
        },
        child: const Text('OK'),
      ),
    ],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _MultiInputDialog extends StatefulWidget {
  final String title;
  final List<InputField> fields;
  final IconData? icon;

  const _MultiInputDialog({required this.title, required this.fields, this.icon});

  @override
  State<_MultiInputDialog> createState() => _MultiInputDialogState();
}

class _MultiInputDialogState extends State<_MultiInputDialog> {
  late final Map<String, TextEditingController> _controllers;
  late final GlobalKey<FormState> _formKey;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _formKey = GlobalKey<FormState>();
    
    for (final field in widget.fields) {
      _controllers[field.key] = TextEditingController(text: field.initialValue);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppTheme.surface,
    title: Row(
      children: [
        if (widget.icon != null) ...[Icon(widget.icon, color: AppTheme.primary), const SizedBox(width: 8)],
        Expanded(child: Text(widget.title, style: const TextStyle(color: Colors.white))),
      ],
    ),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.fields.map((field) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: FormUtils.buildField(
            controller: _controllers[field.key]!,
            label: field.label,
            hint: field.hint,
            obscureText: field.obscureText,
            maxLines: field.maxLines,
            validator: field.validator,
          ),
        )).toList(),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
      TextButton(
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            final result = <String, String>{};
            for (final field in widget.fields) {
              result[field.key] = _controllers[field.key]!.text;
            }
            Navigator.of(context).pop(result);
          }
        },
        child: const Text('Save'),
      ),
    ],
  );

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
