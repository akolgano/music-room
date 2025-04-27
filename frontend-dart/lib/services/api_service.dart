import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() {
    return 'ApiException: $message${statusCode != null ? ' (Status code: $statusCode)' : ''}';
  }
}

class ApiService {
  late final String baseUrl;
  
  ApiService() {
    baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api';
  }

  Future<Map<String, dynamic>> get(String endpoint, {String? token}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    
    return _processResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String endpoint, 
    Map<String, dynamic> data, 
    {String? token}
  ) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    
    return _processResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String endpoint, 
    Map<String, dynamic> data, 
    {String? token}
  ) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    
    return _processResponse(response);
  }

  Future<Map<String, dynamic>> delete(String endpoint, {String? token}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    
    return _processResponse(response);
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      Map<String, dynamic> errorBody = {};
      try {
        errorBody = json.decode(response.body);
      } catch (_) {}
      
      final errorMessage = errorBody['message'] ?? 'Unknown error occurred';
      throw ApiException(errorMessage, statusCode: response.statusCode);
    }
  }
}
