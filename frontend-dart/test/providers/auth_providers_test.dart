import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

class TestAuthService implements AuthService {
  @override
  Future<void> refreshCurrentUser() async {}
  late ApiService _api;
  
  @override
  ApiService get api => _api;
  
  set api(ApiService service) => _api = service;
  
  User? _currentUser;
  String? _currentToken;
  bool _isLoggedIn = false;
  
  @override
  User? get currentUser => _currentUser;
  
  @override
  String? get currentToken => _currentToken;
  
  @override
  bool get isLoggedIn => _isLoggedIn;
  
  @override
  Future<AuthResult> login(String username, String password) async {
    if (username == 'testuser' && password == 'password') {
      final user = User(id: '1', username: 'testuser', email: 'test@test.com');
      _currentUser = user;
      _currentToken = 'valid_token';
      _isLoggedIn = true;
      return AuthResult(token: 'valid_token', user: user);
    }
    throw Exception('Login failed');
  }
  
  @override
  Future<void> logout() async {
    _currentUser = null;
    _currentToken = null;
    _isLoggedIn = false;
  }
  
  @override
  Future<void> sendSignupEmailOtp(String email) async {}
  
  @override
  Future<AuthResult> signupWithOtp(String username, String email, String password, String otp) async {
    final user = User(id: '1', username: username, email: email);
    return AuthResult(token: 'valid_token', user: user);
  }
  
  @override
  Future<AuthResult> googleLogin({String? idToken, String? socialId, String? socialEmail, String? socialName}) async {
    final user = User(id: socialId ?? 'google_id', username: socialName ?? 'Test User', email: socialEmail ?? 'test@gmail.com');
    return AuthResult(token: 'valid_token', user: user);
  }
  
  @override
  Future<AuthResult> facebookLogin(String accessToken) async {
    throw UnimplementedError();
  }
  
  Future<AuthResult> appleLogin({String? socialId, String? socialEmail, String? socialName}) async {
    throw UnimplementedError();
  }
  
  Future<void> refreshToken() async {}
  
  Future<void> checkAuthStatus() async {}
  
  Future<AuthResult> signup(String username, String email, String password) async {
    throw UnimplementedError();
  }
}

class TestApiService implements ApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) {
      return Future.value();
    }
    if (invocation.isGetter) {
      return null;
    }
    return super.noSuchMethod(invocation);
  }
  
  @override
  String get baseUrl => 'http://test.com';
  
  String? authToken;
  
  @override
  Future<void> forgotPassword(ForgotPasswordRequest data) async {}
  
  @override
  Future<Map<String, dynamic>> checkEmail(String email) async {
    return {'exists': false};
  }
  
  @override
  Future<void> forgotChangePassword(ChangePasswordRequest data) async {}
  
  Future<Map<String, dynamic>> request(String endpoint, {String method = 'GET', Map<String, dynamic>? body, Map<String, String>? headers, bool skipAuth = false}) async {
    throw UnimplementedError();
  }
  
  Future<List<Playlist>> getPlaylists() async => [];
  
  @override
  Future<PlaylistDetailResponse> getPlaylist(String playlistId, String token) async {
    throw UnimplementedError();
  }
  
  @override
  Future<CreatePlaylistResponse> createPlaylist(String token, CreatePlaylistRequest request) async {
    throw UnimplementedError();
  }
  
  @override
  Future<void> updatePlaylist(String playlistId, String token, UpdatePlaylistRequest request) async {}
  
  @override
  Future<void> deletePlaylist(String playlistId, String token) async {}
  
  @override
  Future<DeezerSearchResponse> searchTracks(String query, String token) => 
    Future.value(DeezerSearchResponse(data: []));
  
  @override
  Future<void> addTrackToPlaylist(String playlistId, String token, AddTrackRequest request) async {}
  
  @override
  Future<void> removeTrackFromPlaylist(String playlistId, String trackId, String token) async {}
  
  Future<List<User>> getUsers() async => [];
  
  @override
  Future<UserResponse> getUser(String token) async {
    throw UnimplementedError();
  }
  
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {}
  
  @override
  Future<FriendsResponse> getFriends(String token) async => 
    Future.value(FriendsResponse(friends: []));
  
  @override
  Future<MessageResponse> sendFriendRequest(String userId, String token) async {
    return MessageResponse(message: 'Friend request sent');
  }
  
  @override
  Future<MessageResponse> acceptFriendRequest(String friendshipId, String token) async {
    return MessageResponse(message: 'Friend request accepted');
  }
  
  Future<void> declineFriendRequest(String requestId) async {}
  
  @override
  Future<MessageResponse> rejectFriendRequest(String friendshipId, String token) async {
    return MessageResponse(message: 'Rejected');
  }
  
  @override
  Future<void> removeFriend(String userId, String token) async {}
  
  Future<List<Map<String, dynamic>>> getActivities() async => [];
  
  Future<void> createActivity(Map<String, dynamic> data) async {}
  
  Future<Map<String, dynamic>> getStatistics() async => {};
  
  Future<void> updateSettings(Map<String, dynamic> settings) async {}
  
  Future<Map<String, dynamic>> getSettings() async => {};
  
  Future<void> reportIssue(String description, {String? category}) async {}
  
  Future<List<Map<String, dynamic>>> getNotifications() async => [];
  
  Future<void> markNotificationAsRead(String notificationId) async {}
  
  Future<void> deleteNotification(String notificationId) async {}
  
  @override
  Future<VoteResponse> voteForTrack(String playlistId, String token, VoteRequest request) async {
    return VoteResponse(
      message: 'Vote recorded', 
      playlist: [PlaylistInfoWithVotes(
        id: 1,
        playlistName: 'Test Playlist',
        description: 'Test',
        public: true,
        creator: 'test',
        tracks: []
      )]
    );
  }
  
  Future<Map<String, int>> getVotes(String playlistId) async => {};
  
  Future<void> sharePlaylist(String playlistId, String userId) async {}
  
  Future<void> unsharePlaylist(String playlistId, String userId) async {}
  
  Future<List<Map<String, dynamic>>> getSharedPlaylists() async => [];
  
  Future<void> acceptSharedPlaylist(String shareId) async {}
  
  Future<void> declineSharedPlaylist(String shareId) async {}
  
  Future<void> updatePassword(String oldPassword, String newPassword) async {}
  
  Future<void> deleteAccount(String password) async {}
  
  Future<void> exportData(String format) async {}
  
  Future<Map<String, dynamic>> getApiHealth() async => {};
  
  Future<Map<String, dynamic>> getApiMetrics() async => {};
  
  Future<List<Map<String, dynamic>>> getApiLogs({DateTime? startDate, DateTime? endDate}) async => [];
  
  Future<Map<String, dynamic>> getServerConfig() async => {};
  
  Future<void> updateServerConfig(Map<String, dynamic> config) async {}
  
  
  Future<Map<String, dynamic>> getLocation() async => {};
  
  Future<void> updateLocation(double latitude, double longitude) async {}
  
  Future<List<Map<String, dynamic>>> getNearbyUsers({double? radius}) async => [];
  
  Future<void> enableLocationSharing(bool enable) async {}
  
  Future<Map<String, dynamic>> getLocationSettings() async => {};
  
  Future<void> updateLocationSettings(Map<String, dynamic> settings) async {}
  
  Future<List<Map<String, dynamic>>> getLocationHistory() async => [];
  
  Future<void> clearLocationHistory() async {}
  
  Future<Map<String, dynamic>> getDistanceToUser(String userId) async => {};
  
  Future<void> createGeofence(Map<String, dynamic> data) async {}
  
  Future<List<Map<String, dynamic>>> getGeofences() async => [];
  
  Future<void> updateGeofence(String geofenceId, Map<String, dynamic> data) async {}
  
  Future<void> deleteGeofence(String geofenceId) async {}
  
  Future<void> enterGeofence(String geofenceId) async {}
  
  Future<void> exitGeofence(String geofenceId) async {}
  
  Future<Map<String, dynamic>> getGeofenceStatus(String geofenceId) async => {};
  
  Future<List<Map<String, dynamic>>> getGeofenceHistory(String geofenceId) async => [];
  
  Future<void> shareLocation(String userId, {Duration? duration}) async {}
  
  Future<void> stopSharingLocation(String userId) async {}
  
  Future<List<Map<String, dynamic>>> getSharedLocations() async => [];
  
  Future<Map<String, dynamic>> getSharedLocationStatus(String shareId) async => {};
}

class TestWebSocketService implements WebSocketService {
  Future<void> connect(String url, String token) async {}
  
  @override
  Future<void> disconnect() async {}
  
  void send(String event, dynamic data) {}
  
  void on(String event, Function(dynamic) handler) {}
  
  void off(String event) {}
  
  @override
  bool get isConnected => false;
  
  Stream<dynamic> get messages => Stream.empty();
  
  @override
  void dispose() {}
  
  @override
  Future<void> connectToPlaylist(String playlistId, String token) async {}
  
  @override
  Future<void> forceReconnect() async {}
  
  @override
  Stream<PlaylistUpdateMessage> get playlistUpdateStream => Stream.empty();
  
  @override
  Stream<Map<String, dynamic>> get rawMessageStream => Stream.empty();
  
  @override
  void sendMessage(Map<String, dynamic> message) {}
}

class TestFrontendLoggingService implements FrontendLoggingService {
  @override
  void updateUserId(String? userId) {}
  
  void log(String message, {LogLevel? level, Map<String, dynamic>? extra}) {}
  
  void debug(String message, {Map<String, dynamic>? extra}) {}
  
  void info(String message, {Map<String, dynamic>? extra}) {}
  
  void warning(String message, {Map<String, dynamic>? extra}) {}
  
  void error(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? extra}) {}
  
  void critical(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? extra}) {}
  
  @override
  Future<void> flush() async {}
  
  @override
  void dispose() {}
  
  @override
  Future<void> initialize() async {}
  
  @override
  void logButtonClick(String buttonName, String screenName, {Map<String, dynamic>? metadata}) {}
  
  @override
  void logFormSubmit(String formName, String screenName, {bool success = true, Map<String, dynamic>? metadata}) {}
  
  @override
  void logNavigation(String from, String to, {Map<String, dynamic>? metadata}) {}
  
  @override
  void logSearch(String query, String screenName, {int? resultCount, Map<String, dynamic>? metadata}) {}
  
  @override
  void logUserAction({
    required UserActionType actionType,
    required String description,
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? metadata,
    String? screenName,
    String? customRoute,
  }) {}
  
  @override
  Map<String, dynamic> sanitizeMetadata(Map<String, dynamic>? metadata) {
    return metadata ?? {};
  }
  
  @override
  void updateCurrentRoute(String? route) {}
}

class TestMusicPlayerService with ChangeNotifier implements MusicPlayerService {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      return null;
    }
    if (invocation.isMethod) {
      return Future.value();
    }
    return super.noSuchMethod(invocation);
  }
  
  @override
  Future<void> stop() async {}
  
  @override
  Future<void> play() async {}
  
  @override
  Future<void> pause() async {}
  
  Future<void> resume() async {}
  
  @override
  Future<void> seek(Duration position) async {}
  
  Future<void> setVolume(double volume) async {}
  
  
  @override
  Track? get currentTrack => null;
  
  @override
  bool get isPlaying => false;
  
  double get volume => 1.0;
  
  @override
  Duration get position => Duration.zero;
  
  @override
  Duration get duration => Duration.zero;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AuthProvider Tests', () {
    late AuthProvider authProvider;
    late TestAuthService testAuthService;
    late TestApiService testApiService;
    late TestWebSocketService testWebSocketService;
    late TestFrontendLoggingService testLoggingService;
    late TestMusicPlayerService testPlayerService;

    setUp(() {
      GetIt.instance.reset();
      testAuthService = TestAuthService();
      testApiService = TestApiService();
      testWebSocketService = TestWebSocketService();
      testLoggingService = TestFrontendLoggingService();
      testPlayerService = TestMusicPlayerService();
      
      testAuthService.api = testApiService;
      
      getIt.registerSingleton<AuthService>(testAuthService);
      getIt.registerSingleton<ApiService>(testApiService);
      getIt.registerSingleton<WebSocketService>(testWebSocketService);
      getIt.registerSingleton<FrontendLoggingService>(testLoggingService);
      getIt.registerSingleton<MusicPlayerService>(testPlayerService);
      
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

    test('should handle user login successfully', () async {
      final result = await authProvider.login('testuser', 'password');
      
      expect(result, isTrue);
      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.username, 'testuser');
    });

    test('should handle user login failure', () async {
      final result = await authProvider.login('testuser', 'wrongpassword');
      
      expect(result, isFalse);
      expect(authProvider.isLoggedIn, isFalse);
    });

    test('should handle logout successfully', () async {
      await authProvider.login('testuser', 'password');
      final result = await authProvider.logout();
      
      expect(result, isTrue);
      expect(authProvider.isLoggedIn, isFalse);
    });

    test('should send password reset email successfully', () async {
      final result = await authProvider.sendPasswordResetEmail('test@example.com');
      
      expect(result, isTrue);
    });

    test('should send signup email OTP successfully', () async {
      final result = await authProvider.sendSignupEmailOtp('test@example.com');
      
      expect(result, isTrue);
    });

    test('should handle signup with OTP successfully', () async {
      final result = await authProvider.signupWithOtp('username', 'email@test.com', 'password', '123456');
      
      expect(result, isTrue);
    });

    test('should check email availability successfully', () async {
      final result = await authProvider.checkEmailAvailability('test@example.com');
      
      expect(result, isTrue);
    });

    test('should handle Facebook login', () async {
      final result = await authProvider.facebookLogin();
      
      expect(result, isA<bool>());
    });

    test('should reset password with OTP successfully', () async {
      final result = await authProvider.resetPasswordWithOtp('test@example.com', '123456', 'newpassword');
      
      expect(result, isTrue);
    });
  });
}