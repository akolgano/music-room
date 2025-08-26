import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/models/api_models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


void main() {
  group('ApiService Tests', () {
    late ApiService apiService;
    late MockClient mockClient;
    
    setUp(() {
      mockClient = MockClient();
      apiService = ApiService(client: mockClient);
    });

    group('Authentication Endpoints', () {
      test('should login successfully', () async {
        final mockResponse = http.Response(
          json.encode({
            'token': 'test_token_123',
            'user': {
              'id': '1',
              'username': 'testuser',
              'email': 'test@example.com'
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);
        
        final result = await apiService.login('testuser', 'password123');
        
        expect(result.token, 'test_token_123');
        expect(result.user.username, 'testuser');
        verify(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).called(1);
      });

      test('should handle login failure', () async {
        final mockResponse = http.Response(
          json.encode({'error': 'Invalid credentials'}),
          401,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);
        
        expect(
          () async => await apiService.login('testuser', 'wrongpassword'),
          throwsA(isA<ApiException>()),
        );
      });

      test('should register user successfully', () async {
        final mockResponse = http.Response(
          json.encode({
            'success': true,
            'message': 'User registered successfully',
            'user': {
              'id': '2',
              'username': 'newuser',
              'email': 'new@example.com'
            }
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);
        
        final result = await apiService.register(
          username: 'newuser',
          email: 'new@example.com',
          password: 'password123',
        );
        
        expect(result.success, isTrue);
        expect(result.user?.username, 'newuser');
        verify(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).called(1);
      });

      test('should handle registration failure', () async {
        final mockResponse = http.Response(
          json.encode({
            'error': 'Username already exists',
            'details': {'username': ['This username is already taken']}
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);
        
        expect(
          () async => await apiService.register(
            username: 'existinguser',
            email: 'test@example.com',
            password: 'password123',
          ),
          throwsA(isA<ApiException>()),
        );
      });

      test('should logout successfully', () async {
        final mockResponse = http.Response(
          json.encode({'message': 'Logged out successfully'}),
          200,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.post(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);
        
        await apiService.logout('test_token');
        
        verify(mockClient.post(any, headers: anyNamed('headers'))).called(1);
      });
    });

    group('User Management', () {
      test('should get current user successfully', () async {
        final mockResponse = http.Response(
          json.encode({
            'id': '1',
            'username': 'currentuser',
            'email': 'current@example.com',
            'profile_picture': 'https://example.com/avatar.jpg'
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);
        
        final result = await apiService.getCurrentUser('test_token');
        
        expect(result.username, 'currentuser');
        expect(result.email, 'current@example.com');
        verify(mockClient.get(any, headers: anyNamed('headers'))).called(1);
      });

      test('should update user profile successfully', () async {
        final mockResponse = http.Response(
          json.encode({
            'id': '1',
            'username': 'updateduser',
            'email': 'updated@example.com'
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.patch(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);
        
        final result = await apiService.updateProfile('test_token', {
          'username': 'updateduser',
          'email': 'updated@example.com'
        });
        
        expect(result.username, 'updateduser');
        verify(mockClient.patch(any, headers: anyNamed('headers'), body: anyNamed('body'))).called(1);
      });

      test('should change password successfully', () async {
        final mockResponse = http.Response(
          json.encode({'message': 'Password changed successfully'}),
          200,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);
        
        await apiService.changePassword('test_token', 'oldpass', 'newpass');
        
        verify(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).called(1);
      });
    });

    group('Music Operations', () {
      test('should search tracks successfully', () async {
        final mockResponse = http.Response(
          json.encode({
            'results': [
              {
                'id': '1',
                'title': 'Test Song 1',
                'artist': 'Test Artist 1',
                'duration': 180,
                'url': 'https://example.com/song1.mp3'
              },
              {
                'id': '2',
                'title': 'Test Song 2',
                'artist': 'Test Artist 2',
                'duration': 220,
                'url': 'https://example.com/song2.mp3'
              }
            ],
            'total': 2
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);
        
        final result = await apiService.searchTracks('test_token', 'test query');
        
        expect(result.results, hasLength(2));
        expect(result.results.first.title, 'Test Song 1');
        expect(result.total, 2);
        verify(mockClient.get(any, headers: anyNamed('headers'))).called(1);
      });

      test('should get track details successfully', () async {
        final mockResponse = http.Response(
          json.encode({
            'id': '1',
            'title': 'Detailed Song',
            'artist': 'Detailed Artist',
            'album': 'Test Album',
            'duration': 240,
            'url': 'https://example.com/detailed.mp3',
            'lyrics': 'Test lyrics here'
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);
        
        final result = await apiService.getTrackDetails('test_token', '1');
        
        expect(result.title, 'Detailed Song');
        expect(result.album, 'Test Album');
        expect(result.lyrics, 'Test lyrics here');
        verify(mockClient.get(any, headers: anyNamed('headers'))).called(1);
      });

      test('should add track to favorites successfully', () async {
        final mockResponse = http.Response(
          json.encode({'message': 'Track added to favorites'}),
          200,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);
        
        await apiService.addToFavorites('test_token', '1');
        
        verify(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).called(1);
      });

      test('should remove track from favorites successfully', () async {
        final mockResponse = http.Response(
          json.encode({'message': 'Track removed from favorites'}),
          200,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.delete(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);
        
        await apiService.removeFromFavorites('test_token', '1');
        
        verify(mockClient.delete(any, headers: anyNamed('headers'))).called(1);
      });
    });

    group('Playlist Operations', () {
      test('should get user playlists successfully', () async {
        final mockResponse = http.Response(
          json.encode({
            'playlists': [
              {
                'id': '1',
                'name': 'My Playlist 1',
                'description': 'Test playlist 1',
                'track_count': 10,
                'created_at': '2023-01-01T00:00:00Z'
              },
              {
                'id': '2',
                'name': 'My Playlist 2',
                'description': 'Test playlist 2',
                'track_count': 5,
                'created_at': '2023-01-02T00:00:00Z'
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);
        
        final result = await apiService.getUserPlaylists('test_token');
        
        expect(result.playlists, hasLength(2));
        expect(result.playlists.first.name, 'My Playlist 1');
        verify(mockClient.get(any, headers: anyNamed('headers'))).called(1);
      });

      test('should create playlist successfully', () async {
        final mockResponse = http.Response(
          json.encode({
            'id': '3',
            'name': 'New Playlist',
            'description': 'New test playlist',
            'track_count': 0,
            'created_at': '2023-01-03T00:00:00Z'
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);
        
        final result = await apiService.createPlaylist('test_token', {
          'name': 'New Playlist',
          'description': 'New test playlist'
        });
        
        expect(result.name, 'New Playlist');
        expect(result.id, '3');
        verify(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).called(1);
      });

      test('should delete playlist successfully', () async {
        final mockResponse = http.Response(
          json.encode({'message': 'Playlist deleted successfully'}),
          200,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.delete(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);
        
        await apiService.deletePlaylist('test_token', '1');
        
        verify(mockClient.delete(any, headers: anyNamed('headers'))).called(1);
      });

      test('should add track to playlist successfully', () async {
        final mockResponse = http.Response(
          json.encode({'message': 'Track added to playlist'}),
          200,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);
        
        await apiService.addTrackToPlaylist('test_token', '1', '101');
        
        verify(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).called(1);
      });

      test('should remove track from playlist successfully', () async {
        final mockResponse = http.Response(
          json.encode({'message': 'Track removed from playlist'}),
          200,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.delete(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);
        
        await apiService.removeTrackFromPlaylist('test_token', '1', '101');
        
        verify(mockClient.delete(any, headers: anyNamed('headers'))).called(1);
      });
    });

    group('Error Handling', () {
      test('should handle network errors', () async {
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenThrow(Exception('Network error'));
        
        expect(
          () async => await apiService.getCurrentUser('test_token'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle timeout errors', () async {
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async {
          await Future.delayed(Duration(seconds: 30));
          return http.Response('timeout', 408);
        });
        
        expect(
          () async => await apiService.login('testuser', 'password'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle server errors (500)', () async {
        final mockResponse = http.Response(
          json.encode({'error': 'Internal server error'}),
          500,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);
        
        expect(
          () async => await apiService.getCurrentUser('test_token'),
          throwsA(isA<ApiException>()),
        );
      });

      test('should handle invalid JSON responses', () async {
        final mockResponse = http.Response(
          'Invalid JSON response',
          200,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);
        
        expect(
          () async => await apiService.getCurrentUser('test_token'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle unauthorized errors (401)', () async {
        final mockResponse = http.Response(
          json.encode({'error': 'Unauthorized'}),
          401,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);
        
        expect(
          () async => await apiService.getCurrentUser('invalid_token'),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('Request Headers and Authentication', () {
      test('should include correct headers in authenticated requests', () async {
        final mockResponse = http.Response(
          json.encode({'id': '1', 'username': 'test'}),
          200,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);
        
        await apiService.getCurrentUser('test_token');
        
        final captured = verify(mockClient.get(any, headers: captureAnyNamed('headers'))).captured;
        final headers = captured.first as Map<String, String>;
        
        expect(headers['Content-Type'], 'application/json');
        expect(headers['Authorization'], 'Token test_token');
      });

      test('should handle requests without token', () async {
        final mockResponse = http.Response(
          json.encode([]),
          200,
          headers: {'content-type': 'application/json'},
        );
        
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);
        
        await apiService.getPublicPlaylists();
        
        final captured = verify(mockClient.get(any, headers: captureAnyNamed('headers'))).captured;
        final headers = captured.first as Map<String, String>;
        
        expect(headers['Content-Type'], 'application/json');
        expect(headers.containsKey('Authorization'), isFalse);
      });
    });
  });
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, [this.statusCode]);
  
  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class LoginResponse {
  final String token;
  final User user;
  
  LoginResponse({required this.token, required this.user});
}

class RegisterResponse {
  final bool success;
  final String? message;
  final User? user;
  
  RegisterResponse({required this.success, this.message, this.user});
}

class TrackSearchResponse {
  final List<Track> results;
  final int total;
  
  TrackSearchResponse({required this.results, required this.total});
}

class Track {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final int duration;
  final String? url;
  final String? lyrics;
  
  Track({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.duration,
    this.url,
    this.lyrics,
  });
}

class PlaylistsResponse {
  final List<Playlist> playlists;
  
  PlaylistsResponse({required this.playlists});
}

class Playlist {
  final String id;
  final String name;
  final String? description;
  final int trackCount;
  final String createdAt;
  
  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.trackCount,
    required this.createdAt,
  });
}
