import 'package:flutter/material.dart';
import '../services/frontend_logging_service.dart';

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
    _loggingService.logError(error, screenName, stackTrace: stackTrace, metadata: metadata);
  }

  void logAuthAction(String action, {bool success = true, Map<String, dynamic>? metadata}) {
    _loggingService.logAuthAction(action, success: success, metadata: metadata);
  }

  void logMusicAction(String action, String trackId, {String? playlistId, Map<String, dynamic>? metadata}) {
    _loggingService.logMusicAction(action, trackId, playlistId: playlistId, metadata: metadata);
  }

  Widget buildLoggingButton({
    required Widget child,
    required VoidCallback onPressed,
    required String buttonName,
    Map<String, dynamic>? metadata,
  }) {
    return GestureDetector(
      onTap: () {
        logButtonClick(buttonName, metadata: metadata);
        onPressed();
      },
      child: child,
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

  Widget buildLoggingElevatedButton({
    required Widget child,
    required VoidCallback onPressed,
    required String buttonName,
    Map<String, dynamic>? metadata,
    ButtonStyle? style,
  }) {
    return ElevatedButton(
      onPressed: () {
        logButtonClick(buttonName, metadata: metadata);
        onPressed();
      },
      style: style,
      child: child,
    );
  }

  Widget buildLoggingTextButton({
    required Widget child,
    required VoidCallback onPressed,
    required String buttonName,
    Map<String, dynamic>? metadata,
    ButtonStyle? style,
  }) {
    return TextButton(
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