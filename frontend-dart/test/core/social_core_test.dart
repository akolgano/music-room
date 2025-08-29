import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:music_room/core/social_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SocialLoginButton Tests', () {
    testWidgets('should render Google login button correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButton(
              provider: 'Google',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byIcon(Icons.g_mobiledata), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should render Facebook login button correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButton(
              provider: 'Facebook',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Continue with Facebook'), findsOneWidget);
      expect(find.byIcon(Icons.facebook), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should show loading state when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButton(
              provider: 'Google',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Continue with Google'), findsNothing);
    });

    testWidgets('should disable button when loading', (WidgetTester tester) async {
      bool buttonPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButton(
              provider: 'Google',
              isLoading: true,
              onPressed: () {
                buttonPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(buttonPressed, isFalse);
    });

    testWidgets('should call onPressed when button is tapped', (WidgetTester tester) async {
      bool buttonPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialLoginButton(
              provider: 'Google',
              onPressed: () {
                buttonPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(buttonPressed, isTrue);
    });

    testWidgets('should throw error for unsupported provider', (WidgetTester tester) async {
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SocialLoginButton(
                provider: 'UnsupportedProvider',
              ),
            ),
          ),
        );
        fail('Should have thrown ArgumentError');
      } catch (e) {
        expect(e, isA<ArgumentError>());
      }
    });
  });

  group('SocialProfileWidget Tests', () {
    testWidgets('should render profile information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialProfileWidget(
              username: 'testuser',
              bio: 'Test bio description',
              followersCount: 100,
              followingCount: 50,
            ),
          ),
        ),
      );

      expect(find.text('@testuser'), findsOneWidget);
      expect(find.text('Test bio description'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('Followers'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
    });

    testWidgets('should show avatar with first letter when no avatar URL', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialProfileWidget(
              username: 'Alice',
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('should show ? for empty username when no avatar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialProfileWidget(
              username: '',
            ),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('should render follow button when onFollowPressed is provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: SocialProfileWidget(
                username: 'testuser',
                onFollowPressed: () {},
                isFollowing: false,
              ),
            ),
          ),
        ),
      );

      final elevatedButtons = find.byType(ElevatedButton);
      expect(elevatedButtons, findsOneWidget);
      expect(find.text('Follow'), findsOneWidget);
    });

    testWidgets('should show Following when isFollowing is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: SocialProfileWidget(
                username: 'testuser',
                onFollowPressed: () {},
                isFollowing: true,
              ),
            ),
          ),
        ),
      );

      final elevatedButtons = find.byType(ElevatedButton);
      expect(elevatedButtons, findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
    });

    testWidgets('should call onFollowPressed when follow button is tapped', (WidgetTester tester) async {
      bool followPressed = false;
      
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: SocialProfileWidget(
                username: 'testuser',
                onFollowPressed: () {
                  followPressed = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(followPressed, isTrue);
    });

    testWidgets('should not show follow button when onFollowPressed is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialProfileWidget(
              username: 'testuser',
            ),
          ),
        ),
      );

      expect(find.text('Follow'), findsNothing);
      expect(find.text('Following'), findsNothing);
    });
  });

  group('SocialActivityItem Tests', () {
    testWidgets('should render activity item correctly', (WidgetTester tester) async {
      final timestamp = DateTime.now();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialActivityItem(
              username: 'testuser',
              activity: 'Posted a new song',
              timestamp: timestamp,
            ),
          ),
        ),
      );

      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('Posted a new song'), findsOneWidget);
      expect(find.text('Just now'), findsOneWidget);
    });

    testWidgets('should show avatar with first letter when no avatar URL', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialActivityItem(
              username: 'Bob',
              activity: 'Test activity',
              timestamp: DateTime.now(),
            ),
          ),
        ),
      );

      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('should show ? for empty username', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialActivityItem(
              username: '',
              activity: 'Test activity',
              timestamp: DateTime.now(),
            ),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('should render content widget when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialActivityItem(
              username: 'testuser',
              activity: 'Shared a playlist',
              timestamp: DateTime.now(),
              content: const Text('Custom Content'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Content'), findsOneWidget);
    });

    testWidgets('should render action buttons when provided', (WidgetTester tester) async {
      bool likeTapped = false;
      bool commentTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialActivityItem(
              username: 'testuser',
              activity: 'Posted something',
              timestamp: DateTime.now(),
              actions: [
                SocialAction(
                  icon: Icons.favorite,
                  label: 'Like',
                  onTap: () {
                    likeTapped = true;
                  },
                ),
                SocialAction(
                  icon: Icons.comment,
                  label: 'Comment',
                  onTap: () {
                    commentTapped = true;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Like'), findsOneWidget);
      expect(find.text('Comment'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.comment), findsOneWidget);

      await tester.tap(find.text('Like'));
      await tester.pump();
      expect(likeTapped, isTrue);

      await tester.tap(find.text('Comment'));
      await tester.pump();
      expect(commentTapped, isTrue);
    });

    testWidgets('should show active state for actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialActivityItem(
              username: 'testuser',
              activity: 'Posted',
              timestamp: DateTime.now(),
              actions: [
                SocialAction(
                  icon: Icons.favorite,
                  label: 'Liked',
                  onTap: () {},
                  isActive: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Liked'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    group('Timestamp Formatting', () {
      testWidgets('should show "Just now" for recent activity', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SocialActivityItem(
                username: 'user',
                activity: 'activity',
                timestamp: DateTime.now(),
              ),
            ),
          ),
        );

        expect(find.text('Just now'), findsOneWidget);
      });

      testWidgets('should show minutes ago for recent activity', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SocialActivityItem(
                username: 'user',
                activity: 'activity',
                timestamp: DateTime.now().subtract(Duration(minutes: 5)),
              ),
            ),
          ),
        );

        expect(find.text('5m ago'), findsOneWidget);
      });

      testWidgets('should show hours ago for same day activity', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SocialActivityItem(
                username: 'user',
                activity: 'activity',
                timestamp: DateTime.now().subtract(Duration(hours: 3)),
              ),
            ),
          ),
        );

        expect(find.text('3h ago'), findsOneWidget);
      });

      testWidgets('should show days ago for recent days', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SocialActivityItem(
                username: 'user',
                activity: 'activity',
                timestamp: DateTime.now().subtract(Duration(days: 2)),
              ),
            ),
          ),
        );

        expect(find.text('2d ago'), findsOneWidget);
      });

      testWidgets('should show date for older activity', (WidgetTester tester) async {
        final oldDate = DateTime(2024, 1, 15);
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SocialActivityItem(
                username: 'user',
                activity: 'activity',
                timestamp: oldDate,
              ),
            ),
          ),
        );

        expect(find.text('15/1/2024'), findsOneWidget);
      });
    });
  });

  group('SocialAction Tests', () {
    test('should create SocialAction with required properties', () {
      final action = SocialAction(
        icon: Icons.favorite,
        label: 'Like',
        onTap: () {},
      );

      expect(action.icon, Icons.favorite);
      expect(action.label, 'Like');
      expect(action.isActive, false);
    });

    test('should create SocialAction with active state', () {
      final action = SocialAction(
        icon: Icons.favorite,
        label: 'Like',
        onTap: () {},
        isActive: true,
      );

      expect(action.isActive, true);
    });
  });
}
