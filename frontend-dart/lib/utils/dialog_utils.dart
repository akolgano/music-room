// lib/utils/dialog_utils.dart
import 'package:flutter/material.dart';
import '../core/app_core.dart';

class DialogUtils {
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = AppStrings.confirm,
    String cancelText = AppStrings.cancel,
    bool isDangerous = false,
    IconData? icon,
  }) {
    return _showBasicDialog<bool>(
      context: context,
      title: title,
      icon: icon,
      content: Text(message, style: const TextStyle(color: Colors.white)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDangerous ? TextButton.styleFrom(foregroundColor: Colors.red) : null,
          child: Text(confirmText),
        ),
      ],
    );
  }

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
  }) {
    return showDialog<String>(
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
  }

  static Future<Map<String, String>?> showMultiInputDialog({
    required BuildContext context,
    required String title,
    required List<InputField> fields,
    IconData? icon,
  }) {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => _MultiInputDialog(
        title: title,
        fields: fields,
        icon: icon,
      ),
    );
  }

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
      showInfoDialog(
        context: context,
        title: 'No Options Available',
        message: emptyMessage ?? 'No items to select from.',
      );
      return Future.value(null);
    }

    return _showBasicDialog<int>(
      context: context,
      title: title,
      icon: icon,
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              leading: itemLeading?.call(item) ?? CircleAvatar(
                backgroundColor: AppTheme.primary,
                child: Text('${index + 1}'),
              ),
              title: Text(itemTitle(item), style: const TextStyle(color: Colors.white)),
              subtitle: itemSubtitle != null 
                ? Text(itemSubtitle(item), style: const TextStyle(color: Colors.grey))
                : null,
              onTap: () => Navigator.of(context).pop(index),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
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
  }) {
    return _showBasicDialog<void>(
      context: context,
      title: title,
      icon: icon ?? Icons.info,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null) ...[
            Text(message, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
          ],
          if (points != null) ...[
            ...points.map((point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 4, height: 4,
                    decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(point, style: const TextStyle(color: Colors.grey))),
                ],
              ),
            )),
          ],
          if (tip != null) ...[
            const SizedBox(height: 16),
            _buildTipContainer(tip),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
        if (onAction != null && actionText != null)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onAction();
            },
            child: Text(actionText),
          ),
      ],
    );
  }

  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? details,
    VoidCallback? onRetry,
    String? retryText,
  }) {
    return _showBasicDialog<void>(
      context: context,
      title: title,
      icon: Icons.error_outline,
      iconColor: Colors.red,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(color: Colors.white)),
          if (details != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(details, style: const TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'monospace')),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
        if (onRetry != null)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRetry();
            },
            child: Text(retryText ?? 'Retry'),
          ),
      ],
    );
  }

  static Future<void> showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onContinue,
    String? continueText,
  }) {
    return _showBasicDialog<void>(
      context: context,
      title: title,
      icon: Icons.check_circle,
      iconColor: Colors.green,
      content: Text(message, style: const TextStyle(color: Colors.white)),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onContinue?.call();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: Text(continueText ?? 'Continue'),
        ),
      ],
    );
  }

  static Future<void> showLoadingDialog(
    BuildContext context, {
    required String title,
    String? message,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }

  static Future<void> showFeatureComingSoon(BuildContext context, [String? feature]) {
    return showInfoDialog(
      context: context,
      title: 'Coming Soon',
      message: feature != null ? '$feature is coming soon!' : AppStrings.featureComingSoon,
      icon: Icons.construction,
    );
  }

  static Future<bool?> showLogoutConfirmDialog(BuildContext context) {
    return showConfirmDialog(
      context,
      title: AppStrings.logout,
      message: AppStrings.confirmLogout,
      confirmText: AppStrings.logout.toUpperCase(),
      isDangerous: true,
      icon: Icons.logout,
    );
  }

  static Future<bool?> showDeleteConfirmDialog(BuildContext context, String itemName) {
    return showConfirmDialog(
      context,
      title: AppStrings.delete,
      message: '${AppStrings.confirmDelete} "$itemName"?',
      confirmText: AppStrings.delete,
      isDangerous: true,
      icon: Icons.delete_forever,
    );
  }

  static Future<void> showAboutDialog({
    required BuildContext context,
    required String appName,
    required String version,
    String? description,
    List<String>? features,
  }) {
    return _showBasicDialog<void>(
      context: context,
      title: 'About $appName',
      icon: Icons.info,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(appName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          const SizedBox(height: 8),
          Text('Version: $version', style: const TextStyle(color: Colors.white)),
          if (description != null) ...[
            const SizedBox(height: 16),
            Text(description, style: const TextStyle(color: Colors.grey)),
          ],
          if (features != null) ...[
            const SizedBox(height: 16),
            const Text('Features:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $feature', style: const TextStyle(color: Colors.grey)),
            )),
          ],
          const SizedBox(height: 16),
          const Text('© 2024 Music Room Team', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  static Future<void> showSettingsDialog({
    required BuildContext context,
    required String title,
    required List<Widget> settings,
    IconData? icon,
  }) {
    return _showBasicDialog<void>(
      context: context,
      title: title,
      icon: icon ?? Icons.settings,
      content: Column(mainAxisSize: MainAxisSize.min, children: settings),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  static Future<T?> _showBasicDialog<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    required List<Widget> actions,
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog<T>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? AppTheme.primary),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white))),
          ],
        ),
        content: content,
        actions: actions,
      ),
    );
  }

  static Widget _buildTipContainer(String tip) {
    return Container(
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
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: AppTheme.primary),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(widget.title, style: const TextStyle(color: Colors.white))),
        ],
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hintText,
            labelText: widget.labelText,
            hintStyle: const TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.white),
          obscureText: widget.obscureText,
          autofocus: true,
          maxLines: widget.maxLines,
          validator: widget.validator,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_controller.text);
            }
          },
          child: const Text(AppStrings.ok),
        ),
      ],
    );
  }
}

class _MultiInputDialog extends StatefulWidget {
  final String title;
  final List<InputField> fields;
  final IconData? icon;

  const _MultiInputDialog({
    required this.title,
    required this.fields,
    this.icon,
  });

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
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: AppTheme.primary),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(widget.title, style: const TextStyle(color: Colors.white))),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.fields.map((field) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              controller: _controllers[field.key],
              decoration: InputDecoration(
                labelText: field.label,
                hintText: field.hint,
                hintStyle: const TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.white),
              obscureText: field.obscureText,
              maxLines: field.maxLines,
              validator: field.validator,
            ),
          )).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
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
  }
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

class FormUtils {
  static Widget buildFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool obscureText = false,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
  }) {
    return TextFormField(
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
  }

  static Widget buildSwitchField({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String title,
    String? subtitle,
    IconData? icon,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey)) : null,
      secondary: icon != null ? Icon(icon, color: AppTheme.primary) : null,
      activeColor: AppTheme.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  static Widget buildCheckboxField({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String title,
    String? subtitle,
  }) {
    return CheckboxListTile(
      value: value,
      onChanged: (val) => onChanged(val ?? false),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey)) : null,
      activeColor: AppTheme.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  static Widget buildDropdownField<T>({
    required T? value,
    required ValueChanged<T?> onChanged,
    required List<T> items,
    required String Function(T) itemText,
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: onChanged,
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(itemText(item)),
      )).toList(),
      decoration: AppTheme.getInputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon,
      ),
      style: const TextStyle(color: Colors.white),
      dropdownColor: AppTheme.surface,
    );
  }

  static Widget buildActionButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isPrimary = true,
    bool fullWidth = true,
    Color? color,
  }) {
    if (isPrimary) {
      return AppTheme.buildPrimaryButton(
        text: text,
        onPressed: onPressed,
        icon: icon,
        isLoading: isLoading,
      );
    } else {
      return AppTheme.buildSecondaryButton(
        text: text,
        onPressed: onPressed,
        icon: icon,
        fullWidth: fullWidth,
      );
    }
  }

  static Widget buildFormCard({
    required String title,
    required List<Widget> children,
    IconData? icon,
    VoidCallback? onSubmit,
    String? submitText,
    bool isLoading = false,
  }) {
    return AppTheme.buildFormCard(
      title: title,
      titleIcon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...children,
          if (onSubmit != null) ...[
            const SizedBox(height: 24),
            buildActionButton(
              text: submitText ?? 'Submit',
              onPressed: onSubmit,
              isLoading: isLoading,
            ),
          ],
        ],
      ),
    );
  }
}

class ValidationUtils {
  static String? validateRequired(String? value, [String? fieldName]) {
    if (value?.isEmpty ?? true) {
      return 'Please enter ${fieldName ?? 'this field'}';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) return 'Please enter an email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? value, [int minLength = 8]) {
    if (value?.isEmpty ?? true) return 'Please enter password';
    if (value!.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  static String? validateLength(String? value, int maxLength, [String? fieldName]) {
    if (value != null && value.length > maxLength) {
      return '${fieldName ?? 'Field'} must be less than $maxLength characters';
    }
    return null;
  }

  static String? validateRange(String? value, int min, int max, [String? fieldName]) {
    if (value != null) {
      if (value.length < min) {
        return '${fieldName ?? 'Field'} must be at least $min characters';
      }
      if (value.length > max) {
        return '${fieldName ?? 'Field'} must be less than $max characters';
      }
    }
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

  static String? validatePhoneNumber(String? value) {
    if (value?.isEmpty ?? true) return null; 
    if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(value!)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? combine(List<String? Function()> validators) {
    for (final validator in validators) {
      final result = validator();
      if (result != null) return result;
    }
    return null;
  }

  static String? Function(String?) required([String? fieldName]) =>
      (value) => validateRequired(value, fieldName);
  
  static String? Function(String?) email() => validateEmail;
  
  static String? Function(String?) password([int minLength = 8]) =>
      (value) => validatePassword(value, minLength);
  
  static String? Function(String?) length(int maxLength, [String? fieldName]) =>
      (value) => validateLength(value, maxLength, fieldName);
  
  static String? Function(String?) range(int min, int max, [String? fieldName]) =>
      (value) => validateRange(value, min, max, fieldName);
}
