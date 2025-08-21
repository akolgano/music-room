import 'package:flutter/material.dart';
import '../services/logging_services.dart';

mixin UserActionLoggingMixin<T extends StatefulWidget> on State<T> {
  final FrontendLoggingService _loggingService = FrontendLoggingService();
  
  String get screenName => widget.runtimeType.toString().replaceAll('Screen', '').replaceAll('Widget', '');

  void logButtonClick(String buttonName, {Map<String, dynamic>? metadata}) {
    _loggingService.logButtonClick(buttonName, screenName, metadata: metadata);
  }

  void logFormSubmit(String formName, {bool success = true, Map<String, dynamic>? metadata}) {
    _loggingService.logFormSubmit(formName, screenName, success: success, metadata: metadata);
  }

  void logSearch(String query, {int? resultCount, Map<String, dynamic>? metadata}) {
    _loggingService.logSearch(query, screenName, resultCount: resultCount, metadata: metadata);
  }

  void logUserAction({
    required UserActionType actionType,
    required String description,
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? metadata,
  }) {
    _loggingService.logUserAction(
      actionType: actionType,
      description: description,
      level: level,
      metadata: metadata,
      screenName: screenName,
    );
  }

  void logError(String error, {StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    _loggingService.logUserAction(
      actionType: UserActionType.other,
      description: 'Error occurred: $error',
      level: LogLevel.error,
      metadata: {
        'error': error,
        'stack_trace': stackTrace?.toString(),
        ...?metadata,
      },
      screenName: screenName,
    );
  }

  void logAuthAction(String action, {bool success = true, Map<String, dynamic>? metadata}) {
    final actionType = action == 'login' ? UserActionType.login :
                      action == 'logout' ? UserActionType.logout :
                      action == 'signup' ? UserActionType.signup :
                      UserActionType.other;
    
    _loggingService.logUserAction(
      actionType: actionType,
      description: 'Auth action: $action ${success ? 'successful' : 'failed'}',
      level: success ? LogLevel.info : LogLevel.warning,
      metadata: {
        'action': action,
        'success': success,
        ...?metadata,
      },
      screenName: screenName,
    );
  }

  Widget buildLoggingInkWell({
    required Widget child,
    required VoidCallback onTap,
    required String actionName,
    Map<String, dynamic>? metadata,
  }) {
    return InkWell(
      onTap: () {
        logButtonClick(actionName, metadata: metadata);
        onTap();
      },
      child: child,
    );
  }

  Widget buildLoggingButton<B extends ButtonStyleButton>({
    required Widget child,
    required VoidCallback onPressed,
    required String buttonName,
    required B Function({
      required VoidCallback onPressed,
      required Widget child,
      ButtonStyle? style,
    }) buttonBuilder,
    Map<String, dynamic>? metadata,
    ButtonStyle? style,
  }) {
    return buttonBuilder(
      onPressed: () {
        logButtonClick(buttonName, metadata: metadata);
        onPressed();
      },
      style: style,
      child: child,
    );
  }

  Widget buildLoggingIconButton({
    required Widget icon,
    required VoidCallback onPressed,
    required String buttonName,
    Map<String, dynamic>? metadata,
    double? iconSize,
    Color? color,
  }) {
    return IconButton(
      onPressed: () {
        logButtonClick(buttonName, metadata: metadata);
        onPressed();
      },
      icon: icon,
      iconSize: iconSize,
      color: color,
    );
  }
}