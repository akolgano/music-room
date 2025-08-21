import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../core/provider_core.dart';
import '../core/locator_core.dart';
import '../services/api_services.dart';

enum ConnectionStatus { connected, disconnected, checking }

class ConnectivityProvider extends BaseProvider {
  ConnectionStatus _connectionStatus = ConnectionStatus.checking;
  DateTime? _lastConnectedTime;
  Timer? _healthCheckTimer;
  
  static const Duration _initialHealthCheckInterval = Duration(seconds: 30);
  static const Duration _maxHealthCheckInterval = Duration(minutes: 10);
  Duration _currentHealthCheckInterval = _initialHealthCheckInterval;
  int _consecutiveFailures = 0;
  
  static const Duration _timeoutDuration = Duration(seconds: 5);

  ConnectionStatus get connectionStatus => _connectionStatus;
  bool get isConnected => _connectionStatus == ConnectionStatus.connected;
  bool get isDisconnected => _connectionStatus == ConnectionStatus.disconnected;
  bool get isChecking => _connectionStatus == ConnectionStatus.checking;
  DateTime? get lastConnectedTime => _lastConnectedTime;
  Duration get currentCheckInterval => _currentHealthCheckInterval;
  int get consecutiveFailures => _consecutiveFailures;

  ConnectivityProvider() {
    _initializeHealthCheck();
  }

  void _initializeHealthCheck() {
    checkConnection();
    _startHealthCheckTimer();
  }

  void _startHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(
      _currentHealthCheckInterval,
      (_) => checkConnection(),
    );
    
    if (kDebugMode) {
      debugPrint('[ConnectivityProvider] Health check timer started with interval: ${_currentHealthCheckInterval.inSeconds}s');
    }
  }

  Future<void> checkConnection() async {
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
      
      _onConnectionSuccess();
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConnectivityProvider] Connection check failed: $e');
      }
      _setConnectionStatus(ConnectionStatus.disconnected);
      
      _onConnectionFailure();
    }
  }

  void _onConnectionSuccess() {
    if (_consecutiveFailures > 0 || _currentHealthCheckInterval != _initialHealthCheckInterval) {
      _consecutiveFailures = 0;
      _currentHealthCheckInterval = _initialHealthCheckInterval;
      
      if (kDebugMode) {
        debugPrint('[ConnectivityProvider] Connection restored, resetting interval to ${_currentHealthCheckInterval.inSeconds}s');
      }
      
      _startHealthCheckTimer();
    }
  }

  void _onConnectionFailure() {
    _consecutiveFailures++;
    
    final newInterval = Duration(
      milliseconds: (_initialHealthCheckInterval.inMilliseconds * 
          (1 << (_consecutiveFailures - 1).clamp(0, 8))).toInt()
    );
    
    final cappedInterval = newInterval > _maxHealthCheckInterval ? _maxHealthCheckInterval : newInterval;
    
    if (cappedInterval != _currentHealthCheckInterval) {
      _currentHealthCheckInterval = cappedInterval;
      
      if (kDebugMode) {
        debugPrint('[ConnectivityProvider] Connection failed $_consecutiveFailures times, increasing interval to ${_currentHealthCheckInterval.inSeconds}s');
      }
      
      _startHealthCheckTimer();
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
        if (_lastConnectedTime == null) return 'Connected';
        final timeAgo = DateTime.now().difference(_lastConnectedTime!);
        if (timeAgo.inMinutes < 1) {
          return 'Connected (just now)';
        } else if (timeAgo.inHours < 1) {
          return 'Connected (${timeAgo.inMinutes}m ago)';
        } else {
          return 'Connected (${timeAgo.inHours}h ago)';
        }
      case ConnectionStatus.disconnected:
        String baseMessage;
        if (_lastConnectedTime == null) {
          baseMessage = 'Offline';
        } else {
          final timeAgo = DateTime.now().difference(_lastConnectedTime!);
          if (timeAgo.inMinutes < 1) {
            baseMessage = 'Offline (lost connection (just now)';
          } else if (timeAgo.inHours < 1) {
            baseMessage = 'Offline (lost connection (${timeAgo.inMinutes}m ago)';
          } else {
            baseMessage = 'Offline (lost connection (${timeAgo.inHours}h ago)';
          }
        }
        
        if (_consecutiveFailures > 0 && _currentHealthCheckInterval != _initialHealthCheckInterval) {
          final nextCheckIn = _currentHealthCheckInterval.inSeconds;
          return '$baseMessage • Next check in ${nextCheckIn}s';
        }
        return baseMessage;
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
