import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:music_room/providers/auth_providers.dart';
import 'package:music_room/services/auth_services.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/services/websocket_services.dart';
import 'package:music_room/services/logging_services.dart';
import 'package:music_room/services/player_services.dart';
import 'package:music_room/models/api_models.dart';
import 'package:music_room/models/music_models.dart';
import 'package:music_room/core/locator_core.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

@GenerateMocks([AuthService, ApiService, WebSocketService, FrontendLoggingService, MusicPlayerService, GoogleSignIn])
import 'auth_providers_test.mocks.dart';

void main() {
  group('AuthProvider Tests', () {
    late AuthProvider authProvider;
    late MockAuthService mockAuthService;
    late MockApiService mockApiService;
    late MockWebSocketService mockWebSocketService;
    late MockFrontendLoggingService mockLoggingService;
    late MockMusicPlayerService mockPlayerService;
    late MockGoogleSignIn mockGoogleSignIn;

    setUp(() {
      GetIt.instance.reset();
      mockAuthService = MockAuthService();
      mockApiService = MockApiService();
      mockWebSocketService = MockWebSocketService();
      mockLoggingService = MockFrontendLoggingService();
      mockPlayerService = MockMusicPlayerService();
      mockGoogleSignIn = MockGoogleSignIn();
      
      getIt.registerSingleton<AuthService>(mockAuthService);
      getIt.registerSingleton<ApiService>(mockApiService);
      getIt.registerSingleton<WebSocketService>(mockWebSocketService);
      getIt.registerSingleton<FrontendLoggingService>(mockLoggingService);
      getIt.registerSingleton<MusicPlayerService>(mockPlayerService);
      
      when(mockAuthService.api).thenReturn(mockApiService);
      
      when(mockAuthService.isLoggedIn).thenReturn(false);
      when(mockAuthService.currentUser).thenReturn(null);
      when(mockAuthService.currentToken).thenReturn(null);
      
      authProvider = AuthProvider();
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    test('should initialize with correct default values', () {
      expect(authProvider.isLoggedIn, isFalse);
      expect(authProvider.userId, isNull);
      expect(authProvider.username, isNull);
      expect(authProvider.hasValidToken, isFalse);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.token, isNull);
    });

    test('should return correct auth headers without token', () {
      final headers = authProvider.authHeaders;
      expect(headers['Content-Type'], 'application/json');
      expect(headers.containsKey('Authorization'), isFalse);
    });

    test('should return correct auth headers with token', () {
      const testToken = 'test_token_123';
      when(mockAuthService.currentToken).thenReturn(testToken);
      
      final headers = authProvider.authHeaders;
      expect(headers['Content-Type'], 'application/json');
      expect(headers['Authorization'], 'Token $testToken');
    });

    test('should handle user login successfully', () async {
      final testUser = User(id: '1', username: 'testuser', email: 'test@test.com');
      final authResult = AuthResult(token: 'valid_token', user: testUser);
      when(mockAuthService.login(any, any)).thenAnswer((_) async => authResult);
      when(mockAuthService.currentToken).thenReturn('valid_token');
      when(mockAuthService.currentUser).thenReturn(testUser);
      
      final result = await authProvider.login('testuser', 'password');
      
      expect(result, isTrue);
      verify(mockAuthService.login('testuser', 'password')).called(1);
      verify(mockLoggingService.updateUserId(any)).called(1);
    });

    test('should handle user login failure', () async {
      when(mockAuthService.login(any, any)).thenThrow(Exception('Login failed'));
      
      final result = await authProvider.login('testuser', 'wrongpassword');
      
      expect(result, isFalse);
      verify(mockAuthService.login('testuser', 'wrongpassword')).called(1);
    });

    test('should handle logout successfully', () async {
      when(mockPlayerService.stop()).thenAnswer((_) async {});
      when(mockWebSocketService.disconnect()).thenAnswer((_) async {});
      when(mockAuthService.logout()).thenAnswer((_) async {});
      
      final result = await authProvider.logout();
      
      expect(result, isTrue);
      verify(mockPlayerService.stop()).called(1);
      verify(mockWebSocketService.disconnect()).called(1);
      verify(mockAuthService.logout()).called(1);
      verify(mockLoggingService.updateUserId(null)).called(1);
    });

    test('should handle logout failure gracefully', () async {
      when(mockPlayerService.stop()).thenAnswer((_) async {});
      when(mockWebSocketService.disconnect()).thenAnswer((_) async {});
      when(mockAuthService.logout()).thenThrow(Exception('Logout failed'));
      
      final result = await authProvider.logout();
      
      expect(result, isFalse);
      verify(mockPlayerService.stop()).called(1);
      verify(mockWebSocketService.disconnect()).called(1);
      verify(mockAuthService.logout()).called(1);
    });

    test('should handle player service error during logout', () async {
      when(mockPlayerService.stop()).thenThrow(Exception('Player error'));
      when(mockWebSocketService.disconnect()).thenAnswer((_) async {});
      when(mockAuthService.logout()).thenAnswer((_) async {});
      
      final result = await authProvider.logout();
      
      expect(result, isTrue);
      verify(mockPlayerService.stop()).called(1);
      verify(mockWebSocketService.disconnect()).called(1);
      verify(mockAuthService.logout()).called(1);
    });

    test('should handle websocket error during logout', () async {
      when(mockPlayerService.stop()).thenAnswer((_) async {});
      when(mockWebSocketService.disconnect()).thenThrow(Exception('WebSocket error'));
      when(mockAuthService.logout()).thenAnswer((_) async {});
      
      final result = await authProvider.logout();
      
      expect(result, isTrue);
      verify(mockPlayerService.stop()).called(1);
      verify(mockWebSocketService.disconnect()).called(1);
      verify(mockAuthService.logout()).called(1);
    });

    test('should send password reset email successfully', () async {
      when(mockApiService.forgotPassword(any)).thenAnswer((_) async {});
      
      final result = await authProvider.sendPasswordResetEmail('test@example.com');
      
      expect(result, isTrue);
      verify(mockApiService.forgotPassword(any)).called(1);
    });

    test('should send signup email OTP successfully', () async {
      when(mockAuthService.sendSignupEmailOtp(any)).thenAnswer((_) async {});
      
      final result = await authProvider.sendSignupEmailOtp('test@example.com');
      
      expect(result, isTrue);
      verify(mockAuthService.sendSignupEmailOtp('test@example.com')).called(1);
    });

    test('should handle signup with OTP successfully', () async {
      final testUser = User(id: '1', username: 'username', email: 'email@test.com');
      final authResult = AuthResult(token: 'valid_token', user: testUser);
      when(mockAuthService.signupWithOtp(any, any, any, any)).thenAnswer((_) async => authResult);
      
      final result = await authProvider.signupWithOtp('username', 'email@test.com', 'password', '123456');
      
      expect(result, isTrue);
      verify(mockAuthService.signupWithOtp('username', 'email@test.com', 'password', '123456')).called(1);
    });

    test('should handle signup with OTP failure', () async {
      when(mockAuthService.signupWithOtp(any, any, any, any)).thenThrow(Exception('Signup failed'));
      
      final result = await authProvider.signupWithOtp('username', 'email@test.com', 'password', '123456');
      
      expect(result, isFalse);
      verify(mockAuthService.signupWithOtp('username', 'email@test.com', 'password', '123456')).called(1);
    });

    test('should check email availability successfully', () async {
      when(mockApiService.checkEmail(any)).thenAnswer((_) async => {'exists': false});
      
      final result = await authProvider.checkEmailAvailability('test@example.com');
      
      expect(result, isTrue);
      verify(mockApiService.checkEmail('test@example.com')).called(1);
    });

    test('should handle check email availability error', () async {
      when(mockApiService.checkEmail(any)).thenThrow(Exception('API error'));
      
      final result = await authProvider.checkEmailAvailability('test@example.com');
      
      expect(result, isFalse);
      verify(mockApiService.checkEmail('test@example.com')).called(1);
    });

    test('should handle Google login successfully', () async {
      final mockGoogleSignInAccount = MockGoogleSignInAccount();
      when(mockGoogleSignInAccount.id).thenReturn('google_id');
      when(mockGoogleSignInAccount.email).thenReturn('test@gmail.com');
      when(mockGoogleSignInAccount.displayName).thenReturn('Test User');
      when(mockGoogleSignInAccount.authentication).thenAnswer((_) async => MockGoogleSignInAuthentication());
      
      when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleSignInAccount);
      final testUser = User(id: 'google_id', username: 'Test User', email: 'test@gmail.com');
      final authResult = AuthResult(token: 'valid_token', user: testUser);
      when(mockAuthService.googleLogin(socialId: anyNamed('socialId'), socialEmail: anyNamed('socialEmail'), socialName: anyNamed('socialName'))).thenAnswer((_) async => authResult);
      
      final result = await authProvider.googleLogin();
      
      expect(result, isTrue);
    });

    test('should handle Google login cancellation', () async {
      when(mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
      when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);
      
      final result = await authProvider.googleLogin();
      
      expect(result, isFalse);
    });

    test('should handle Facebook login successfully', () async {
      final result = await authProvider.facebookLogin();
      
      expect(result, isA<bool>());
    });

    test('should return correct hasValidToken value', () {
      when(mockAuthService.currentToken).thenReturn('valid_token');
      expect(authProvider.hasValidToken, isTrue);
      
      when(mockAuthService.currentToken).thenReturn('');
      expect(authProvider.hasValidToken, isFalse);
      
      when(mockAuthService.currentToken).thenReturn(null);
      expect(authProvider.hasValidToken, isFalse);
    });

    test('should return correct user properties', () {
      final testUser = User(id: '123', username: 'testuser', email: 'test@example.com');
      when(mockAuthService.currentUser).thenReturn(testUser);
      when(mockAuthService.isLoggedIn).thenReturn(true);
      
      expect(authProvider.currentUser, equals(testUser));
      expect(authProvider.userId, equals('123'));
      expect(authProvider.username, equals('testuser'));
      expect(authProvider.isLoggedIn, isTrue);
    });

    test('should handle reset password with OTP successfully', () async {
      when(mockApiService.forgotChangePassword(any)).thenAnswer((_) async {});
      
      final result = await authProvider.resetPasswordWithOtp('test@example.com', '123456', 'newpassword');
      
      expect(result, isTrue);
      verify(mockApiService.forgotChangePassword(any)).called(1);
    });

    test('should handle reset password with OTP failure', () async {
      when(mockApiService.forgotChangePassword(any)).thenThrow(Exception('Reset failed'));
      
      final result = await authProvider.resetPasswordWithOtp('test@example.com', '123456', 'newpassword');
      
      expect(result, isFalse);
      verify(mockApiService.forgotChangePassword(any)).called(1);
    });
  });
}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}
