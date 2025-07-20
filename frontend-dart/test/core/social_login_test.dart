import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/core/social_login.dart';

void main() {
  group('SocialLoginUtils Tests', () {
    test('SocialLoginUtils should have correct initial state', () {
      print('Testing: SocialLoginUtils should have correct initial state');
      expect(SocialLoginUtils.isInitialized, false);
      expect(SocialLoginUtils.isFacebookInitialized, false);
      expect(SocialLoginUtils.googleSignInInstance, null);
    });
  });

  group('SocialLoginButton Tests', () {
    testWidgets('SocialLoginButton should render correctly', (WidgetTester tester) async {
      print('Testing: SocialLoginButton should render correctly');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButton(
              provider: 'google',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Continue with google'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('SocialLoginButton should show loading state', (WidgetTester tester) async {
      print('Testing: SocialLoginButton should show loading state');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButton(
              provider: 'facebook',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Continue with facebook'), findsNothing);
    });

    testWidgets('SocialLoginButton should handle different providers', (WidgetTester tester) async {
      print('Testing: SocialLoginButton should handle different providers');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButton(
              provider: 'google',
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.text('Continue with google'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButton(
              provider: 'facebook',
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.text('Continue with facebook'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButton(
              provider: 'other',
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.text('Continue with other'), findsOneWidget);
    });

    testWidgets('SocialLoginButton should be disabled when loading', (WidgetTester tester) async {
      print('Testing: SocialLoginButton should be disabled when loading');
      bool pressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButton(
              provider: 'google',
              isLoading: true,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(pressed, false);
    });
  });
}
