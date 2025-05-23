// lib/utils/api_debug_helper.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiDebugHelper {
  static bool debugMode = kDebugMode; 
  
  static void logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!debugMode) return;
    
    print('\n🚀 API REQUEST');
    print('Method: $method');
    print('URL: $url');
    print('Headers: ${_formatHeaders(headers)}');
    if (body != null) {
      print('Body: ${_formatBody(body)}');
    }
    print('─' * 50);
  }
  
  static void logResponse({
    required String method,
    required String url,
    required http.Response response,
    Duration? duration,
  }) {
    if (!debugMode) return;
    
    final statusEmoji = response.statusCode >= 200 && response.statusCode < 300 
        ? '✅' : '❌';
    
    print('\n$statusEmoji API RESPONSE');
    print('Method: $method');
    print('URL: $url');
    print('Status: ${response.statusCode} ${response.reasonPhrase}');
    if (duration != null) {
      print('Duration: ${duration.inMilliseconds}ms');
    }
    print('Response Headers: ${_formatHeaders(response.headers)}');
    print('Response Body: ${_formatResponseBody(response.body)}');
    print('─' * 50);
  }
  
  static void logError({
    required String method,
    required String url,
    required dynamic error,
    StackTrace? stackTrace,
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!debugMode) return;
    
    print('\n💥 API ERROR');
    print('Method: $method');
    print('URL: $url');
    print('Error Type: ${error.runtimeType}');
    print('Error Message: $error');
    
    if (headers != null) {
      print('Request Headers: ${_formatHeaders(headers)}');
    }
    if (body != null) {
      print('Request Body: ${_formatBody(body)}');
    }
    
    if (error is SocketException) {
      print('Network Error Details:');
      print('  - Host: ${error.address?.host}');
      print('  - Port: ${error.port}');
      print('  - OS Error: ${error.osError}');
    } else if (error is HttpException) {
      print('HTTP Error Details:');
      print('  - Message: ${error.message}');
      print('  - URI: ${error.uri}');
    } else if (error is FormatException) {
      print('Format Error Details:');
      print('  - Source: ${error.source}');
      print('  - Offset: ${error.offset}');
    }
    
    if (stackTrace != null && debugMode) {
      print('Stack Trace:');
      print(stackTrace.toString().split('\n').take(10).join('\n'));
    }
    print('─' * 50);
  }
  
  static String _formatHeaders(Map<String, String>? headers) {
    if (headers == null || headers.isEmpty) return 'None';
    
    return headers.entries.map((e) {
      if (e.key.toLowerCase().contains('authorization') ||
          e.key.toLowerCase().contains('token')) {
        return '${e.key}: [HIDDEN]';
      }
      return '${e.key}: ${e.value}';
    }).join(', ');
  }
  
  static String _formatBody(dynamic body) {
    if (body == null) return 'None';
    
    try {
      if (body is String) {
        final decoded = jsonDecode(body);
        return JsonEncoder.withIndent('  ').convert(decoded);
      }
      return body.toString();
    } catch (e) {
      return body.toString();
    }
  }
  
  static String _formatResponseBody(String body) {
    if (body.isEmpty) return 'Empty';
    
    try {
      final decoded = jsonDecode(body);
      final formatted = JsonEncoder.withIndent('  ').convert(decoded);
      
      if (formatted.length > 1000) {
        return '${formatted.substring(0, 1000)}...\n[Response truncated - ${formatted.length} characters total]';
      }
      return formatted;
    } catch (e) {
      if (body.length > 500) {
        return '${body.substring(0, 500)}...\n[Response truncated - ${body.length} characters total]';
      }
      return body;
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;
  final String method;
  final String url;
  
  ApiException({
    required this.message,
    this.statusCode,
    this.responseBody,
    required this.method,
    required this.url,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer('ApiException: $message');
    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }
    return buffer.toString();
  }
}

class NetworkException extends ApiException {
  NetworkException({
    required String method,
    required String url,
    String? message,
  }) : super(
    message: message ?? 'Network connection failed',
    method: method,
    url: url,
  );
}

class ServerException extends ApiException {
  ServerException({
    required int statusCode,
    required String method,
    required String url,
    String? responseBody,
  }) : super(
    message: 'Server error occurred',
    statusCode: statusCode,
    responseBody: responseBody,
    method: method,
    url: url,
  );
}

class ParseException extends ApiException {
  ParseException({
    required String method,
    required String url,
    String? responseBody,
  }) : super(
    message: 'Failed to parse server response',
    responseBody: responseBody,
    method: method,
    url: url,
  );
}
