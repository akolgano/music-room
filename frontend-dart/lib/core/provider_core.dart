import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:dio/dio.dart';
import 'locator_core.dart';
import '../providers/connectivity_providers.dart';
import 'navigation_core.dart';

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
      if (kDebugMode) {
        final errorString = e.toString().toLowerCase();
        final isUserCancellation = errorString.contains('popup_closed') || 
                                  errorString.contains('cancelled') ||
                                  errorString.contains('sign-in was cancelled') ||
                                  errorString.contains('facebook login failed') ||
                                  errorString.contains('login cancelled') ||
                                  errorString.contains('user cancelled');
        
        debugPrint('[BaseProvider] executeAsync error: ${_extractErrorMessage(e)}');
        
        if (e is! DioException && !isUserCancellation) {
          debugPrint('[BaseProvider] Full error: $e');
          debugPrint('[BaseProvider] Stack trace: ${StackTrace.current}');
        }
      }
      setError(errorMessage ?? _extractErrorMessage(e));
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
        final errorString = e.toString().toLowerCase();
        final isUserCancellation = errorString.contains('popup_closed') || 
                                  errorString.contains('cancelled') ||
                                  errorString.contains('sign-in was cancelled') ||
                                  errorString.contains('facebook login failed') ||
                                  errorString.contains('login cancelled') ||
                                  errorString.contains('user cancelled');
        
        debugPrint('[BaseProvider] executeBool error: ${_extractErrorMessage(e)}');
        
        if (e is! DioException && !isUserCancellation) {
          debugPrint('[BaseProvider] Full error: $e');
          debugPrint('[BaseProvider] Stack trace: ${StackTrace.current}');
        }
      }
      setError(errorMessage ?? _extractErrorMessage(e));
      return false;
    }
  }
  
  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {

        try {
          final connectivity = getIt<ConnectivityProvider>();
          connectivity.checkConnection();
        } catch (e) {
          AppLogger.debug('Failed to force connectivity check', 'BaseProvider');
        }
        return 'No connection to server. Please check your internet connection.';
      }

      if (error.response?.data is Map) {
        final data = error.response!.data as Map<String, dynamic>;
        
        if (kDebugMode) {
          debugPrint('[BaseProvider] ${error.response?.statusCode} error response data: $data');
        }
        
        if (data['detail'] != null) {
          return data['detail'].toString();
        }
        
        if (data['error'] != null) {
          if (data['error'] is List) {
            final errorList = (data['error'] as List).cast<String>();
            return errorList.join('\n');
          }
          return data['error'].toString();
        }
        
        if (data['message'] != null) {
          return data['message'].toString();
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
          return errors.join('\n');
        }
      } else if (error.response?.data is List) {
        final dataList = error.response!.data as List;
        final errorMessages = dataList.map((e) => e.toString()).toList();
        if (errorMessages.isNotEmpty) {
          return errorMessages.join('\n');
        }
      } else if (error.response?.data is String) {
        return error.response!.data.toString();
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
