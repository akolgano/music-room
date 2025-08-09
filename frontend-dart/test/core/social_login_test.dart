import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/core/social_login.dart';
void main() {
  group('SocialLoginUtils Tests', () {
    test('SocialLoginUtils should have correct initial state', () {
      expect(SocialLoginUtils.isInitialized, false);
    });
  });
  group('SocialLoginButton Tests', () {
    testWidgets('SocialLoginButton should render correctly', (WidgetTester tester) async {
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
