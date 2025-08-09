import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:music_room/services/api_service.dart';
import 'package:music_room/models/api_models.dart';
void main() {
  group('API Service Tests', () {
    test('ApiService should be instantiable', () {
      final dio = Dio();
      dio.options.baseUrl = 'http://localhost:8000'
      final apiService = ApiService(dio);
      expect(apiService, isA<ApiService>());
    });
    test('ApiService should be instantiable with custom Dio instance', () {
      final dio = Dio();
      dio.options.baseUrl = 'http://localhost:8000'
      final apiService = ApiService(dio);
      expect(apiService, isA<ApiService>());
    });
    test('LoginRequest should create correct JSON', () {
      const request = LoginRequest(username: 'testuser', password: 'password123');
      final json = request.toJson();
      
      expect(json['username'], 'testuser');
      expect(json['password'], 'password123');
    });
    test('LogoutRequest should create correct JSON', () {
      const request = LogoutRequest(username: 'testuser');
      final json = request.toJson();
      
      expect(json['username'], 'testuser');
    });
    test('ForgotPasswordRequest should create correct JSON', () {
      const request = ForgotPasswordRequest(email: 'test@example.com');
      final json = request.toJson();
      
      expect(json['email'], 'test@example.com');
    });
    test('SignupWithOtpRequest should create correct JSON', () {
      const request = SignupWithOtpRequest(
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
        otp: '123456'
      );
      final json = request.toJson();
      
      expect(json['username'], 'testuser');
      expect(json['email'], 'test@example.com');
      expect(json['password'], 'password123');
      expect(json['otp'], '123456');
    });
    test('PasswordChangeRequest should create correct JSON', () {
      const request = PasswordChangeRequest(
        currentPassword: 'oldpass',
        newPassword: 'newpass'
      );
      final json = request.toJson();
      
      expect(json['current_password'], 'oldpass');
      expect(json['new_password'], 'newpass');
    });
    test('EmailOtpRequest should create correct JSON', () {
      const request = EmailOtpRequest(email: 'test@example.com');
      final json = request.toJson();
      
      expect(json['email'], 'test@example.com');
    });
    test('SocialLoginRequest should handle optional fields', () {
      const request = SocialLoginRequest(
        fbAccessToken: 'fb_token',
        socialId: 'social123'
      );
      final json = request.toJson();
      
      expect(json['fbAccessToken'], 'fb_token');
      expect(json['socialId'], 'social123');
      expect(json.containsKey('idToken'), false);
    });
  });
}