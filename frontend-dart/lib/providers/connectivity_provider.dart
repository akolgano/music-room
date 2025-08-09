import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/base_provider.dart';
import '../core/service_locator.dart';
import '../services/api_service.dart';

enum ConnectionStatus { connected, disconnected, checking }

class ConnectivityProvider extends BaseProvider {
  ConnectionStatus _connectionStatus = ConnectionStatus.checking;
  DateTime? _lastConnectedTime;
  Timer? _healthCheckTimer;
  static const Duration _healthCheckInterval = Duration(seconds: 30);
  static const Duration _timeoutDuration = Duration(seconds: 5);

  ConnectionStatus get connectionStatus => _connectionStatus;
  bool get isConnected => _connectionStatus == ConnectionStatus.connected;
  bool get isDisconnected => _connectionStatus == ConnectionStatus.disconnected;
  bool get isChecking => _connectionStatus == ConnectionStatus.checking;
  DateTime? get lastConnectedTime => _lastConnectedTime;

  ConnectivityProvider() {
    _initializeHealthCheck();
  }

  void _initializeHealthCheck() {
    _checkConnection();
    _startHealthCheckTimer();
  }

  void _startHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(
      _healthCheckInterval,
      (_) => _checkConnection(),
    );
  }

  void stopHealthCheck() {
    _healthCheckTimer?.cancel();
  }

  Future<void> _checkConnection() async {
    if (_connectionStatus != ConnectionStatus.checking) {
      _setConnectionStatus(ConnectionStatus.checking);
    }

    try {
      final apiService = getIt<ApiService>();
      final dio = Dio(
        BaseOptions(
          baseUrl: apiService.baseUrl,
          connectTimeout: _timeoutDuration,
          receiveTimeout: _timeoutDuration,
          sendTimeout: _timeoutDuration,
        ),
      );

      await dio.head('/admin/');
      _setConnectionStatus(ConnectionStatus.connected);
      _lastConnectedTime = DateTime.now();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConnectivityProvider] Connection check failed: $e');
      }
      _setConnectionStatus(ConnectionStatus.disconnected);
    }
  }

  void _setConnectionStatus(ConnectionStatus status) {
    if (_connectionStatus != status) {
      _connectionStatus = status;
      notifyListeners();

      if (kDebugMode) {
        debugPrint(
          '[ConnectivityProvider] Connection status changed to: $status',
        );
      }
    }
  }

  Future<void> forceCheck() async {
    await _checkConnection();
  }

  String get connectionStatusText {
    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.disconnected:
        return 'Offline';
      case ConnectionStatus.checking:
        return 'Checking...';
    }
  }

  String get detailedStatusText {
    switch (_connectionStatus) {
      case ConnectionStatus.connected:
        if (_lastConnectedTime != null) {
          final timeAgo = DateTime.now().difference(_lastConnectedTime!);
          if (timeAgo.inMinutes < 1) {
            return 'Connected (just now)';
          } else if (timeAgo.inHours < 1) {
            return 'Connected (${timeAgo.inMinutes}m ago)';
          } else {
            return 'Connected (${timeAgo.inHours}h ago)';
          }
        }
        return 'Connected';
      case ConnectionStatus.disconnected:
        if (_lastConnectedTime != null) {
          final timeAgo = DateTime.now().difference(_lastConnectedTime!);
          if (timeAgo.inMinutes < 1) {
            return 'Offline (lost connection just now)';
          } else if (timeAgo.inHours < 1) {
            return 'Offline (lost connection ${timeAgo.inMinutes}m ago)';
          } else {
            return 'Offline (lost connection ${timeAgo.inHours}h ago)';
          }
        }
        return 'Offline';
      case ConnectionStatus.checking:
        return 'Checking connection...';
    }
  }

  @override
  void dispose() {
    _healthCheckTimer?.cancel();
    super.dispose();
  }
}

