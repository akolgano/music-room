import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_room/widgets/playlist_voting_widgets.dart';
import 'package:music_room/providers/voting_provider.dart';
import 'package:music_room/models/music_models.dart';

void main() {
  group('PlaylistVotingWidgets Tests', () {
    late VotingProvider mockVotingProvider;
    late List<PlaylistTrack> mockTracks;

    setUp(() {
      mockVotingProvider = VotingProvider();
      mockTracks = [
        PlaylistTrack(
          trackId: '1',
          name: 'Test Track 1',
          position: 0,
          track: Track(
            id: '1',
            name: 'Test Track 1',
            artist: 'Test Artist 1',
            album: 'Test Album 1',
            url: 'https://example.com/track1',
            deezerTrackId: '123',
          ),
        ),
        PlaylistTrack(
          trackId: '2',
          name: 'Test Track 2',
          position: 1,
          track: Track(
            id: '2',
            name: 'Test Track 2',
            artist: 'Test Artist 2',
            album: 'Test Album 2',
            url: 'https://example.com/track2',
            deezerTrackId: '456',
          ),
        ),
      ];
    });

    testWidgets('buildVotingModeHeader should display voting controls for owner', (WidgetTester tester) async {
      final widgets = PlaylistVotingWidgets.buildVotingModeHeader(
        context: tester.element(find.byType(Container).first),
        isOwner: true,
        isPublicVoting: true,
        votingLicenseType: 'open',
        votingStartTime: null,
        votingEndTime: null,
        votingInfo: null,
        onPublicVotingChanged: (value) {},
        onLicenseTypeChanged: (value) {},
        onApplyVotingSettings: () async {},
        onSelectVotingDateTime: (isStart) async {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(children: widgets),
          ),
        ),
      );

      expect(find.text('Voting Mode'), findsOneWidget);
      expect(find.text('Public Voting'), findsOneWidget);
    });

    testWidgets('buildVotingModeHeader should handle non-owner view', (WidgetTester tester) async {
      final widgets = PlaylistVotingWidgets.buildVotingModeHeader(
        context: tester.element(find.byType(Container).first),
        isOwner: false,
        isPublicVoting: false,
        votingLicenseType: 'private',
        votingStartTime: null,
        votingEndTime: null,
        votingInfo: null,
        onPublicVotingChanged: (value) {},
        onLicenseTypeChanged: (value) {},
        onApplyVotingSettings: () async {},
        onSelectVotingDateTime: (isStart) async {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(children: widgets),
          ),
        ),
      );

      expect(find.text('Voting Mode'), findsOneWidget);
    });

    testWidgets('buildVotingTracksSection should display tracks for voting', (WidgetTester tester) async {
      final widget = PlaylistVotingWidgets.buildVotingTracksSection(
        context: tester.element(find.byType(Container).first),
        tracks: mockTracks,
        playlistId: 'test-playlist',
        onLoadData: () {},
        onSuggestTrackForVoting: () {},
        votingInfo: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<VotingProvider>.value(
            value: mockVotingProvider,
            child: Scaffold(body: widget),
          ),
        ),
      );

      expect(find.text('Test Track 1'), findsOneWidget);
      expect(find.text('Test Track 2'), findsOneWidget);
      expect(find.text('Test Artist 1'), findsOneWidget);
      expect(find.text('Test Artist 2'), findsOneWidget);
    });

    testWidgets('should handle empty tracks list', (WidgetTester tester) async {
      final widget = PlaylistVotingWidgets.buildVotingTracksSection(
        context: tester.element(find.byType(Container).first),
        tracks: [],
        playlistId: 'test-playlist',
        onLoadData: () {},
        onSuggestTrackForVoting: () {},
        votingInfo: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<VotingProvider>.value(
            value: mockVotingProvider,
            child: Scaffold(body: widget),
          ),
        ),
      );

      expect(find.text('No tracks available for voting'), findsOneWidget);
    });

    testWidgets('should handle suggest track button tap', (WidgetTester tester) async {
      bool suggestCalled = false;
      
      final widget = PlaylistVotingWidgets.buildVotingTracksSection(
        context: tester.element(find.byType(Container).first),
        tracks: mockTracks,
        playlistId: 'test-playlist',
        onLoadData: () {},
        onSuggestTrackForVoting: () {
          suggestCalled = true;
        },
        votingInfo: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<VotingProvider>.value(
            value: mockVotingProvider,
            child: Scaffold(body: widget),
          ),
        ),
      );

      if (find.text('Suggest Track').evaluate().isNotEmpty) {
        await tester.tap(find.text('Suggest Track'));
        await tester.pump();
        expect(suggestCalled, isTrue);
      }
    });
  });
}