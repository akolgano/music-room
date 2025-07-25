import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:dio/dio.dart';

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
      if (kDebugMode) {
        debugPrint('[BaseProvider] executeBool error: $e');
        debugPrint('[BaseProvider] Stack trace: ${StackTrace.current}');
      }
      setError(errorMessage ?? _extractErrorMessage(e));
      return false;
    }
  }
  
  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.statusCode == 400 && error.response?.data is Map) {
        final data = error.response!.data as Map<String, dynamic>;
        
        if (kDebugMode) {
          debugPrint('[BaseProvider] 400 error response data: $data');
        }
        
        final errors = <String>[];
        for (final entry in data.entries) {
          if (entry.value is List) {
            final fieldErrors = (entry.value as List).cast<String>();
            errors.addAll(fieldErrors);
          } else if (entry.value is String) {
            errors.add(entry.value);
          }
        }
        
        if (errors.isNotEmpty) {
          return errors.first; // Return the first validation error
        }
      }
      
      switch (error.response?.statusCode) {
        case 401:
          return 'Authentication required. Please log in again.';
        case 403:
          return 'You do not have permission to perform this action.';
        case 404:
          return 'The requested resource was not found.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return 'An error occurred. Please try again.';
      }
    }
    
    return error.toString();
  }
}
