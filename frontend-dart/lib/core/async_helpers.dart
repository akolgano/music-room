// lib/core/async_helpers.dart
class AsyncHelpers {
  static Future<bool> executeOperation<T>({
    required Future<T> Function() operation,
    Function(String)? onError,
    Function(T)? onSuccess,
  }) async {
    try {
      final result = await operation();
      onSuccess?.call(result);
      return true;
    } catch (e) {
      onError?.call(e.toString());
      return false;
    }
  }
}
