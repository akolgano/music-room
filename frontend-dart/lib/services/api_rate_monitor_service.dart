import 'dart:async';
import '../core/navigation_core.dart';

class ApiRateMonitorService {
  static const int _maxRequestsPerMinute = 60;
  static const Duration _windowDuration = Duration(minutes: 1);
  
  final List<DateTime> _requestTimestamps = [];
  Timer? _cleanupTimer;
  
  ApiRateMonitorService() {
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) => _cleanup());
  }
  
  bool canMakeRequest() {
    _cleanup();
    return _requestTimestamps.length < _maxRequestsPerMinute;
  }
  
  void recordRequest() {
    _requestTimestamps.add(DateTime.now());
    AppLogger.debug('API request recorded. Total in window: ${_requestTimestamps.length}', 'ApiRateMonitorService');
  }
  
  int get remainingRequests {
    _cleanup();
    return _maxRequestsPerMinute - _requestTimestamps.length;
  }
  
  Duration? get timeUntilReset {
    if (_requestTimestamps.isEmpty) return null;
    final oldestRequest = _requestTimestamps.first;
    final resetTime = oldestRequest.add(_windowDuration);
    final now = DateTime.now();
    if (resetTime.isAfter(now)) {
      return resetTime.difference(now);
    }
    return null;
  }
  
  void _cleanup() {
    final cutoff = DateTime.now().subtract(_windowDuration);
    _requestTimestamps.removeWhere((timestamp) => timestamp.isBefore(cutoff));
  }
  
  void dispose() {
    _cleanupTimer?.cancel();
  }
  
  Map<String, dynamic> getStats() {
    _cleanup();
    return {
      'currentRequests': _requestTimestamps.length,
      'maxRequests': _maxRequestsPerMinute,
      'remainingRequests': remainingRequests,
      'timeUntilReset': timeUntilReset?.inSeconds,
    };
  }
  
  void startMonitoring() {
    AppLogger.debug('API rate monitoring started', 'ApiRateMonitorService');
  }
  
  void recordApiCall() {
    recordRequest();
  }
}