// lib/services/profile_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/app_core.dart';


class ProfileApiService {
  static final ProfileApiService _instance = ProfileApiService._internal();
  factory ProfileApiService() => _instance;
  ProfileApiService._internal();

  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? AppConstants.defaultApiBaseUrl;
  
  Map<String, String> _getHeaders([String? token]) => {
    'Content-Type': AppConstants.contentTypeJson,
    if (token != null) 'Authorization': '${AppConstants.authorizationPrefix} $token',
  };

  Future<T> _handleRequest<T>(
    Future<http.Response> Function() request,
    T Function(Map<String, dynamic>) parser,
  ) async {
    try {
      final response = await request();
      if (response.statusCode >= 400) {
        String errorMessage;
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? errorData['detail'] ?? '${AppStrings.error}: ${response.statusCode}';
        } catch (e) {
          errorMessage = '${AppStrings.error}: ${response.statusCode}';
        }
        throw ApiException(errorMessage);
      }
      final data = json.decode(response.body);
      return parser(data);
    } on SocketException {
      throw ApiException(AppStrings.connectionErrorMessage);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> updateAvatar(String? token, String? avatarBase64, String? mimeType) async {
    return _handleRequest(
      () => http.post(
        Uri.parse('$_baseUrl/profile/public/update/'),
        headers: _getHeaders(token),
        body: json.encode({'avatarBase64': avatarBase64, 'mimeType': mimeType}),
      ),
      (data) => data,
    );
  }

  Future<Map<String, dynamic>> getProfilePublic(String? token) async {
    return _handleRequest(
        () => http.get(
          Uri.parse('$_baseUrl/profile/public/'),
          headers: _getHeaders(token),
        ),
        (data) => data,
      );
  }

  Future<Map<String, dynamic>> updatePublicBasic(String? token, String? gender, String? location) async {
      return _handleRequest(
        () => http.post(
          Uri.parse('$_baseUrl/profile/public/update/'),
          headers: _getHeaders(token),
          body: json.encode({'gender': gender, 'location': location}),
        ),
        (data) => data,
      );
  }

  Future<Map<String, dynamic>> updatePublicBio(String? token, String? bio) async {
      return _handleRequest(
        () => http.post(
          Uri.parse('$_baseUrl/profile/public/update/'),
          headers: _getHeaders(token),
          body: json.encode({'bio': bio}),
        ),
        (data) => data,
      );
  }

  Future<Map<String, dynamic>> updatePrivateInfo(String? token, String? firstName, String? lastName, String? phone, String? street, String? country, String? postalCode) async {
      return _handleRequest(
        () => http.post(
          Uri.parse('$_baseUrl/profile/private/update/'),
          headers: _getHeaders(token),
          body: json.encode({'firstName': firstName, 
                             'lastName': lastName,
                             'phone': phone,
                             'street': street,
                             'country': country,
                             'postalCode': postalCode,
                            }),
        ),
        (data) => data,
      );
  }

  Future<Map<String, dynamic>> getProfilePrivate(String? token) async {
    return _handleRequest(
        () => http.get(
          Uri.parse('$_baseUrl/profile/private/'),
          headers: _getHeaders(token),
        ),
        (data) => data,
      );
  }

  Future<Map<String, dynamic>> updateFriendInfo(String? token, String? dob, List<String>? hobbies, String? friendInfo) async {
      return _handleRequest(
        () => http.post(
          Uri.parse('$_baseUrl/profile/friend/update/'),
          headers: _getHeaders(token),
          body: json.encode({'dob': dob,
                             'hobbies': hobbies,
                             'friendInfo': friendInfo,
                            }),
        ),
        (data) => data,
      );
  }

  Future<Map<String, dynamic>> getProfileFriend(String? token) async {
    return _handleRequest(
        () => http.get(
          Uri.parse('$_baseUrl/profile/friend/'),
          headers: _getHeaders(token),
        ),
        (data) => data,
      );
  }

  Future<Map<String, dynamic>> updateMusicPreferences(String? token, List<String>? musicPreferences) async {
      return _handleRequest(
        () => http.post(
          Uri.parse('$_baseUrl/profile/music/update/'),
          headers: _getHeaders(token),
          body: json.encode({'musicPreferences': musicPreferences,
                            }),
        ),
        (data) => data,
      );
  }

  Future<Map<String, dynamic>> getProfileMusic(String? token) async {
    return _handleRequest(
        () => http.get(
          Uri.parse('$_baseUrl/profile/music/'),
          headers: _getHeaders(token),
        ),
        (data) => data,
      );
  }


}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}