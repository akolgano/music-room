import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:music_room/screens/profile/user_profile.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/models/api_models.dart';
import 'package:music_room/providers/auth_providers.dart';
import 'package:music_room/providers/friend_providers.dart';
import 'package:music_room/providers/profile_providers.dart';
import 'package:music_room/providers/music_providers.dart';

@GenerateMocks([
  ApiService,
  AuthProvider,
  FriendProvider,
  ProfileProvider,
  MusicProvider,
])
import 'user_profile_test.mocks.dart';

void main() {
  late MockApiService mockApiService;
  late MockAuthProvider mockAuthProvider;
  late MockFriendProvider mockFriendProvider;
  late MockProfileProvider mockProfileProvider;
  late MockMusicProvider mockMusicProvider;

  setUp(() {
    mockApiService = MockApiService();
    mockAuthProvider = MockAuthProvider();
    mockFriendProvider = MockFriendProvider();
    mockProfileProvider = MockProfileProvider();
    mockMusicProvider = MockMusicProvider();

    // Setup default auth provider behavior
    when(mockAuthProvider.token).thenReturn('test_token');
    when(mockAuthProvider.userId).thenReturn('current_user_id');
    when(mockAuthProvider.isLoggedIn).thenReturn(true);
  });

  Widget createTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ChangeNotifierProvider<FriendProvider>.value(value: mockFriendProvider),
        ChangeNotifierProvider<ProfileProvider>.value(value: mockProfileProvider),
        ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('UserPageScreen', () {
    testWidgets('displays loading state initially', (WidgetTester tester) async {
      // Arrange
      when(mockApiService.getProfileById(any, any))
          .thenAnswer((_) async => Future.delayed(const Duration(seconds: 1), () => ProfileByIdResponse(
                id: 'test_user_id',
                user: 'testuser',
                name: 'Test User',
              )));

      // Act
      await tester.pumpWidget(createTestWidget(
        const UserPageScreen(userId: 'test_user_id', username: 'testuser'),
      ));

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading user profile...'), findsOneWidget);
    });

    testWidgets('displays user profile when loaded', (WidgetTester tester) async {
      // Arrange
      final testProfile = ProfileByIdResponse(
        id: 'test_user_id',
        user: 'testuser',
        name: 'Test User',
        bio: 'Test bio',
        location: 'Test Location',
      );

      when(mockApiService.getProfileById(any, any))
          .thenAnswer((_) async => testProfile);
      when(mockApiService.getFriends(any))
          .thenAnswer((_) async => FriendsResponse(friends: []));
      when(mockApiService.getReceivedInvitations(any))
          .thenAnswer((_) async => FriendInvitationsResponse(invitations: []));
      when(mockApiService.getSentInvitations(any))
          .thenAnswer((_) async => FriendInvitationsResponse(invitations: []));

      // Act
      await tester.pumpWidget(createTestWidget(
        const UserPageScreen(userId: 'test_user_id', username: 'testuser'),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('Test Location'), findsOneWidget);
      expect(find.text('Test bio'), findsOneWidget);
    });

    testWidgets('displays not found state when profile load fails', (WidgetTester tester) async {
      // Arrange
      when(mockApiService.getProfileById(any, any))
          .thenThrow(Exception('User not found'));

      // Act
      await tester.pumpWidget(createTestWidget(
        const UserPageScreen(userId: 'test_user_id', username: 'testuser'),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('User profile not found'), findsOneWidget);
      expect(find.text('User ID: test_user_id'), findsOneWidget);
      expect(find.byIcon(Icons.person_off), findsOneWidget);
    });

    testWidgets('shows friend status for non-current user', (WidgetTester tester) async {
      // Arrange
      final testProfile = ProfileByIdResponse(
        id: 'other_user_id',
        user: 'otheruser',
        name: 'Other User',
      );

      when(mockApiService.getProfileById(any, any))
          .thenAnswer((_) async => testProfile);
      when(mockApiService.getFriends(any))
          .thenAnswer((_) async => FriendsResponse(friends: [
                Friend(id: 'other_user_id', username: 'Other User'),
              ]));
      when(mockApiService.getReceivedInvitations(any))
          .thenAnswer((_) async => FriendInvitationsResponse(invitations: []));
      when(mockApiService.getSentInvitations(any))
          .thenAnswer((_) async => FriendInvitationsResponse(invitations: []));

      // Act
      await tester.pumpWidget(createTestWidget(
        const UserPageScreen(userId: 'other_user_id', username: 'otheruser'),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('You are friends with this user'), findsOneWidget);
    });

    testWidgets('shows pending friend request status', (WidgetTester tester) async {
      // Arrange
      final testProfile = ProfileByIdResponse(
        id: 'other_user_id',
        user: 'otheruser',
        name: 'Other User',
      );

      when(mockApiService.getProfileById(any, any))
          .thenAnswer((_) async => testProfile);
      when(mockApiService.getFriends(any))
          .thenAnswer((_) async => FriendsResponse(friends: []));
      when(mockApiService.getReceivedInvitations(any))
          .thenAnswer((_) async => FriendInvitationsResponse(invitations: []));
      when(mockApiService.getSentInvitations(any))
          .thenAnswer((_) async => FriendInvitationsResponse(invitations: [
                {'to_user': 'other_user_id'},
              ]));

      // Act
      await tester.pumpWidget(createTestWidget(
        const UserPageScreen(userId: 'other_user_id', username: 'otheruser'),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Friend Request Sent'), findsOneWidget);
      expect(find.text('Your friend request is pending approval'), findsOneWidget);
    });

    testWidgets('can send friend request', (WidgetTester tester) async {
      // Arrange
      final testProfile = ProfileByIdResponse(
        id: 'other_user_id',
        user: 'otheruser',
        name: 'Other User',
      );

      when(mockApiService.getProfileById(any, any))
          .thenAnswer((_) async => testProfile);
      when(mockApiService.getFriends(any))
          .thenAnswer((_) async => FriendsResponse(friends: []));
      when(mockApiService.getReceivedInvitations(any))
          .thenAnswer((_) async => FriendInvitationsResponse(invitations: []));
      when(mockApiService.getSentInvitations(any))
          .thenAnswer((_) async => FriendInvitationsResponse(invitations: []));
      when(mockFriendProvider.sendFriendRequest(any, any))
          .thenAnswer((_) async => true);

      // Act
      await tester.pumpWidget(createTestWidget(
        const UserPageScreen(userId: 'other_user_id', username: 'otheruser'),
      ));
      await tester.pumpAndSettle();

      // Find and tap the send friend request button
      expect(find.text('Send Friend Request'), findsOneWidget);
      await tester.tap(find.text('Send Friend Request'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockFriendProvider.sendFriendRequest(any, 'other_user_id')).called(1);
    });

    testWidgets('displays avatar with initials when no avatar image', (WidgetTester tester) async {
      // Arrange
      final testProfile = ProfileByIdResponse(
        id: 'test_user_id',
        user: 'testuser',
        name: 'Test User',
      );

      when(mockApiService.getProfileById(any, any))
          .thenAnswer((_) async => testProfile);
      when(mockApiService.getFriends(any))
          .thenAnswer((_) async => FriendsResponse(friends: []));
      when(mockApiService.getReceivedInvitations(any))
          .thenAnswer((_) async => FriendInvitationsResponse(invitations: []));
      when(mockApiService.getSentInvitations(any))
          .thenAnswer((_) async => FriendInvitationsResponse(invitations: []));

      // Act
      await tester.pumpWidget(createTestWidget(
        const UserPageScreen(userId: 'test_user_id', username: 'testuser'),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('TU'), findsOneWidget); // Initials for "Test User"
    });

    testWidgets('displays music preferences when available', (WidgetTester tester) async {
      // Arrange
      final testProfile = ProfileByIdResponse(
        id: 'test_user_id',
        user: 'testuser',
        name: 'Test User',
        musicPreferences: ['Rock', 'Jazz', 'Classical'],
      );

      when(mockApiService.getProfileById(any, any))
          .thenAnswer((_) async => testProfile);
      when(mockApiService.getFriends(any))
          .thenAnswer((_) async => FriendsResponse(friends: []));
      when(mockApiService.getReceivedInvitations(any))
          .thenAnswer((_) async => FriendInvitationsResponse(invitations: []));
      when(mockApiService.getSentInvitations(any))
          .thenAnswer((_) async => FriendInvitationsResponse(invitations: []));

      // Act
      await tester.pumpWidget(createTestWidget(
        const UserPageScreen(userId: 'test_user_id', username: 'testuser'),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Rock, Jazz, Classical'), findsOneWidget);
    });
  });

  group('SocialNetworkLinkScreen', () {
    testWidgets('displays social link options', (WidgetTester tester) async {
      // Arrange
      when(mockProfileProvider.socialType).thenReturn(null);
      when(mockProfileProvider.isLoading).thenReturn(false);

      // Act
      await tester.pumpWidget(createTestWidget(
        const SocialNetworkLinkScreen(),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Link with Social Network'), findsOneWidget);
      expect(find.text('Link Social Account'), findsOneWidget);
      expect(find.text('Connect your social media account for easier sign-in'), findsOneWidget);
    });

    testWidgets('shows connected status when social account is linked', (WidgetTester tester) async {
      // Arrange
      when(mockProfileProvider.socialType).thenReturn('Google');
      when(mockProfileProvider.isLoading).thenReturn(false);

      // Act
      await tester.pumpWidget(createTestWidget(
        const SocialNetworkLinkScreen(),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Your account is linked to Google'), findsOneWidget);
    });

    testWidgets('can link Google account', (WidgetTester tester) async {
      // Arrange
      when(mockProfileProvider.socialType).thenReturn(null);
      when(mockProfileProvider.isLoading).thenReturn(false);
      when(mockProfileProvider.googleLink(any))
          .thenAnswer((_) async => true);
      when(mockProfileProvider.loadProfile(any))
          .thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createTestWidget(
        const SocialNetworkLinkScreen(),
      ));
      await tester.pumpAndSettle();

      // Find and tap Google button
      final googleButton = find.widgetWithText(ElevatedButton, 'Google');
      expect(googleButton, findsOneWidget);
      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      // Assert
      verify(mockProfileProvider.googleLink(any)).called(1);
    });

    testWidgets('displays loading state when linking', (WidgetTester tester) async {
      // Arrange
      when(mockProfileProvider.socialType).thenReturn(null);
      when(mockProfileProvider.isLoading).thenReturn(true);

      // Act
      await tester.pumpWidget(createTestWidget(
        const SocialNetworkLinkScreen(),
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
