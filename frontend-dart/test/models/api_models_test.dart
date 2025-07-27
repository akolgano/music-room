import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/models/api_models.dart';
void main() {
  group('API Models Tests', () {
    group('LoginRequest', () {
      test('should serialize to JSON correctly', () {
        const request = LoginRequest(username: 'testuser', password: 'testpass');
        final json = request.toJson();
        
        expect(json['username'], 'testuser');
        expect(json['password'], 'testpass');
      });
    });
    group('SocialLoginRequest', () {
      test('should serialize Facebook login correctly', () {
        const request = SocialLoginRequest(fbAccessToken: 'fb_token');
        final json = request.toJson();
        
        expect(json['fbAccessToken'], 'fb_token');
        expect(json.containsKey('idToken'), false);
      });
      test('should serialize Google login correctly', () {
        const request = SocialLoginRequest(
          idToken: 'google_token',
          socialId: 'google_id',
          socialEmail: 'test@example.com'
        );
        final json = request.toJson();
        
        expect(json['idToken'], 'google_token');
        expect(json['socialId'], 'google_id');
        expect(json['socialEmail'], 'test@example.com');
      });
      test('should handle null values correctly', () {
        const request = SocialLoginRequest();
        final json = request.toJson();
        
        expect(json.isEmpty, true);
      });
    });
    group('ProfileResponse', () {
      test('should deserialize from JSON correctly', () {
        final json = {
          'avatar': 'avatar_url',
          'name': 'John Doe',
          'location': 'New York',
          'bio': 'Music lover',
          'music_preferences': ['Rock', 'Jazz'],
          'music_preferences_ids': [1, 2],
          'avatar_visibility': 'public'
        };
        
        final profile = ProfileResponse.fromJson(json);
        
        expect(profile.avatar, 'avatar_url');
        expect(profile.name, 'John Doe');
        expect(profile.location, 'New York');
        expect(profile.bio, 'Music lover');
        expect(profile.musicPreferences, ['Rock', 'Jazz']);
        expect(profile.musicPreferencesIds, [1, 2]);
        expect(profile.avatarVisibility, 'public');
      });
      test('should handle null values gracefully', () {
        final json = <String, dynamic>{};
        final profile = ProfileResponse.fromJson(json);
        
        expect(profile.avatar, null);
        expect(profile.name, null);
        expect(profile.musicPreferences, null);
      });
      test('should serialize to JSON correctly', () {
        const profile = ProfileResponse(
          avatar: 'avatar_url',
          name: 'John Doe',
          musicPreferences: ['Rock', 'Jazz']
        );
        final json = profile.toJson();
        
        expect(json['avatar'], 'avatar_url');
        expect(json['name'], 'John Doe');
        expect(json['music_preferences'], ['Rock', 'Jazz']);
        expect(json.containsKey('location'), false);
      });
    });
    group('CreatePlaylistRequest', () {
      test('should serialize correctly with device UUID', () {
        const request = CreatePlaylistRequest(
          name: 'My Playlist',
          description: 'Test playlist',
          public: true,
          deviceUuid: 'device-123'
        );
        final json = request.toJson();
        
        expect(json['name'], 'My Playlist');
        expect(json['description'], 'Test playlist');
        expect(json['public'], true);
        expect(json['device_uuid'], 'device-123');
      });
      test('should serialize correctly without device UUID', () {
        const request = CreatePlaylistRequest(
          name: 'My Playlist',
          description: 'Test playlist',
          public: false
        );
        final json = request.toJson();
        
        expect(json['name'], 'My Playlist');
        expect(json['description'], 'Test playlist');
        expect(json['public'], false);
        expect(json.containsKey('device_uuid'), false);
      });
    });
    group('AuthResult', () {
      test('should deserialize from JSON correctly', () {
        final json = {
          'token': 'auth_token_123',
          'user': {
            'id': 1,
            'username': 'testuser',
            'email': 'test@example.com'
          }
        };
        
        final authResult = AuthResult.fromJson(json);
        
        expect(authResult.token, 'auth_token_123');
        expect(authResult.user.username, 'testuser');
      });
    });
    group('VoteResponse', () {
      test('should deserialize from JSON correctly', () {
        final json = {
          'message': 'Vote recorded successfully',
          'playlist': []
        };
        
        final voteResponse = VoteResponse.fromJson(json);
        
        expect(voteResponse.message, 'Vote recorded successfully');
        expect(voteResponse.playlist, isEmpty);
      });
      test('should handle missing message field', () {
        final json = {
          'playlist': []
        };
        
        final voteResponse = VoteResponse.fromJson(json);
        
        expect(voteResponse.message, 'Vote recorded');
        expect(voteResponse.playlist, isEmpty);
      });
    });
    group('PlaylistLicenseRequest', () {
      test('should serialize correctly with all fields', () {
        const request = PlaylistLicenseRequest(
          licenseType: 'premium',
          invitedUsers: [1, 2, 3],
          voteStartTime: '2023-01-01T00:00:00Z',
          voteEndTime: '2023-01-02T00:00:00Z',
          latitude: 40.7128,
          longitude: -74.0060,
          allowedRadiusMeters: 1000
        );
        final json = request.toJson();
        
        expect(json['license_type'], 'premium');
        expect(json['invited_users'], [1, 2, 3]);
        expect(json['vote_start_time'], '2023-01-01T00:00:00Z');
        expect(json['vote_end_time'], '2023-01-02T00:00:00Z');
        expect(json['latitude'], 40.7128);
        expect(json['longitude'], -74.0060);
        expect(json['allowed_radius_meters'], 1000);
      });
      test('should serialize correctly with minimal fields', () {
        const request = PlaylistLicenseRequest(licenseType: 'free');
        final json = request.toJson();
        
        expect(json['license_type'], 'free');
        expect(json.containsKey('invited_users'), false);
        expect(json.containsKey('latitude'), false);
      });
    });
    group('MusicPreference', () {
      test('should serialize and deserialize correctly', () {
        const preference = MusicPreference(id: 1, name: 'Rock');
        final json = preference.toJson();
        final deserialized = MusicPreference.fromJson(json);
        
        expect(deserialized.id, 1);
        expect(deserialized.name, 'Rock');
      });
    });
  });
}
