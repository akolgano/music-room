// lib/utils/enhanced_api_methods.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'api_debug_helper.dart';

mixin EnhancedApiMixin on ChangeNotifier {
  bool _isLoading = false;
  bool _isRetrying = false;
  String? _errorMessage;
  String? _lastErrorDetails;

  bool get isLoading => _isLoading;
  bool get isRetrying => _isRetrying;
  String? get errorMessage => _errorMessage;
  String? get lastErrorDetails => _lastErrorDetails;
  bool get hasError => _errorMessage != null;
  bool get hasConnectionError => _errorMessage?.contains('Connection') ?? false;

  void clearError() {
    _errorMessage = null;
    _lastErrorDetails = null;
    notifyListeners();
  }

  Future<T?> apiCall<T>(
    Future<T> Function() call, {
    String? debugContext,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _lastErrorDetails = null;
    notifyListeners();

    try {
      final result = await call();
      return result;
    } catch (e, stackTrace) {
      _handleError(e, stackTrace, debugContext);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<T?> apiCallWithRetry<T>(
    Future<T> Function() call, {
    String? debugContext,
    int maxRetries = 1,
  }) async {
    _isRetrying = true;
    _errorMessage = null;
    _lastErrorDetails = null;
    notifyListeners();

    try {
      final result = await call();
      return result;
    } catch (e, stackTrace) {
      _handleError(e, stackTrace, debugContext);
      return null;
    } finally {
      _isRetrying = false;
      notifyListeners();
    }
  }

  Future<http.Response> enhancedHttpRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    ApiDebugHelper.logRequest(
      method: method,
      url: url,
      headers: headers,
      body: body,
    );

    try {
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(
            Uri.parse(url),
            headers: headers,
          ).timeout(timeout);
          break;
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: body,
          ).timeout(timeout);
          break;
        case 'PUT':
          response = await http.put(
            Uri.parse(url),
            headers: headers,
            body: body,
          ).timeout(timeout);
          break;
        case 'DELETE':
          response = await http.delete(
            Uri.parse(url),
            headers: headers,
          ).timeout(timeout);
          break;
        case 'PATCH':
          response = await http.patch(
            Uri.parse(url),
            headers: headers,
            body: body,
          ).timeout(timeout);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }

      stopwatch.stop();
      
      ApiDebugHelper.logResponse(
        method: method,
        url: url,
        response: response,
        duration: stopwatch.elapsed,
      );

      if (response.statusCode >= 400) {
        throw ServerException(
          statusCode: response.statusCode,
          method: method,
          url: url,
          responseBody: response.body,
        );
      }

      return response;
    } on SocketException catch (e, stackTrace) {
      stopwatch.stop();
      ApiDebugHelper.logError(
        method: method,
        url: url,
        error: e,
        stackTrace: stackTrace,
        headers: headers,
        body: body,
      );
      throw NetworkException(method: method, url: url, message: e.message);
    } on HttpException catch (e, stackTrace) {
      stopwatch.stop();
      ApiDebugHelper.logError(
        method: method,
        url: url,
        error: e,
        stackTrace: stackTrace,
        headers: headers,
        body: body,
      );
      throw NetworkException(method: method, url: url, message: e.message);
    } on FormatException catch (e, stackTrace) {
      stopwatch.stop();
      ApiDebugHelper.logError(
        method: method,
        url: url,
        error: e,
        stackTrace: stackTrace,
        headers: headers,
        body: body,
      );
      throw ParseException(method: method, url: url);
    } catch (e, stackTrace) {
      stopwatch.stop();
      ApiDebugHelper.logError(
        method: method,
        url: url,
        error: e,
        stackTrace: stackTrace,
        headers: headers,
        body: body,
      );
      rethrow;
    }
  }

  void _handleError(dynamic error, StackTrace stackTrace, String? context) {
    if (error is ApiException) {
      _errorMessage = error.message;
      _lastErrorDetails = '''
Context: ${context ?? 'Unknown'}
URL: ${error.url}
Method: ${error.method}
Status Code: ${error.statusCode ?? 'N/A'}
Response: ${error.responseBody ?? 'No response body'}
''';
    } else if (error is SocketException) {
      _errorMessage = 'Connection error. Please check your internet connection.';
      _lastErrorDetails = '''
Context: ${context ?? 'Unknown'}
Network Error: ${error.message}
Host: ${error.address?.host ?? 'Unknown'}
Port: ${error.port ?? 'Unknown'}
OS Error: ${error.osError?.message ?? 'Unknown'}
''';
    } else if (error is HttpException) {
      _errorMessage = 'HTTP error occurred.';
      _lastErrorDetails = '''
Context: ${context ?? 'Unknown'}
HTTP Error: ${error.message}
URI: ${error.uri}
''';
    } else {
      _errorMessage = 'An unexpected error occurred.';
      _lastErrorDetails = '''
Context: ${context ?? 'Unknown'}
Error Type: ${error.runtimeType}
Error: $error
Stack Trace: ${stackTrace.toString().split('\n').take(5).join('\n')}
''';
    }
  }
}
