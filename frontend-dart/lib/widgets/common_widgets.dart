// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import 'app_widgets.dart';

class CommonWidgets {
  static Widget loadingWidget([String? message]) {
    return AppWidgets.loading(message);
  }

  static Widget emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return AppWidgets.emptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
    );
  }

  static Widget errorState({
    required String message,
    VoidCallback? onRetry,
    String? retryText,
  }) {
    return AppWidgets.errorState(
      message: message,
      onRetry: onRetry,
      retryText: retryText,
    );
  }

  static Widget statusIndicator({
    required bool isConnected,
    String? connectedText,
    String? disconnectedText,
  }) {
    return AppWidgets.statusIndicator(
      isConnected: isConnected,
      connectedText: connectedText,
      disconnectedText: disconnectedText,
    );
  }

  static Widget infoBanner({
    required String title,
    required String message,
    required IconData icon,
    Color? color,
    VoidCallback? onAction,
    String? actionText,
  }) {
    return AppWidgets.infoBanner(
      title: title,
      message: message,
      icon: icon,
      color: color ?? Colors.blue,
      onAction: onAction,
      actionText: actionText,
    );
  }

  static Widget sectionTitle(String title) {
    return AppWidgets.sectionTitle(title);
  }
}
