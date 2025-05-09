// lib/providers/base_provider.dart - Optional update if needed
import 'package:flutter/foundation.dart';

mixin BaseProviderMixin on ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasConnectionError = false;
  bool _isRetrying = false;
  int _retryCount = 0;
  final int _maxRetries = 3;
  final int _retryDelaySeconds = 3;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasConnectionError => _hasConnectionError;
  bool get isRetrying => _isRetrying;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void resetError() {
    _errorMessage = null;
    _hasConnectionError = false;
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    _hasConnectionError = true;
    notifyListeners();
  }

  Future<T?> apiCall<T>(Future<T> Function() call, {bool autoRetry = true}) async {
    setLoading(true);
    resetError();
    
    try {
      final result = await call();
      _retryCount = 0;
      return result;
    } catch (error) {
      setError('Unable to connect to server. Please check your internet connection.');
      print('API error: $error');
      
      if (autoRetry && !_isRetrying) {
        _autoRetry(() => apiCall(call, autoRetry: false));
      }
    } finally {
      setLoading(false);
    }
    return null;
  }

  Future<void> _autoRetry(Function apiCall) async {
    if (_retryCount >= _maxRetries) {
      _isRetrying = false;
      notifyListeners();
      return;
    }

    _isRetrying = true;
    _retryCount++;
    notifyListeners();
    
    await Future.delayed(Duration(seconds: _retryDelaySeconds));
    
    try {
      await apiCall();
      _isRetrying = false;
      _retryCount = 0;
      resetError();
    } catch (error) {
      if (_retryCount < _maxRetries) {
        _autoRetry(apiCall);
      } else {
        _isRetrying = false;
        _errorMessage = 'Unable to connect after $_maxRetries attempts. Please try again.';
      }
    }
    
    notifyListeners();
  }
}
