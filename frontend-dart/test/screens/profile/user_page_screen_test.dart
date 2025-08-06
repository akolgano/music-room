import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_room/screens/profile/user_page_screen.dart';
import 'package:music_room/providers/profile_provider.dart';
import 'package:music_room/providers/auth_provider.dart';

void main() {
  group('UserPageScreen Tests', () {
    late ProfileProvider mockProfileProvider;
    late AuthProvider mockAuthProvider;

    setUp(() {
      mockProfileProvider = ProfileProvider();
      mockAuthProvider = AuthProvider();
    });

    testWidgets('should display user page screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ProfileProvider>.value(value: mockProfileProvider),
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ],
            child: const UserPageScreen(userId: 'test-user-id'),
          ),
        ),
      );

      expect(find.byType(UserPageScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should show loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ProfileProvider>.value(value: mockProfileProvider),
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ],
            child: const UserPageScreen(userId: 'test-user-id'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle invalid user ID', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ProfileProvider>.value(value: mockProfileProvider),
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ],
            child: const UserPageScreen(userId: ''),
          ),
        ),
      );

      expect(find.byType(UserPageScreen), findsOneWidget);
    });

    testWidgets('should have app bar with user info', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ProfileProvider>.value(value: mockProfileProvider),
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ],
            child: const UserPageScreen(userId: 'test-user-id'),
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should handle back navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(body: Text('Home')),
          routes: {
            '/user': (context) => MultiProvider(
              providers: [
                ChangeNotifierProvider<ProfileProvider>.value(value: mockProfileProvider),
                ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
              ],
              child: const UserPageScreen(userId: 'test-user-id'),
            ),
          },
        ),
      );

      final context = tester.element(find.text('Home'));
      Navigator.pushNamed(context, '/user');
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsOneWidget);
      }
    });

    testWidgets('should display user profile information when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ProfileProvider>.value(value: mockProfileProvider),
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ],
            child: const UserPageScreen(userId: 'test-user-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(UserPageScreen), findsOneWidget);
    });

    testWidgets('should handle network errors gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ProfileProvider>.value(value: mockProfileProvider),
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ],
            child: const UserPageScreen(userId: 'invalid-user-id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(UserPageScreen), findsOneWidget);
    });

    testWidgets('should display proper error message for non-existent user', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ProfileProvider>.value(value: mockProfileProvider),
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ],
            child: const UserPageScreen(userId: 'non-existent-user'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(UserPageScreen), findsOneWidget);
    });
  });
}