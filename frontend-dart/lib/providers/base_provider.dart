// lib/providers/base_provider.dart
import 'package:flutter/material.dart';

mixin BaseProvider on ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<T?> execute<T>(Future<T> Function() operation) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await operation();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> performAction(
    Future<void> Function() action, {
    String? successMessage,
    String? errorMessage,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    setLoading(true);
    clearError();

    try {
      await action();
      if (successMessage != null) {
      }
      onSuccess?.call();
    } catch (e) {
      final message = errorMessage ?? e.toString();
      setError(message);
      onError?.call();
    } finally {
      setLoading(false);
    }
  }

  Future<T?> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    String? errorPrefix,
  }) async {
    Exception? lastException;
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await execute(operation);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        if (attempt == maxRetries - 1) {
          final prefix = errorPrefix ?? 'Operation failed after $maxRetries attempts';
          setError('$prefix: ${lastException.toString()}');
          break;
        }
        await Future.delayed(delay);
      }
    }
    return null;
  }

  Future<List<T>> executeBatch<T>(
    List<Future<T> Function()> operations, {
    bool stopOnFirstError = false,
    String? batchName,
  }) async {
    setLoading(true);
    clearError();

    final results = <T>[];
    final errors = <String>[];

    try {
      for (int i = 0; i < operations.length; i++) {
        try {
          final result = await operations[i]();
          results.add(result);
        } catch (e) {
          final errorMsg = '${batchName ?? 'Operation'} ${i + 1}: ${e.toString()}';
          errors.add(errorMsg);
          
          if (stopOnFirstError) {
            setError(errorMsg);
            break;
          }
        }
      }

      if (errors.isNotEmpty && !stopOnFirstError) {
        setError('${errors.length} of ${operations.length} operations failed:\n${errors.join('\n')}');
      }

      return results;
    } finally {
      setLoading(false);
    }
  }

  Future<T?> executeWithTimeout<T>(
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 30),
    String? timeoutMessage,
  }) async {
    return await execute(() async {
      return await operation().timeout(
        timeout,
        onTimeout: () {
          throw Exception(timeoutMessage ?? 'Operation timed out after ${timeout.inSeconds} seconds');
        },
      );
    });
  }

  void reset() {
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<T?> safeExecute<T>(
    Future<T> Function() operation, {
    T? fallbackValue,
    bool silent = false,
  }) async {
    try {
      _isLoading = true;
      if (!silent) notifyListeners();
      
      final result = await operation();
      
      if (_errorMessage != null && !silent) {
        clearError();
      }
      
      return result;
    } catch (e) {
      if (!silent) {
        _errorMessage = e.toString();
      }
      return fallbackValue;
    } finally {
      _isLoading = false;
      if (!silent) notifyListeners();
    }
  }

  void executeSync(
    void Function() operation, {
    String? errorMessage,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) {
    try {
      clearError();
      operation();
      onSuccess?.call();
    } catch (e) {
      setError(errorMessage ?? e.toString());
      onError?.call();
    }
  }

  Future<Map<String, T?>> executeParallel<T>(
    Map<String, Future<T> Function()> operations, {
    Duration? timeout,
  }) async {
    setLoading(true);
    clearError();

    try {
      final futures = operations.map((key, operation) => 
        MapEntry(key, operation().catchError((e) => null as T?)));

      final results = timeout != null
        ? await Future.wait(
            futures.values,
            eagerError: false,
          ).timeout(timeout)
        : await Future.wait(
            futures.values,
            eagerError: false,
          );

      final resultMap = <String, T?>{};
      final keys = futures.keys.toList();
      
      for (int i = 0; i < keys.length; i++) {
        resultMap[keys[i]] = results[i];
      }

      return resultMap;
    } catch (e) {
      setError(e.toString());
      return <String, T?>{};
    } finally {
      setLoading(false);
    }
  }

  Stream<T?> executeStream<T>(
    Stream<T> Function() streamOperation, {
    void Function(String)? onError,
  }) async* {
    setLoading(true);
    clearError();

    try {
      await for (final value in streamOperation()) {
        yield value;
      }
    } catch (e) {
      setError(e.toString());
      onError?.call(e.toString());
      yield null;
    } finally {
      setLoading(false);
    }
  }

  Future<void> delay([Duration duration = const Duration(milliseconds: 500)]) async {
    await Future.delayed(duration);
  }

  void notifyError(String message) {
    setError(message);
  }

  void notifySuccess() {
    clearError();
  }

  bool get isIdle => !_isLoading && !hasError;
  bool get isReady => !_isLoading;
}
