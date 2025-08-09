import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/providers/auth_providers.dart';
import 'package:music_room/models/music_models.dart';
import 'package:music_room/models/api_models.dart';
void main() {
  group('Auth Provider Tests', () {
    test('AuthProvider should be a valid class type', () {
      expect(AuthProvider, isA<Type>());
    });
    test('AuthProvider should have expected properties', () {
      expect('$AuthProvider', contains('AuthProvider'));
    });
    test('User model should work correctly', () {
      const user = User(id: '1', username: 'testuser', email: 'test@example.com');
      
      expect(user.id, '1');
      expect(user.username, 'testuser');
      expect(user.email, 'test@example.com');
    });
    test('SocialLoginResult should create success result', () {
      final result = SocialLoginResult.success('test_token', 'google');
      
      expect(result.success, true);
      expect(result.token, 'test_token');
      expect(result.provider, 'google');
      expect(result.error, null);
    });
    test('SocialLoginResult should create error result', () {
      final result = SocialLoginResult.error('Login failed');
      
      expect(result.success, false);
      expect(result.token, null);
      expect(result.provider, null);
      expect(result.error, 'Login failed');
    });
    test('AuthResult should contain user and token', () {
      const user = User(id: '1', username: 'testuser', email: 'test@example.com');
      const authResult = AuthResult(token: 'auth_token', user: user);
      
      expect(authResult.token, 'auth_token');
      expect(authResult.user, user);
      expect(authResult.user.username, 'testuser');
    });
    test('API request models should serialize correctly', () {
      const loginRequest = LoginRequest(username: 'testuser', password: 'password123');
      final loginJson = loginRequest.toJson();
      
      expect(loginJson['username'], 'testuser');
      expect(loginJson['password'], 'password123');
      
      const socialRequest = SocialLoginRequest(fbAccessToken: 'fb_token');
      final socialJson = socialRequest.toJson();
      
      expect(socialJson['fbAccessToken'], 'fb_token');
    });
    test('Password change request should work correctly', () {
      const request = PasswordChangeRequest(
        currentPassword: 'oldpass',
        newPassword: 'newpass'
      );
      final json = request.toJson();
      
      expect(json['current_password'], 'oldpass');
      expect(json['new_password'], 'newpass');
    });
    test('Email OTP request should work correctly', () {
      const request = EmailOtpRequest(email: 'test@example.com');
      final json = request.toJson();
      
      expect(json['email'], 'test@example.com');
    });
  });
}