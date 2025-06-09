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
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: isDangerous
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  static Future<bool?> showLogoutConfirmDialog(BuildContext context) {
    return showConfirmDialog(
      context,
      title: AppStrings.logout,
      message: AppStrings.confirmLogout,
      confirmText: AppStrings.logout.toUpperCase(),
      isDangerous: true,
    );
  }

  static Future<bool?> showDeleteConfirmDialog(BuildContext context, String itemName) {
    return showConfirmDialog(
      context,
      title: AppStrings.delete,
      message: '${AppStrings.confirmDelete} "$itemName"?',
      confirmText: AppStrings.delete,
      isDangerous: true,
    );
  }

  static Future<String?> showTextInputDialog(
    BuildContext context, {
    required String title,
    String? initialValue,
    String? hintText,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();
    
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey),
            ),
            style: const TextStyle(color: Colors.white),
            obscureText: obscureText,
            autofocus: true,
            validator: validator,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(controller.text);
              }
            },
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }

  static Future<void> showFeatureComingSoon(BuildContext context, [String? feature]) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Row(
          children: [
            Icon(Icons.construction, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Coming Soon', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          feature != null 
            ? '$feature is coming soon!' 
            : AppStrings.featureComingSoon,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
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
  }) {
    if (items.isEmpty) {
      showInfoDialog(
        context: context,
        title: 'No Options Available',
        message: emptyMessage ?? 'No items to select from.',
      );
      return Future.value(null);
    }

    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
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
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppTheme.primary),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(title, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
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
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(point, style: const TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              )),
            ],
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
                    Expanded(
                      child: Text(
                        tip, 
                        style: const TextStyle(color: AppTheme.primary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
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
      ),
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

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  static Future<void> showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? details,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
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
                child: Text(
                  details,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
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
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  static Future<void> showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onContinue,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onContinue?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  static Future<void> showAboutDialog({
    required BuildContext context,
    required String appName,
    required String version,
    String? description,
    List<String>? features,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('About $appName', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text('Version: $version', style: const TextStyle(color: Colors.white)),
            if (description != null) ...[
              const SizedBox(height: 16),
              Text(description, style: const TextStyle(color: Colors.grey)),
            ],
            if (features != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Features:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $feature', style: const TextStyle(color: Colors.grey)),
              )),
            ],
            const SizedBox(height: 16),
            const Text(
              '© 2024 Music Room Team',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Future<Map<String, String>?> showMultiInputDialog({
    required BuildContext context,
    required String title,
    required List<String> fieldNames,
    List<String>? initialValues,
    List<String>? hintTexts,
    List<bool>? obscureTexts,
  }) {
    final controllers = fieldNames.map((name) => TextEditingController()).toList();
    final formKey = GlobalKey<FormState>();

    if (initialValues != null) {
      for (int i = 0; i < initialValues.length && i < controllers.length; i++) {
        controllers[i].text = initialValues[i];
      }
    }

    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: fieldNames.asMap().entries.map((entry) {
              final index = entry.key;
              final fieldName = entry.value;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: controllers[index],
                  decoration: InputDecoration(
                    labelText: fieldName,
                    hintText: hintTexts != null && index < hintTexts.length 
                      ? hintTexts[index] 
                      : null,
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                  obscureText: obscureTexts != null && 
                              index < obscureTexts.length && 
                              obscureTexts[index],
                  validator: (value) => 
                    value?.isEmpty ?? true ? 'Please enter $fieldName' : null,
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final result = <String, String>{};
                for (int i = 0; i < fieldNames.length; i++) {
                  result[fieldNames[i]] = controllers[i].text;
                }
                Navigator.of(ctx).pop(result);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((result) {
      for (final controller in controllers) {
        controller.dispose();
      }
      return result;
    });
  }

  static Future<void> showSettingsDialog({
    required BuildContext context,
    required String title,
    required List<Widget> settings,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: settings,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
