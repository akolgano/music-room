import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:music_room/services/auth_services.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/models/api_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

@GenerateMocks([ApiService, SharedPreferences])
import 'auth_services_test.mocks.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;
    late MockApiService mockApiService;
    late MockSharedPreferences mockSharedPreferences;

    setUp(() {
      GetIt.instance.reset();
      mockApiService = MockApiService();
      mockSharedPreferences = MockSharedPreferences();
      
      getIt.registerSingleton<ApiService>(mockApiService);
      
      when(mockSharedPreferences.getString('auth_token')).thenReturn(null);
      when(mockSharedPreferences.getString('user_data')).thenReturn(null);
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
      when(mockSharedPreferences.remove(any)).thenAnswer((_) async => true);
      
      authService = AuthService(sharedPreferences: mockSharedPreferences);
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    test('should initialize with no current user', () {
      expect(authService.currentUser, isNull);
      expect(authService.currentToken, isNull);
      expect(authService.isLoggedIn, isFalse);
    });

    test('should login successfully and store credentials', () async {
      final mockUser = User(id: '1', username: 'testuser', email: 'test@example.com');
      final mockLoginResponse = LoginResponse(token: 'test_token', user: mockUser);
      
      when(mockApiService.login(any, any)).thenAnswer((_) async => mockLoginResponse);
      
      final result = await authService.login('testuser', 'password123');
      
      expect(result, isTrue);
      expect(authService.currentUser, isNotNull);
      expect(authService.currentUser?.username, 'testuser');
      expect(authService.currentToken, 'test_token');
      expect(authService.isLoggedIn, isTrue);
      
      verify(mockApiService.login('testuser', 'password123')).called(1);
      verify(mockSharedPreferences.setString('auth_token', 'test_token')).called(1);
      verify(mockSharedPreferences.setString('user_data', any)).called(1);
    });

    test('should handle login failure', () async {
      when(mockApiService.login(any, any)).thenThrow(Exception('Invalid credentials'));
      
      final result = await authService.login('testuser', 'wrongpassword');
      
      expect(result, isFalse);
      expect(authService.currentUser, isNull);
      expect(authService.currentToken, isNull);
      expect(authService.isLoggedIn, isFalse);
      
      verify(mockApiService.login('testuser', 'wrongpassword')).called(1);
      verifyNever(mockSharedPreferences.setString('auth_token', any));
    });

    test('should logout successfully and clear stored data', () async {
      authService.currentUser = User(id: '1', username: 'testuser', email: 'test@example.com');
      authService.currentToken = 'test_token';
      
      when(mockApiService.logout(any)).thenAnswer((_) async {});
      
      final result = await authService.logout();
      
      expect(result, isTrue);
      expect(authService.currentUser, isNull);
      expect(authService.currentToken, isNull);
      expect(authService.isLoggedIn, isFalse);
      
      verify(mockApiService.logout('test_token')).called(1);
      verify(mockSharedPreferences.remove('auth_token')).called(1);
      verify(mockSharedPreferences.remove('user_data')).called(1);
    });

    test('should handle logout when not logged in', () async {
      final result = await authService.logout();
      
      expect(result, isTrue);
      verifyNever(mockApiService.logout(any));
      verify(mockSharedPreferences.remove('auth_token')).called(1);
      verify(mockSharedPreferences.remove('user_data')).called(1);
    });

    test('should handle logout API failure gracefully', () async {
      authService.currentToken = 'test_token';
      
      when(mockApiService.logout(any)).thenThrow(Exception('Logout failed'));
      
      final result = await authService.logout();
      
      expect(result, isTrue);
      expect(authService.currentUser, isNull);
      expect(authService.currentToken, isNull);
      
      verify(mockApiService.logout('test_token')).called(1);
      verify(mockSharedPreferences.remove('auth_token')).called(1);
      verify(mockSharedPreferences.remove('user_data')).called(1);
    });

    test('should register user successfully', () async {
      final mockUser = User(id: '2', username: 'newuser', email: 'new@example.com');
      final mockRegisterResponse = RegisterResponse(success: true, user: mockUser);
      
      when(mockApiService.register(any, any, any)).thenAnswer((_) async => mockRegisterResponse);
      
      final result = await authService.register('newuser', 'new@example.com', 'password123');
      
      expect(result, isTrue);
      verify(mockApiService.register('newuser', 'new@example.com', 'password123')).called(1);
    });

    test('should handle registration failure', () async {
      when(mockApiService.register(any, any, any)).thenThrow(Exception('Registration failed'));
      
      final result = await authService.register('newuser', 'new@example.com', 'password123');
      
      expect(result, isFalse);
      verify(mockApiService.register('newuser', 'new@example.com', 'password123')).called(1);
    });

    test('should send signup email OTP successfully', () async {
      when(mockApiService.sendSignupEmailOtp(any)).thenAnswer((_) async {});
      
      await authService.sendSignupEmailOtp('test@example.com');
      
      verify(mockApiService.sendSignupEmailOtp('test@example.com')).called(1);
    });

    test('should handle send signup email OTP failure', () async {
      when(mockApiService.sendSignupEmailOtp(any)).thenThrow(Exception('OTP send failed'));
      
      expect(
        () async => await authService.sendSignupEmailOtp('test@example.com'),
        throwsA(isA<Exception>()),
      );
      
      verify(mockApiService.sendSignupEmailOtp('test@example.com')).called(1);
    });

    test('should signup with OTP successfully', () async {
      final mockUser = User(id: '3', username: 'otpuser', email: 'otp@example.com');
      final mockSignupResponse = SignupWithOtpResponse(success: true, user: mockUser);
      
      when(mockApiService.signupWithOtp(any, any, any, any)).thenAnswer((_) async => mockSignupResponse);
      
      final result = await authService.signupWithOtp('otpuser', 'otp@example.com', 'password123', '123456');
      
      expect(result, isTrue);
      verify(mockApiService.signupWithOtp('otpuser', 'otp@example.com', 'password123', '123456')).called(1);
    });

    test('should handle signup with OTP failure', () async {
      when(mockApiService.signupWithOtp(any, any, any, any)).thenThrow(Exception('OTP signup failed'));
      
      final result = await authService.signupWithOtp('otpuser', 'otp@example.com', 'password123', '123456');
      
      expect(result, isFalse);
      verify(mockApiService.signupWithOtp('otpuser', 'otp@example.com', 'password123', '123456')).called(1);
    });

    test('should perform Google login successfully', () async {
      final mockUser = User(id: '4', username: 'googleuser', email: 'google@example.com');
      final mockLoginResponse = LoginResponse(token: 'google_token', user: mockUser);
      
      when(mockApiService.googleLogin(any)).thenAnswer((_) async => mockLoginResponse);
      
      await authService.googleLogin(idToken: 'google_id_token');
      
      expect(authService.currentUser, isNotNull);
      expect(authService.currentUser?.email, 'google@example.com');
      expect(authService.currentToken, 'google_token');
      expect(authService.isLoggedIn, isTrue);
      
      verify(mockApiService.googleLogin(GoogleLoginRequest(idToken: 'google_id_token'))).called(1);
      verify(mockSharedPreferences.setString('auth_token', 'google_token')).called(1);
    });

    test('should perform Google login with social credentials', () async {
      final mockUser = User(id: '5', username: 'socialuser', email: 'social@example.com');
      final mockLoginResponse = LoginResponse(token: 'social_token', user: mockUser);
      
      when(mockApiService.googleLogin(any)).thenAnswer((_) async => mockLoginResponse);
      
      await authService.googleLogin(
        socialId: 'social_123',
        socialEmail: 'social@example.com',
        socialName: 'Social User',
      );
      
      expect(authService.currentUser, isNotNull);
      expect(authService.currentToken, 'social_token');
      expect(authService.isLoggedIn, isTrue);
      
      verify(mockApiService.googleLogin(any)).called(1);
    });

    test('should handle Google login failure', () async {
      when(mockApiService.googleLogin(any)).thenThrow(Exception('Google login failed'));
      
      expect(
        () async => await authService.googleLogin(idToken: 'invalid_token'),
        throwsA(isA<Exception>()),
      );
      
      verify(mockApiService.googleLogin(any)).called(1);
    });

    test('should perform Facebook login successfully', () async {
      final mockUser = User(id: '6', username: 'facebookuser', email: 'facebook@example.com');
      final mockLoginResponse = LoginResponse(token: 'facebook_token', user: mockUser);
      
      when(mockApiService.facebookLogin(any)).thenAnswer((_) async => mockLoginResponse);
      
      await authService.facebookLogin('fb_access_token');
      
      expect(authService.currentUser, isNotNull);
      expect(authService.currentUser?.email, 'facebook@example.com');
      expect(authService.currentToken, 'facebook_token');
      expect(authService.isLoggedIn, isTrue);
      
      verify(mockApiService.facebookLogin('fb_access_token')).called(1);
      verify(mockSharedPreferences.setString('auth_token', 'facebook_token')).called(1);
    });

    test('should handle Facebook login failure', () async {
      when(mockApiService.facebookLogin(any)).thenThrow(Exception('Facebook login failed'));
      
      expect(
        () async => await authService.facebookLogin('invalid_token'),
        throwsA(isA<Exception>()),
      );
      
      verify(mockApiService.facebookLogin('invalid_token')).called(1);
    });

    test('should refresh current user successfully', () async {
      authService.currentToken = 'test_token';
      final mockUser = User(id: '1', username: 'refresheduser', email: 'refreshed@example.com');
      
      when(mockApiService.getCurrentUser(any)).thenAnswer((_) async => mockUser);
      
      await authService.refreshCurrentUser();
      
      expect(authService.currentUser, isNotNull);
      expect(authService.currentUser?.username, 'refresheduser');
      
      verify(mockApiService.getCurrentUser('test_token')).called(1);
      verify(mockSharedPreferences.setString('user_data', any)).called(1);
    });

    test('should handle refresh current user when no token', () async {
      await authService.refreshCurrentUser();
      
      verifyNever(mockApiService.getCurrentUser(any));
    });

    test('should handle refresh current user failure', () async {
      authService.currentToken = 'test_token';
      
      when(mockApiService.getCurrentUser(any)).thenThrow(Exception('Refresh failed'));
      
      expect(
        () async => await authService.refreshCurrentUser(),
        throwsA(isA<Exception>()),
      );
      
      verify(mockApiService.getCurrentUser('test_token')).called(1);
    });

    test('should load stored authentication data on initialization', () {
      when(mockSharedPreferences.getString('auth_token')).thenReturn('stored_token');
      when(mockSharedPreferences.getString('user_data')).thenReturn(
        '{"id":"1","username":"storeduser","email":"stored@example.com"}',
      );
      
      final authServiceWithStoredData = AuthService(sharedPreferences: mockSharedPreferences);
      
      expect(authServiceWithStoredData.currentToken, 'stored_token');
      expect(authServiceWithStoredData.currentUser, isNotNull);
      expect(authServiceWithStoredData.currentUser?.username, 'storeduser');
      expect(authServiceWithStoredData.isLoggedIn, isTrue);
    });

    test('should handle corrupted stored user data gracefully', () {
      when(mockSharedPreferences.getString('auth_token')).thenReturn('stored_token');
      when(mockSharedPreferences.getString('user_data')).thenReturn('invalid_json');
      
      final authServiceWithCorruptedData = AuthService(sharedPreferences: mockSharedPreferences);
      
      expect(authServiceWithCorruptedData.currentToken, 'stored_token');
      expect(authServiceWithCorruptedData.currentUser, isNull);
      expect(authServiceWithCorruptedData.isLoggedIn, isFalse);
    });

    test('should validate token format', () {
      expect(authService.isValidTokenFormat('valid_token_123'), isTrue);
      expect(authService.isValidTokenFormat(''), isFalse);
      expect(authService.isValidTokenFormat(' '), isFalse);
      expect(authService.isValidTokenFormat('short'), isFalse);
    });

    test('should check if user is authenticated', () {
      expect(authService.isAuthenticated, isFalse);
      
      authService.currentToken = 'test_token';
      authService.currentUser = User(id: '1', username: 'test', email: 'test@example.com');
      
      expect(authService.isAuthenticated, isTrue);
    });

    test('should clear authentication data', () {
      authService.currentToken = 'test_token';
      authService.currentUser = User(id: '1', username: 'test', email: 'test@example.com');
      
      authService.clearAuthData();
      
      expect(authService.currentToken, isNull);
      expect(authService.currentUser, isNull);
      expect(authService.isLoggedIn, isFalse);
    });

    test('should get user ID when authenticated', () {
      expect(authService.userId, isNull);
      
      authService.currentUser = User(id: '123', username: 'test', email: 'test@example.com');
      
      expect(authService.userId, '123');
    });

    test('should get username when authenticated', () {
      expect(authService.username, isNull);
      
      authService.currentUser = User(id: '1', username: 'testuser', email: 'test@example.com');
      
      expect(authService.username, 'testuser');
    });

    test('should get user email when authenticated', () {
      expect(authService.userEmail, isNull);
      
      authService.currentUser = User(id: '1', username: 'test', email: 'test@example.com');
      
      expect(authService.userEmail, 'test@example.com');
    });
  });
}

class LoginResponse {
  final String token;
  final User user;
  
  LoginResponse({required this.token, required this.user});
}

class RegisterResponse {
  final bool success;
  final User? user;
  
  RegisterResponse({required this.success, this.user});
}

class SignupWithOtpResponse {
  final bool success;
  final User? user;
  
  SignupWithOtpResponse({required this.success, this.user});
}

class GoogleLoginRequest {
  final String? idToken;
  final String? socialId;
  final String? socialEmail;
  final String? socialName;
  
  GoogleLoginRequest({this.idToken, this.socialId, this.socialEmail, this.socialName});
}
