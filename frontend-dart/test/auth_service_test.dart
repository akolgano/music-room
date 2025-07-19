import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:music_room/services/auth_service.dart';
import 'package:music_room/services/api_service.dart';
import 'package:music_room/services/storage_service.dart';
import 'package:music_room/models/models.dart';
import 'package:music_room/models/api_models.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([ApiService, StorageService])
void main() {
  group('AuthService Tests', () {
    late AuthService authService;
    late MockApiService mockApiService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockApiService = MockApiService();
      mockStorageService = MockStorageService();
      authService = AuthService(mockApiService, mockStorageService);
    });

    group('login', () {
      test('should authenticate user and store credentials', () async {
        const user = User(id: '1', username: 'testuser', email: 'test@example.com');
        const authResult = AuthResult(token: 'test_token', user: user);
        
        when(mockApiService.login(any)).thenAnswer((_) async => authResult);
        when(mockStorageService.set(any, any)).thenAnswer((_) async => {});

        final result = await authService.login('testuser', 'password123');

        expect(result.token, 'test_token');
        expect(result.user.username, 'testuser');
        expect(authService.currentToken, 'test_token');
        expect(authService.currentUser?.username, 'testuser');
        expect(authService.isLoggedIn, true);

        verify(mockStorageService.set('auth_token', 'test_token')).called(1);
        verify(mockStorageService.set('current_user', user.toJson())).called(1);
      });

      test('should throw exception on invalid credentials', () async {
        when(mockApiService.login(any)).thenThrow(Exception('Invalid credentials'));

        expect(
          () => authService.login('wronguser', 'wrongpass'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('logout', () {
      test('should clear stored authentication data', () async {
        when(mockApiService.logout(any, any)).thenAnswer((_) async => {});
        when(mockStorageService.delete(any)).thenAnswer((_) async => {});

        // Login first to have data to clear
        const user = User(id: '1', username: 'testuser', email: 'test@example.com');
        const authResult = AuthResult(token: 'test_token', user: user);
        when(mockApiService.login(any)).thenAnswer((_) async => authResult);
        when(mockStorageService.set(any, any)).thenAnswer((_) async => {});
        await authService.login('testuser', 'password123');

        await authService.logout();

        expect(authService.currentToken, null);
        expect(authService.currentUser, null);
        expect(authService.isLoggedIn, false);

        verify(mockStorageService.delete('auth_token')).called(greaterThanOrEqualTo(1));
        verify(mockStorageService.delete('current_user')).called(greaterThanOrEqualTo(1));
      });

      test('should clear data even if API call fails', () async {
        when(mockApiService.logout(any, any)).thenThrow(Exception('Network error'));
        when(mockStorageService.delete(any)).thenAnswer((_) async => {});

        // Login first to have data to clear
        const user = User(id: '1', username: 'testuser', email: 'test@example.com');
        const authResult = AuthResult(token: 'test_token', user: user);
        when(mockApiService.login(any)).thenAnswer((_) async => authResult);
        when(mockStorageService.set(any, any)).thenAnswer((_) async => {});
        await authService.login('testuser', 'password123');

        await authService.logout();

        expect(authService.currentToken, null);
        expect(authService.currentUser, null);
        expect(authService.isLoggedIn, false);

        verify(mockStorageService.delete('auth_token')).called(greaterThanOrEqualTo(1));
        verify(mockStorageService.delete('current_user')).called(greaterThanOrEqualTo(1));
      });
    });

    group('social login', () {
      test('should handle Facebook login', () async {
        const user = User(id: '1', username: 'fbuser', email: 'fb@example.com');
        const authResult = AuthResult(token: 'fb_token', user: user);
        
        when(mockApiService.facebookLogin(any)).thenAnswer((_) async => authResult);
        when(mockStorageService.set(any, any)).thenAnswer((_) async => {});

        final result = await authService.facebookLogin('fb_access_token');

        expect(result.token, 'fb_token');
        expect(result.user.username, 'fbuser');
        expect(authService.isLoggedIn, true);

        final capturedRequest = verify(mockApiService.facebookLogin(captureAny)).captured.single;
        expect(capturedRequest.fbAccessToken, 'fb_access_token');
      });

      test('should handle Google login with ID token', () async {
        const user = User(id: '1', username: 'googleuser', email: 'google@example.com');
        const authResult = AuthResult(token: 'google_token', user: user);
        
        when(mockApiService.googleLogin(any)).thenAnswer((_) async => authResult);
        when(mockStorageService.set(any, any)).thenAnswer((_) async => {});

        final result = await authService.googleLoginApp('google_id_token');

        expect(result.token, 'google_token');
        expect(authService.isLoggedIn, true);

        final capturedRequest = verify(mockApiService.googleLogin(captureAny)).captured.single;
        expect(capturedRequest.idToken, 'google_id_token');
      });

      test('should handle Google web login', () async {
        const user = User(id: '1', username: 'googleuser', email: 'google@example.com');
        const authResult = AuthResult(token: 'google_token', user: user);
        
        when(mockApiService.googleLogin(any)).thenAnswer((_) async => authResult);
        when(mockStorageService.set(any, any)).thenAnswer((_) async => {});

        final result = await authService.googleLoginWeb(
          'social_id', 
          'google@example.com', 
          'Google User'
        );

        expect(result.token, 'google_token');
        expect(authService.isLoggedIn, true);

        final capturedRequest = verify(mockApiService.googleLogin(captureAny)).captured.single;
        expect(capturedRequest.socialId, 'social_id');
        expect(capturedRequest.socialEmail, 'google@example.com');
        expect(capturedRequest.socialName, 'Google User');
      });
    });

    group('signup with OTP', () {
      test('should send signup email OTP', () async {
        when(mockApiService.sendSignupEmailOtp(any)).thenAnswer((_) async => {});

        await authService.sendSignupEmailOtp('test@example.com');

        final capturedRequest = verify(mockApiService.sendSignupEmailOtp(captureAny)).captured.single;
        expect(capturedRequest.email, 'test@example.com');
      });

      test('should complete signup with OTP and store credentials', () async {
        const user = User(id: '1', username: 'newuser', email: 'new@example.com');
        const authResult = AuthResult(token: 'new_token', user: user);
        
        when(mockApiService.signupWithOtp(any)).thenAnswer((_) async => authResult);
        when(mockStorageService.set(any, any)).thenAnswer((_) async => {});

        final result = await authService.signupWithOtp(
          'newuser', 
          'new@example.com', 
          'password123', 
          '123456'
        );

        expect(result.token, 'new_token');
        expect(result.user.username, 'newuser');
        expect(authService.isLoggedIn, true);

        final capturedRequest = verify(mockApiService.signupWithOtp(captureAny)).captured.single;
        expect(capturedRequest.username, 'newuser');
        expect(capturedRequest.email, 'new@example.com');
        expect(capturedRequest.password, 'password123');
        expect(capturedRequest.otp, '123456');
      });
    });

    group('state management', () {
      test('should correctly report login status when not logged in', () {
        expect(authService.isLoggedIn, false);
        expect(authService.currentToken, null);
        expect(authService.currentUser, null);
      });

      test('should provide access to API service', () {
        expect(authService.api, mockApiService);
      });
    });

    group('_loadStoredAuth', () {
      test('should load stored authentication data on initialization', () async {
        const userData = {'id': '1', 'username': 'storeduser', 'email': 'stored@example.com'};
        
        when(mockStorageService.get<String>('auth_token')).thenReturn('stored_token');
        when(mockStorageService.getMap('current_user')).thenReturn(userData);

        final newAuthService = AuthService(mockApiService, mockStorageService);
        
        await Future.delayed(Duration.zero);

        expect(newAuthService.currentToken, 'stored_token');
        expect(newAuthService.currentUser?.username, 'storeduser');
        expect(newAuthService.isLoggedIn, true);
      });

      test('should handle corrupted stored data gracefully', () async {
        when(mockStorageService.get<String>('auth_token')).thenThrow(Exception('Storage error'));
        when(mockStorageService.delete(any)).thenAnswer((_) async => {});

        final newAuthService = AuthService(mockApiService, mockStorageService);
        
        await Future.delayed(Duration.zero);

        expect(newAuthService.currentToken, null);
        expect(newAuthService.currentUser, null);
        expect(newAuthService.isLoggedIn, false);

        verify(mockStorageService.delete('auth_token')).called(greaterThanOrEqualTo(1));
        verify(mockStorageService.delete('current_user')).called(greaterThanOrEqualTo(1));
      });
    });
  });
}