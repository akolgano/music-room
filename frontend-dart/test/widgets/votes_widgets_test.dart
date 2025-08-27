import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:music_room/widgets/votes_widgets.dart';
import 'package:music_room/models/music_models.dart';
import 'package:music_room/models/voting_models.dart';
import 'package:music_room/providers/voting_providers.dart';
import 'package:music_room/providers/auth_providers.dart';
import 'package:music_room/core/logging_core.dart';

@GenerateMocks([VotingProvider, AuthProvider])
import 'votes_widgets_test.mocks.dart';

void main() {
  late MockVotingProvider mockVotingProvider;
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockVotingProvider = MockVotingProvider();
    mockAuthProvider = MockAuthProvider();
    
    when(mockVotingProvider.hasUserVotedForPlaylist).thenReturn(false);
    when(mockVotingProvider.hasError).thenReturn(false);
    when(mockVotingProvider.errorMessage).thenReturn(null);
    when(mockAuthProvider.isLoggedIn).thenReturn(true);
    when(mockAuthProvider.token).thenReturn('test_token');
    when(mockAuthProvider.userId).thenReturn('user123');
    when(mockAuthProvider.username).thenReturn('testuser');
  });

  Widget createWidgetUnderTest(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<VotingProvider>.value(value: mockVotingProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('PlaylistVotingWidgets', () {
    testWidgets('buildVotingModeHeader shows voting banner for owner', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(Container()));
      
      final headers = PlaylistVotingWidgets.buildVotingModeHeader(
        context: tester.element(find.byType(Container).first),
        isOwner: true,
        isPublicVoting: true,
        votingLicenseType: 'open',
        votingStartTime: null,
        votingEndTime: null,
        votingInfo: null,
        onPublicVotingChanged: (_) {},
        onLicenseTypeChanged: (_) {},
        onApplyVotingSettings: () async {},
        onSelectVotingDateTime: (_) async {},
        playlistId: 'playlist123',
      );

      await tester.pumpWidget(createWidgetUnderTest(Column(children: headers)));
      
      expect(find.text('Voting Mode Active'), findsOneWidget);
      expect(find.text('Users can vote for their favorite track. Go to Edit Playlist to configure voting settings.'), findsOneWidget);
      expect(find.text('Configure Voting Settings'), findsOneWidget);
    });

    testWidgets('buildVotingModeHeader shows voting banner for non-owner', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(Container()));
      
      final headers = PlaylistVotingWidgets.buildVotingModeHeader(
        context: tester.element(find.byType(Container).first),
        isOwner: false,
        isPublicVoting: true,
        votingLicenseType: 'open',
        votingStartTime: null,
        votingEndTime: null,
        votingInfo: null,
        onPublicVotingChanged: (_) {},
        onLicenseTypeChanged: (_) {},
        onApplyVotingSettings: () async {},
        onSelectVotingDateTime: (_) async {},
      );

      await tester.pumpWidget(createWidgetUnderTest(Column(children: headers)));
      
      expect(find.text('Voting Mode Active'), findsOneWidget);
      expect(find.text('Vote for your favorite track below to boost its ranking!'), findsOneWidget);
      expect(find.text('Scroll down to see tracks and vote'), findsOneWidget);
    });

    testWidgets('buildVotingTracksSection shows empty state when no tracks', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(Container()));
      
      final widget = PlaylistVotingWidgets.buildVotingTracksSection(
        context: tester.element(find.byType(Container).first),
        tracks: [],
        playlistId: 'playlist123',
        onLoadData: () {},
        onSuggestTrackForVoting: () {},
        votingInfo: null,
      );
      
      await tester.pumpWidget(createWidgetUnderTest(widget));

      expect(find.text('No tracks to vote on'), findsOneWidget);
      expect(find.text('Add tracks to start collaborative voting!'), findsOneWidget);
      expect(find.text('Suggest Track for Voting'), findsOneWidget);
    });

    testWidgets('buildVotingTracksSection shows track list when tracks exist', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(Container()));
      
      final testTrack = Track(
        id: 'track1',
        name: 'Test Track',
        artist: 'Test Artist',
        album: 'Test Album',
        url: 'http://example.com/track',
        imageUrl: null,
        previewUrl: null,
      );

      final playlistTrack = PlaylistTrack(
        trackId: 'track1',
        name: 'Test Track',
        position: 0,
        points: 5,
        track: testTrack,
      );

      final widget = PlaylistVotingWidgets.buildVotingTracksSection(
        context: tester.element(find.byType(Container).first),
        tracks: [playlistTrack],
        playlistId: 'playlist123',
        onLoadData: () {},
        onSuggestTrackForVoting: () {},
        votingInfo: null,
      );

      await tester.pumpWidget(createWidgetUnderTest(SingleChildScrollView(child: widget)));

      expect(find.text('Vote for Your Favorite Track'), findsOneWidget);
      expect(find.text('1 track available • Tap to vote'), findsOneWidget);
      expect(find.text('Test Track'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);
      expect(find.text('Test Album'), findsOneWidget);
    });
  });

  group('TrackVotingControls', () {
    testWidgets('shows vote button and count', (WidgetTester tester) async {
      final voteStats = VoteStats(
        totalVotes: 10,
        upvotes: 10,
        downvotes: 0,
        userHasVoted: false,
        voteScore: 10.0,
      );

      await tester.pumpWidget(createWidgetUnderTest(
        TrackVotingControls(
          playlistId: 'playlist123',
          trackId: 'track1',
          trackIndex: 0,
          stats: voteStats,
          onVoteSubmitted: () {},
        ),
      ));

      expect(find.byIcon(Icons.thumb_up), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('disables vote button when user has voted', (WidgetTester tester) async {
      final voteStats = VoteStats(
        totalVotes: 10,
        upvotes: 10,
        downvotes: 0,
        userHasVoted: true,
        voteScore: 10.0,
      );

      await tester.pumpWidget(createWidgetUnderTest(
        TrackVotingControls(
          playlistId: 'playlist123',
          trackId: 'track1',
          trackIndex: 0,
          stats: voteStats,
          onVoteSubmitted: () {},
        ),
      ));

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('handles vote submission', (WidgetTester tester) async {
      final voteStats = VoteStats(
        totalVotes: 10,
        upvotes: 10,
        downvotes: 0,
        userHasVoted: false,
        voteScore: 10.0,
      );

      var voteSubmitted = false;
      
      when(mockVotingProvider.voteForTrackByIndex(
        playlistId: anyNamed('playlistId'),
        trackIndex: anyNamed('trackIndex'),
        token: anyNamed('token'),
        playlistOwnerId: anyNamed('playlistOwnerId'),
        currentUserId: anyNamed('currentUserId'),
        currentUsername: anyNamed('currentUsername'),
      )).thenAnswer((_) async => true);

      await tester.pumpWidget(createWidgetUnderTest(
        TrackVotingControls(
          playlistId: 'playlist123',
          trackId: 'track1',
          trackIndex: 0,
          stats: voteStats,
          onVoteSubmitted: () => voteSubmitted = true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.thumb_up));
      await tester.pumpAndSettle();

      verify(mockVotingProvider.voteForTrackByIndex(
        playlistId: 'playlist123',
        trackIndex: 0,
        token: 'test_token',
        playlistOwnerId: null,
        currentUserId: 'user123',
        currentUsername: 'testuser',
      )).called(1);
      
      expect(voteSubmitted, isTrue);
    });

    testWidgets('shows error when user not logged in', (WidgetTester tester) async {
      when(mockAuthProvider.token).thenReturn(null);
      
      final voteStats = VoteStats(
        totalVotes: 10,
        upvotes: 10,
        downvotes: 0,
        userHasVoted: false,
        voteScore: 10.0,
      );

      await tester.pumpWidget(createWidgetUnderTest(
        TrackVotingControls(
          playlistId: 'playlist123',
          trackId: 'track1',
          trackIndex: 0,
          stats: voteStats,
        ),
      ));

      await tester.tap(find.byIcon(Icons.thumb_up));
      await tester.pumpAndSettle();

      expect(find.text('You must be logged in to vote'), findsOneWidget);
    });

    testWidgets('shows error when user already voted on playlist', (WidgetTester tester) async {
      when(mockVotingProvider.hasUserVotedForPlaylist).thenReturn(true);
      
      final voteStats = VoteStats(
        totalVotes: 10,
        upvotes: 10,
        downvotes: 0,
        userHasVoted: false,
        voteScore: 10.0,
      );

      await tester.pumpWidget(createWidgetUnderTest(
        TrackVotingControls(
          playlistId: 'playlist123',
          trackId: 'track1',
          trackIndex: 0,
          stats: voteStats,
        ),
      ));

      await tester.tap(find.byIcon(Icons.thumb_up));
      await tester.pumpAndSettle();

      expect(find.text('You have already voted on this playlist'), findsOneWidget);
    });
  });
}