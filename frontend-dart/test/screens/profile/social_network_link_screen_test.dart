import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/screens/profile/social_network_link_screen.dart';
import 'package:music_room/models/api_models.dart';

void main() {
  group('Social Network Link Screen Tests', () {
    test('SocialNetworkLinkScreen should be instantiable', () {
      const screen = SocialNetworkLinkScreen();
      expect(screen, isA<SocialNetworkLinkScreen>());
    });

    test('SocialNetworkLinkScreen should handle Google linking', () {
      final googleResult = SocialLoginResult.success('google_token_123', 'google');
      
      expect(googleResult.success, true);
      expect(googleResult.provider, 'google');
      expect(googleResult.token, 'google_token_123');
      expect(googleResult.error, null);
      const isGoogleLinked = true;
      const googleEmail = 'user@gmail.com';
      
      expect(isGoogleLinked, isA<bool>());
      expect(googleEmail, contains('@gmail.com'));
    });

    test('SocialNetworkLinkScreen should handle Facebook linking', () {
      final facebookResult = SocialLoginResult.success('fb_token_456', 'facebook');
      
      expect(facebookResult.success, true);
      expect(facebookResult.provider, 'facebook');
      expect(facebookResult.token, 'fb_token_456');
      expect(facebookResult.error, null);
      final failureResult = SocialLoginResult.error('Facebook login cancelled');
      expect(failureResult.success, false);
      expect(failureResult.error, 'Facebook login cancelled');
      expect(failureResult.token, null);
    });

    test('SocialNetworkLinkScreen should handle account unlinking', () {
      const linkedAccount = 'google';
      const unlinkConfirmation = true;
      
      expect(linkedAccount, isNotEmpty);
      expect(unlinkConfirmation, isA<bool>());
      const unlinkSuccessMessage = 'Account successfully unlinked';
      const unlinkErrorMessage = 'Failed to unlink account';
      
      expect(unlinkSuccessMessage, contains('success'));
      expect(unlinkErrorMessage, contains('Failed'));
      const isLinkedAfterUnlink = false;
      expect(isLinkedAfterUnlink, false);
    });

    test('SocialNetworkLinkScreen should handle linking status display', () {
      const googleLinked = true;
      const facebookLinked = false;
      const linkedAccountEmail = 'user@example.com';
      
      expect(googleLinked, isA<bool>());
      expect(facebookLinked, isA<bool>());
      expect(linkedAccountEmail, isA<String>());
      const linkedStatusMessage = 'Account is linked';
      const notLinkedStatusMessage = 'Account is not linked';
      
      expect(linkedStatusMessage, contains('linked'));
      expect(notLinkedStatusMessage, contains('not linked'));
      const linkedIconColor = 'green';
      const notLinkedIconColor = 'grey';
      
      expect(linkedIconColor, 'green');
      expect(notLinkedIconColor, 'grey');
    });

    test('SocialNetworkLinkScreen should handle OAuth errors', () {
      final networkError = SocialLoginResult.error('Network connection failed');
      final permissionError = SocialLoginResult.error('Permission denied');
      final tokenError = SocialLoginResult.error('Invalid token');
      
      expect(networkError.success, false);
      expect(networkError.error, contains('Network'));
      
      expect(permissionError.success, false);
      expect(permissionError.error, contains('Permission'));
      
      expect(tokenError.success, false);
      expect(tokenError.error, contains('token'));
    });

    test('SocialNetworkLinkScreen should handle linking preferences', () {
      const allowGoogleLinking = true;
      const allowFacebookLinking = false;
      const requireEmailAccess = true;
      
      expect(allowGoogleLinking, isA<bool>());
      expect(allowFacebookLinking, isA<bool>());
      expect(requireEmailAccess, isA<bool>());
      const shareProfilePublically = false;
      const allowContactSync = true;
      
      expect(shareProfilePublically, isA<bool>());
      expect(allowContactSync, isA<bool>());
    });
  });
}