import 'dart:async';
import 'package:flutter/material.dart';

class _PendingNotification {
  final String message;
  final String? title;
  final Map<String, dynamic>? data;
  final Duration duration;
  final Color? backgroundColor;
  final IconData? icon;

  _PendingNotification({
    required this.message,
    this.title,
    this.data,
    required this.duration,
    this.backgroundColor,
    this.icon,
  });
}

class OverlayInfo {
  final OverlayState overlay;
  final ThemeData theme;

  OverlayInfo({required this.overlay, required this.theme});
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  OverlayEntry? _currentOverlay;
  Timer? _hideTimer;
  Timer? _retryTimer;
  final List<_PendingNotification> _pendingNotifications = [];

  void showNotification({
    required String message,
    String? title,
    Map<String, dynamic>? data,
    Duration duration = const Duration(seconds: 4),
    Color? backgroundColor,
    IconData? icon,
  }) {
    if (!_canShowNotification()) {
      _queueNotification(message, title, data, duration, backgroundColor, icon);
      return;
    }
    
    _showNotificationNow(message, title, data, duration, backgroundColor, icon);
  }

  bool _canShowNotification() {
    final context = navigatorKey.currentContext;
    if (context == null) {
      return false;
    }
    
    final overlay = Overlay.maybeOf(context);
    return overlay != null;
  }

  void _queueNotification(String message, String? title, Map<String, dynamic>? data, 
                         Duration duration, Color? backgroundColor, IconData? icon) {
    
    _pendingNotifications.clear();
    _pendingNotifications.add(_PendingNotification(
      message: message,
      title: title,
      data: data,
      duration: duration,
      backgroundColor: backgroundColor,
      icon: icon,
    ));
    
    _retryTimer?.cancel();
    
    _retryTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_processPendingNotifications()) {
        timer.cancel();
        _retryTimer = null;
      }
    });
  }

  bool _processPendingNotifications() {
    if (_pendingNotifications.isEmpty || !_canShowNotification()) {
      return false;
    }
    
    final notification = _pendingNotifications.removeAt(0);
    _showNotificationNow(
      notification.message,
      notification.title,
      notification.data,
      notification.duration,
      notification.backgroundColor,
      notification.icon,
    );
    
    _pendingNotifications.clear(); 
    return true; 
  }

  void _showNotificationNow(String message, String? title, Map<String, dynamic>? data, 
                           Duration duration, Color? backgroundColor, IconData? icon) {
    final overlayInfo = _getOverlayInfo();
    if (overlayInfo == null) return;

    _hideCurrentNotification();
    _displayNotification(overlayInfo, message, title, data, backgroundColor, icon);
    _hideTimer = Timer(duration, _hideCurrentNotification);
    
  }

  OverlayInfo? _getOverlayInfo() {
    final context = navigatorKey.currentContext;
    if (context == null) {
      return null;
    }

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return null;
    }

    return OverlayInfo(overlay: overlay, theme: Theme.of(context));
  }

  void _displayNotification(OverlayInfo overlayInfo, String message, String? title, 
                          Map<String, dynamic>? data, Color? backgroundColor, IconData? icon) {
    _currentOverlay = OverlayEntry(
      builder: (context) => _buildNotificationWidget(
        context,
        message: message,
        title: title,
        data: data,
        theme: overlayInfo.theme,
        backgroundColor: backgroundColor,
        icon: icon,
      ),
    );

    overlayInfo.overlay.insert(_currentOverlay!);
  }

  Widget _buildNotificationWidget(
    BuildContext context, {
    required String message,
    String? title,
    Map<String, dynamic>? data,
    required ThemeData theme,
    Color? backgroundColor,
    IconData? icon,
  }) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor ?? theme.colorScheme.primary,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: backgroundColor ?? theme.colorScheme.primary,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: theme.colorScheme.onPrimary,
                  size: 24,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      Text(
                        title,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Text(
                      message,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 14,
                        fontWeight: title != null ? FontWeight.normal : FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _hideCurrentNotification,
                child: Icon(
                  Icons.close,
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _hideCurrentNotification() {
    _hideTimer?.cancel();
    _hideTimer = null;
    
    if (_currentOverlay != null) {
      _currentOverlay!.remove();
      _currentOverlay = null;
    }
  }

}
