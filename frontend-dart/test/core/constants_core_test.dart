import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/core/provider_core.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AppConstants Tests', () {
    test('AppConstants should have correct values', () {
      expect(AppConstants.appName, 'Music Room');
      expect(AppConstants.version, '1.0.0');
      expect(AppConstants.defaultApiBaseUrl, 'http://localhost:8000');
      expect(AppConstants.contentTypeJson, 'application/json');
      expect(AppConstants.authorizationPrefix, 'Token');
      expect(AppConstants.minPasswordLength, 4);
    });
  });
  group('AppStrings Tests', () {
    test('AppStrings should have correct values', () {
      expect(AppStrings.confirmLogout, 'Are you sure you want to sign out?');
      expect(AppStrings.networkError, 'Network error. Please check your connection.');
    });
  });
  group('AppRoutes Tests', () {
    test('AppRoutes should have correct values', () {
      expect(AppRoutes.auth, '/auth');
      expect(AppRoutes.profile, '/profile');
      expect(AppRoutes.playlistEditor, '/playlist_editor');
      expect(AppRoutes.playlistDetail, '/playlist_detail');
      expect(AppRoutes.trackDetail, '/track_detail');
      expect(AppRoutes.trackSearch, '/track_search');
      expect(AppRoutes.publicPlaylists, '/public_playlists');
      expect(AppRoutes.friends, '/friends');
      expect(AppRoutes.addFriend, '/add_friend');
      expect(AppRoutes.friendRequests, '/friend_requests');
      expect(AppRoutes.playlistSharing, '/playlist_sharing');
      expect(AppRoutes.player, '/player');
      expect(AppRoutes.userPasswordChange, '/user_password_change');
      expect(AppRoutes.socialNetworkLink, '/social_network_link');
      expect(AppRoutes.signupOtp, '/signup_otp');
    });
  });
  
  group('AppValidators Tests', () {
    test('AppValidators should have required validator', () {
      expect(AppValidators.required('test'), null);
      expect(AppValidators.required(''), isA<String>());
    });
    
    group('Email validator', () {
      test('should accept valid emails', () {
        expect(AppValidators.email('test@example.com'), null);
        expect(AppValidators.email('user.name+tag@example-domain.com'), null);
        expect(AppValidators.email('user123@test.co'), null);
      });
      
      test('should reject invalid emails', () {
        expect(AppValidators.email('invalid'), isA<String>());
        expect(AppValidators.email('test@'), isA<String>());
        expect(AppValidators.email('@example.com'), isA<String>());
        expect(AppValidators.email('test@.com'), isA<String>());
      });
      
      test('should reject emails with leading/trailing spaces', () {
        expect(AppValidators.email(' test@example.com'), isA<String>());
        expect(AppValidators.email('test@example.com '), isA<String>());
        expect(AppValidators.email(' test@example.com '), isA<String>());
      });
    });
    
    group('Password validator', () {
      const validTestPassword1 = 'ValidPass123';
      const validTestPassword2 = 'TestPass456';
      const validTestPassword3 = 'SamplePwd789';
      const shortPassword1 = 'abc';
      const shortPassword2 = 'Short12';
      
      test('should accept valid passwords', () {
        expect(AppValidators.password(validTestPassword1), null);
        expect(AppValidators.password(validTestPassword2), null);
        expect(AppValidators.password(validTestPassword3), null);
      });
      
      test('should reject short passwords', () {
        expect(AppValidators.password(shortPassword1), isA<String>());
        expect(AppValidators.password(shortPassword2), isA<String>());
      });
      
      test('should reject passwords with spaces', () {
        expect(AppValidators.password('test with space'), isA<String>());
        expect(AppValidators.password(' testword'), isA<String>());
        expect(AppValidators.password('testword '), isA<String>());
      });
    });
    
    group('Username validator', () {
      test('should accept valid usernames', () {
        expect(AppValidators.username('user'), null);
        expect(AppValidators.username('user123'), null);
        expect(AppValidators.username('user_name'), null);
        expect(AppValidators.username('Username123_'), null);
      });
      
      test('should reject short usernames', () {
        expect(AppValidators.username(''), isA<String>());
      });
      
      test('should reject long usernames', () {
        expect(AppValidators.username('a' * 21), isA<String>());
      });
      
      test('should reject usernames with leading/trailing spaces', () {
        expect(AppValidators.username(' username'), isA<String>());
        expect(AppValidators.username('username '), isA<String>());
        expect(AppValidators.username(' username '), isA<String>());
      });
      
      test('should reject usernames with invalid characters', () {
        expect(AppValidators.username('user-name'), isA<String>());
        expect(AppValidators.username('user.name'), isA<String>());
        expect(AppValidators.username('user@name'), isA<String>());
        expect(AppValidators.username('user name'), isA<String>());
      });
    });
    
    test('AppValidators should have phoneNumber validator', () {
      expect(AppValidators.phoneNumber(''), null);
      expect(AppValidators.phoneNumber('', true), isA<String>());
    });
    
    group('Required field validator for playlist names', () {
      test('should accept valid playlist names', () {
        expect(AppValidators.required('My Playlist'), null);
        expect(AppValidators.required('Rock Songs'), null);
        expect(AppValidators.required('  Playlist with spaces  '), null);
      });
      
      test('should reject empty playlist names', () {
        expect(AppValidators.required(''), isA<String>());
        expect(AppValidators.required(null), isA<String>());
        expect(AppValidators.required('   '), isA<String>());
      });
    });
  });
}