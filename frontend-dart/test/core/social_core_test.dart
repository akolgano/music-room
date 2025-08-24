import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/core/social_core.dart';

void main() {
  group('SocialLoginUtils Tests', () {
    test('SocialLoginUtils should have initialize method', () {
      expect(SocialLoginUtils.initialize, isA<Function>());
    });

    test('SocialLoginUtils should handle initialization', () {
      expect(() => SocialLoginUtils.initialize(), returnsNormally);
    });

    test('SocialLoginUtils should provide static methods', () {
      expect(SocialLoginUtils.initialize, isNotNull);
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

    testWidgets('SocialLoginButton should handle tap events', (WidgetTester tester) async {
      bool pressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButton(
              provider: 'google',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );
      
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(pressed, true);
    });

    testWidgets('SocialLoginButton should handle null onPressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButton(
              provider: 'google',
              onPressed: null,
            ),
          ),
        ),
      );
      
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('SocialLoginButton should support custom styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButton(
              provider: 'apple',
              onPressed: () {},
            ),
          ),
        ),
      );
      
      expect(find.text('Continue with apple'), findsOneWidget);
    });

    testWidgets('SocialLoginButton should handle state changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButton(
              provider: 'github',
              onPressed: () {},
              isLoading: false,
            ),
          ),
        ),
      );
      
      expect(find.text('Continue with github'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('SocialLoginButton should display proper text format', (WidgetTester tester) async {
      const providers = ['google', 'facebook', 'apple', 'github', 'twitter'];
      
      for (final provider in providers) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SocialLoginButton(
                provider: provider,
                onPressed: () {},
              ),
            ),
          ),
        );
        
        expect(find.text('Continue with $provider'), findsOneWidget);
      }
    });
  });
}
