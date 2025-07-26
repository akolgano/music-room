import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/models/music_models.dart';
import 'package:music_room/models/api_models.dart';

void main() {
  group('AuthService Tests', () {
    group('User Model Tests', () {
      test('User model should have required properties', () {
        const user = User(id: '1', username: 'testuser', email: 'test@example.com');
        
        expect(user.id, '1');
        expect(user.username, 'testuser');
        expect(user.email, 'test@example.com');
      });

      test('User toJson should serialize correctly', () {
        const user = User(id: '1', username: 'testuser', email: 'test@example.com');
        final json = user.toJson();
        
        expect(json['id'], '1');
        expect(json['username'], 'testuser');
        expect(json['email'], 'test@example.com');
      });

      test('User fromJson should deserialize correctly', () {
        final json = {'id': '1', 'username': 'testuser', 'email': 'test@example.com'};
        final user = User.fromJson(json);
        
        expect(user.id, '1');
        expect(user.username, 'testuser');
        expect(user.email, 'test@example.com');
      });
    });

    group('AuthResult Model Tests', () {
      test('AuthResult model should have required properties', () {
        const user = User(id: '1', username: 'testuser', email: 'test@example.com');
        const authResult = AuthResult(token: 'test_token', user: user);
        
        expect(authResult.token, 'test_token');
        expect(authResult.user.username, 'testuser');
      });
    });

    group('Login Request Tests', () {
      test('LoginRequest should serialize correctly', () {
        final request = LoginRequest(username: 'testuser', password: 'password123');
        final json = request.toJson();
        
        expect(json['username'], 'testuser');
        expect(json['password'], 'password123');
      });
    });

    group('Social Login Request Tests', () {
      test('SocialLoginRequest should create valid objects', () {
        final fbRequest = SocialLoginRequest(fbAccessToken: 'fb_token');
        final googleRequest = SocialLoginRequest(idToken: 'google_id_token');
        final webRequest = SocialLoginRequest(
          socialId: 'social_id',
          socialEmail: 'google@example.com',
          socialName: 'Google User'
        );
        
        expect(fbRequest.toJson().isNotEmpty, true);
        expect(googleRequest.toJson().isNotEmpty, true);
        expect(webRequest.toJson().isNotEmpty, true);
      });
    });

    group('Signup Request Tests', () {
      test('SignupWithOtpRequest should serialize correctly', () {
        final request = SignupWithOtpRequest(
          username: 'newuser',
          email: 'new@example.com',
          password: 'password123',
          otp: '123456'
        );
        final json = request.toJson();
        
        expect(json['username'], 'newuser');
        expect(json['email'], 'new@example.com');
        expect(json['password'], 'password123');
        expect(json['otp'], '123456');
      });
    });

    group('Email OTP Request Tests', () {
      test('EmailOtpRequest should serialize correctly', () {
        final request = EmailOtpRequest(email: 'test@example.com');
        final json = request.toJson();
        
        expect(json['email'], 'test@example.com');
      });
    });

    group('Logout Request Tests', () {
      test('LogoutRequest should handle username', () {
        final request = LogoutRequest(username: 'testuser');
        final json = request.toJson();
        
        expect(json.isNotEmpty, true);
        expect(json['username'], 'testuser');
      });
    });
  });
}