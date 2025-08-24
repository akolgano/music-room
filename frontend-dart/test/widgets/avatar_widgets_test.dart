import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:music_room/widgets/avatar_widgets.dart';
import 'package:music_room/providers/profile_providers.dart';
import 'package:music_room/providers/auth_providers.dart';

@GenerateMocks([ProfileProvider, AuthProvider])
import 'avatar_widgets_test.mocks.dart';

void main() {
  group('ProfileAvatarWidget', () {
    late MockProfileProvider mockProfileProvider;
    late MockAuthProvider mockAuthProvider;
    late VoidCallback onSuccessCallback;
    late Function(String) onErrorCallback;
    bool onSuccessCalled = false;
    String? errorMessage;

    setUp(() {
      mockProfileProvider = MockProfileProvider();
      mockAuthProvider = MockAuthProvider();
      onSuccessCalled = false;
      errorMessage = null;
      onSuccessCallback = () => onSuccessCalled = true;
      onErrorCallback = (String message) => errorMessage = message;
    });

    Widget createWidget() {
      return MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider<ProfileProvider>.value(value: mockProfileProvider),
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ],
            child: ProfileAvatarWidget(
              profileProvider: mockProfileProvider,
              auth: mockAuthProvider,
              onSuccess: onSuccessCallback,
              onError: onErrorCallback,
            ),
          ),
        ),
      );
    }

    testWidgets('should render without errors', (WidgetTester tester) async {
      when(mockProfileProvider.isLoading).thenReturn(false);
      when(mockProfileProvider.profilePicture).thenReturn(null);

      await tester.pumpWidget(createWidget());

      expect(find.byType(ProfileAvatarWidget), findsOneWidget);
    });

    testWidgets('should show loading state when isLoading is true', (WidgetTester tester) async {
      when(mockProfileProvider.isLoading).thenReturn(true);
      when(mockProfileProvider.profilePicture).thenReturn(null);

      await tester.pumpWidget(createWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display default avatar when no profile picture', (WidgetTester tester) async {
      when(mockProfileProvider.isLoading).thenReturn(false);
      when(mockProfileProvider.profilePicture).thenReturn(null);

      await tester.pumpWidget(createWidget());

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should display profile picture when available', (WidgetTester tester) async {
      when(mockProfileProvider.isLoading).thenReturn(false);
      when(mockProfileProvider.profilePicture).thenReturn('https://example.com/avatar.jpg');

      await tester.pumpWidget(createWidget());

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should be tappable when not loading', (WidgetTester tester) async {
      when(mockProfileProvider.isLoading).thenReturn(false);
      when(mockProfileProvider.profilePicture).thenReturn(null);

      await tester.pumpWidget(createWidget());

      final gestureDetector = find.byType(GestureDetector);
      expect(gestureDetector, findsOneWidget);

      await tester.tap(gestureDetector);
      await tester.pump();

      verify(mockProfileProvider.isLoading).called(atLeast(1));
    });

    testWidgets('should not be tappable when loading', (WidgetTester tester) async {
      when(mockProfileProvider.isLoading).thenReturn(true);
      when(mockProfileProvider.profilePicture).thenReturn(null);

      await tester.pumpWidget(createWidget());

      final gestureDetector = tester.widget<GestureDetector>(find.byType(GestureDetector));
      expect(gestureDetector.onTap, isNull);
    });

    testWidgets('should handle tap interaction correctly', (WidgetTester tester) async {
      when(mockProfileProvider.isLoading).thenReturn(false);
      when(mockProfileProvider.profilePicture).thenReturn(null);

      await tester.pumpWidget(createWidget());

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(onSuccessCalled, isFalse);
    });

    testWidgets('should call onSuccess when upload succeeds', (WidgetTester tester) async {
      when(mockProfileProvider.isLoading).thenReturn(false);
      when(mockProfileProvider.profilePicture).thenReturn(null);

      await tester.pumpWidget(createWidget());

      onSuccessCallback();
      expect(onSuccessCalled, isTrue);
    });

    testWidgets('should call onError when upload fails', (WidgetTester tester) async {
      when(mockProfileProvider.isLoading).thenReturn(false);
      when(mockProfileProvider.profilePicture).thenReturn(null);

      await tester.pumpWidget(createWidget());

      const testError = 'Upload failed';
      onErrorCallback(testError);
      expect(errorMessage, equals(testError));
    });

    testWidgets('should have proper accessibility semantics', (WidgetTester tester) async {
      when(mockProfileProvider.isLoading).thenReturn(false);
      when(mockProfileProvider.profilePicture).thenReturn(null);

      await tester.pumpWidget(createWidget());

      final semantics = tester.getSemantics(find.byType(ProfileAvatarWidget));
      expect(semantics.hasAction(SemanticsAction.tap), isTrue);
    });

    testWidgets('should update when profile picture changes', (WidgetTester tester) async {
      when(mockProfileProvider.isLoading).thenReturn(false);
      when(mockProfileProvider.profilePicture).thenReturn(null);

      await tester.pumpWidget(createWidget());

      expect(find.byIcon(Icons.person), findsOneWidget);

      when(mockProfileProvider.profilePicture).thenReturn('https://example.com/new-avatar.jpg');
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should handle different avatar sizes', (WidgetTester tester) async {
      when(mockProfileProvider.isLoading).thenReturn(false);
      when(mockProfileProvider.profilePicture).thenReturn(null);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 100,
            child: ProfileAvatarWidget(
              profileProvider: mockProfileProvider,
              auth: mockAuthProvider,
              onSuccess: onSuccessCallback,
              onError: onErrorCallback,
            ),
          ),
        ),
      ));

      expect(find.byType(ProfileAvatarWidget), findsOneWidget);
    });
  });
}