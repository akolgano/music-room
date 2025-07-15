// lib/core/base_provider.dart
import 'package:flutter/material.dart';

abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  bool get hasSuccess => _successMessage != null;
  bool get isReady => !_isLoading && !hasError;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    if (loading) clearMessages();
    notifyListeners();
  }

  void setError(String error) {
    _errorMessage = error;
    _successMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  void setSuccess(String message) {
    _successMessage = message;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    String? successMessage,
    String? errorMessage,
  }) async {
    setLoading(true);
    try {
      final result = await operation();
      if (successMessage != null) {
        setSuccess(successMessage);
      } else {
        setLoading(false);
      }
      return result;
    } catch (e) {
      setError(errorMessage ?? e.toString());
      return null;
    }
  }

  Future<bool> executeBool(
    Future<void> Function() operation, {
    String? successMessage,
    String? errorMessage,
  }) async {
    setLoading(true);
    try {
      await operation();
      if (successMessage != null) {
        setSuccess(successMessage);
      } else {
        setLoading(false);
      }
      return true;
    } catch (e) {
      setError(errorMessage ?? e.toString());
      return false;
    }
  }
}
