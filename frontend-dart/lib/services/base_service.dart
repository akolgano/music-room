// lib/services/base_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BaseService {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  
  Map<String, String> _getHeaders([String? token]) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Token $token',
  };

  Future<T> handleRequest<T>(
    Future<http.Response> Function() request,
    T Function(Map<String, dynamic>) parser,
  ) async {
    try {
      final response = await request();
      
      if (response.statusCode >= 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Request failed');
      }
      
      return parser(json.decode(response.body));
    } on SocketException {
      throw Exception('Connection error. Check your internet.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<http.Response> get(String endpoint, [String? token]) =>
      http.get(Uri.parse('$_baseUrl$endpoint'), headers: _getHeaders(token));

  Future<http.Response> post(String endpoint, Map<String, dynamic> body, [String? token]) =>
      http.post(Uri.parse('$_baseUrl$endpoint'), headers: _getHeaders(token), body: json.encode(body));
}
