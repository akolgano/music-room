// lib/utils/async_operation_utils.dart
import 'dart:async';
import 'package:flutter/material.dart';

class AsyncOperationUtils {
  
  static Future<T?> executeWithLoading<T>({
    required Future<T> Function() operation,
    required VoidCallback setLoading,
    required VoidCallback clearLoading,
    required Function(String) onError,
    VoidCallback? onSuccess,
    String? successMessage,
    String? errorMessage,
  }) async {
    setLoading();
    
    try {
      final result = await operation();
      clearLoading();
      
      if (successMessage != null) {
      }
      onSuccess?.call();
      
      return result;
    } catch (e) {
      clearLoading();
      onError(errorMessage ?? e.toString());
      return null;
    }
  }

  static Future<bool> executeBool({
    required Future<void> Function() operation,
    required VoidCallback setLoading,
    required VoidCallback clearLoading,
    required Function(String) onError,
    VoidCallback? onSuccess,
    String? successMessage,
    String? errorMessage,
  }) async {
    final result = await executeWithLoading<bool>(
      operation: () async {
        await operation();
        return true;
      },
      setLoading: setLoading,
      clearLoading: clearLoading,
      onError: onError,
      onSuccess: onSuccess,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
    
    return result ?? false;
  }

  static Future<List<T?>> executeSequential<T>(
    List<Future<T> Function()> operations,
    Function(int, int) onProgress,
  ) async {
    final results = <T?>[];
    
    for (int i = 0; i < operations.length; i++) {
      try {
        final result = await operations[i]();
        results.add(result);
      } catch (e) {
        results.add(null);
      }
      
      onProgress(i + 1, operations.length);
    }
    
    return results;
  }

  static Future<List<AsyncResult<T>>> executeParallel<T>(
    List<Future<T> Function()> operations,
  ) async {
    final futures = operations.map((op) async {
      try {
        final result = await op();
        return AsyncResult<T>.success(result);
      } catch (e) {
        return AsyncResult<T>.error(e.toString());
      }
    });
    
    return await Future.wait(futures);
  }

  static Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    double backoffMultiplier = 2.0,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempts = 0;
    Duration currentDelay = initialDelay;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        
        if (attempts >= maxRetries) {
          rethrow;
        }
        
        if (shouldRetry != null && !shouldRetry(e)) {
          rethrow;
        }
        
        await Future.delayed(currentDelay);
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }
    
    throw Exception('Max retries exceeded');
  }

  static Future<T> executeWithTimeout<T>({
    required Future<T> Function() operation,
    required Duration timeout,
    String? timeoutMessage,
  }) async {
    try {
      return await operation().timeout(timeout);
    } catch (e) {
      if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
        throw Exception(timeoutMessage ?? 'Operation timed out');
      }
      rethrow;
    }
  }

  static Function debounce(
    Function function,
    Duration delay,
  ) {
    Timer? timer;
    
    return () {
      timer?.cancel();
      timer = Timer(delay, () => function());
    };
  }

  static Function throttle(
    Function function,
    Duration interval,
  ) {
    bool isThrottled = false;
    
    return () {
      if (!isThrottled) {
        function();
        isThrottled = true;
        Timer(interval, () => isThrottled = false);
      }
    };
  }
}

class AsyncResult<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final DateTime timestamp;

  AsyncResult.success(this.data)
      : isSuccess = true,
        error = null,
        timestamp = DateTime.now();

  AsyncResult.error(this.error)
      : isSuccess = false,
        data = null,
        timestamp = DateTime.now();

  bool get isError => !isSuccess;
  bool get hasData => data != null;
}

mixin AsyncOperationMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  bool get hasSuccess => _successMessage != null;

  void setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
      if (loading) {
        _errorMessage = null;
        _successMessage = null;
      }
    });
  }

  void setError(String error) {
    setState(() {
      _errorMessage = error;
      _successMessage = null;
      _isLoading = false;
    });
  }

  void setSuccess(String message) {
    setState(() {
      _successMessage = message;
      _errorMessage = null;
      _isLoading = false;
    });
  }

  void clearMessages() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
  }

  Future<T?> executeAsync<T>({
    required Future<T> Function() operation,
    String? successMessage,
    String? errorMessage,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    return AsyncOperationUtils.executeWithLoading<T>(
      operation: operation,
      setLoading: () => setLoading(true),
      clearLoading: () => setLoading(false),
      onError: (error) {
        setError(errorMessage ?? error);
        onError?.call();
      },
      onSuccess: () {
        if (successMessage != null) {
          setSuccess(successMessage);
        }
        onSuccess?.call();
      },
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }

  Future<bool> executeBool({
    required Future<void> Function() operation,
    String? successMessage,
    String? errorMessage,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    final result = await executeAsync<bool>(
      operation: () async {
        await operation();
        return true;
      },
      successMessage: successMessage,
      errorMessage: errorMessage,
      onSuccess: onSuccess,
      onError: onError,
    );
    
    return result ?? false;
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

mixin LoadingStateMixin on ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  bool get hasSuccess => _successMessage != null;

  void setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = null;
      _successMessage = null;
    }
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

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<T?> executeAsync<T>({
    required Future<T> Function() operation,
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

  Future<bool> executeBool({
    required Future<void> Function() operation,
    String? successMessage,
    String? errorMessage,
  }) async {
    final result = await executeAsync<bool>(
      operation: () async {
        await operation();
        return true;
      },
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
    
    return result ?? false;
  }
}
