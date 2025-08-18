import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_room/widgets/detail_widgets.dart';
import 'package:music_room/providers/theme_providers.dart';
import 'package:music_room/providers/voting_providers.dart';
import 'package:music_room/models/music_models.dart';

class MockDynamicThemeProvider extends DynamicThemeProvider {
}

class MockVotingProvider extends VotingProvider {
}

void main() {
  group('PlaylistDetailWidgets', () {
    late MockDynamicThemeProvider mockThemeProvider;
    late MockVotingProvider mockVotingProvider;

    setUp(() {
      mockThemeProvider = MockDynamicThemeProvider();
      mockVotingProvider = MockVotingProvider();
    });

    Widget createTestWidget({required Widget child}) {
      return MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider<DynamicThemeProvider>.value(value: mockThemeProvider),
              ChangeNotifierProvider<VotingProvider>.value(value: mockVotingProvider),
            ],
            child: child,
          ),
        ),
      );
    }

    group('buildThemedPlaylistHeader', () {
      testWidgets('should render playlist header with basic information', (tester) async {
        final playlist = Playlist(
          id: '1',
          name: 'Test Playlist',
          description: 'Test Description',
          creator: 'Test User',
          isPublic: true,
        );

        await tester.pumpWidget(createTestWidget(
          child: PlaylistDetailWidgets.buildThemedPlaylistHeader(tester.element(find.byType(Scaffold)), playlist),
        ));

        expect(find.text('Test Playlist'), findsOneWidget);
        expect(find.text('Test Description'), findsOneWidget);
        expect(find.text('Test User'), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('should handle playlist without image', (tester) async {
        final playlist = Playlist(
          id: '1',
          name: 'Test Playlist',
          description: 'Test Description',
          creator: 'Test User',
          isPublic: true,
        );

        await tester.pumpWidget(createTestWidget(
          child: PlaylistDetailWidgets.buildThemedPlaylistHeader(tester.element(find.byType(Scaffold)), playlist),
        ));

        expect(find.byIcon(Icons.queue_music), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('should display playlist with image', (tester) async {
        final playlist = Playlist(
          id: '1',
          name: 'Test Playlist',
          description: 'Test Description',
          creator: 'Test User',
          isPublic: true,
          imageUrl: 'https://example.com/image.jpg',
        );

        await tester.pumpWidget(createTestWidget(
          child: PlaylistDetailWidgets.buildThemedPlaylistHeader(tester.element(find.byType(Scaffold)), playlist),
        ));

        expect(find.text('Test Playlist'), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });
    });

    group('buildThemedPlaylistStats', () {
      testWidgets('should display playlist statistics', (tester) async {
        final tracks = [
          PlaylistTrack(
            trackId: '1',
            name: 'Track 1',
            position: 0,
            points: 5,
            track: Track(
              id: '1',
              name: 'Track 1',
              artist: 'Artist 1',
              album: 'Album 1',
              url: 'https://example.com/track1.mp3',
            ),
          ),
          PlaylistTrack(
            trackId: '2',
            name: 'Track 2',
            position: 1,
            points: 3,
            track: Track(
              id: '2',
              name: 'Track 2',
              artist: 'Artist 2',
              album: 'Album 2',
              url: 'https://example.com/track2.mp3',
            ),
          ),
        ];

        await tester.pumpWidget(createTestWidget(
          child: PlaylistDetailWidgets.buildThemedPlaylistStats(tester.element(find.byType(Scaffold)), tracks),
        ));

        expect(find.text('2'), findsAtLeastNWidgets(1)); // Track count
        expect(find.byType(Row), findsAtLeastNWidgets(1));
      });

      testWidgets('should handle empty track list', (tester) async {
        await tester.pumpWidget(createTestWidget(
          child: PlaylistDetailWidgets.buildThemedPlaylistStats(tester.element(find.byType(Scaffold)), []),
        ));

        expect(find.text('0'), findsAtLeastNWidgets(1));
        expect(find.byType(Row), findsOneWidget);
      });
    });

    group('buildThemedVisibilityChip', () {
      testWidgets('should show public chip for public playlist', (tester) async {
        await tester.pumpWidget(createTestWidget(
          child: PlaylistDetailWidgets.buildThemedVisibilityChip(tester.element(find.byType(Scaffold)), true),
        ));

        expect(find.text('Public'), findsOneWidget);
        expect(find.byIcon(Icons.public), findsOneWidget);
        expect(find.byType(Container), findsOneWidget);
      });

      testWidgets('should show private chip for private playlist', (tester) async {
        await tester.pumpWidget(createTestWidget(
          child: PlaylistDetailWidgets.buildThemedVisibilityChip(tester.element(find.byType(Scaffold)), false),
        ));

        expect(find.text('Private'), findsOneWidget);
        expect(find.byIcon(Icons.lock), findsOneWidget);
        expect(find.byType(Container), findsOneWidget);
      });
    });

    group('buildThemedStatItem', () {
      testWidgets('should display stat item with icon, label, and value', (tester) async {
        await tester.pumpWidget(createTestWidget(
          child: PlaylistDetailWidgets.buildThemedStatItem(
            tester.element(find.byType(Scaffold)),
            icon: Icons.music_note,
            label: 'Tracks',
            value: '10',
          ),
        ));

        expect(find.byIcon(Icons.music_note), findsOneWidget);
        expect(find.text('Tracks'), findsOneWidget);
        expect(find.text('10'), findsOneWidget);
        expect(find.byType(Column), findsOneWidget);
      });
    });

    group('buildTrackImage', () {
      testWidgets('should display track with image', (tester) async {
        final track = Track(
          id: '1',
          name: 'Test Track',
          artist: 'Test Artist',
          album: 'Test Album',
          url: 'https://example.com/track.mp3',
          imageUrl: 'https://example.com/image.jpg',
        );

        await tester.pumpWidget(createTestWidget(
          child: PlaylistDetailWidgets.buildTrackImage(track),
        ));

        expect(find.byType(ClipRRect), findsOneWidget);
        expect(find.byType(Container), findsAtLeastNWidgets(1));
      });

      testWidgets('should display default icon for track without image', (tester) async {
        final track = Track(
          id: '1',
          name: 'Test Track',
          artist: 'Test Artist',
          album: 'Test Album',
          url: 'https://example.com/track.mp3',
        );

        await tester.pumpWidget(createTestWidget(
          child: PlaylistDetailWidgets.buildTrackImage(track),
        ));

        expect(find.byIcon(Icons.music_note), findsOneWidget);
        expect(find.byType(Container), findsOneWidget);
      });
    });

    group('buildEmptyTracksState', () {
      testWidgets('should show empty state for owner', (tester) async {
        bool addTracksPressed = false;

        await tester.pumpWidget(createTestWidget(
          child: PlaylistDetailWidgets.buildEmptyTracksState(
            isOwner: true,
            onAddTracks: () => addTracksPressed = true,
          ),
        ));

        expect(find.text('No tracks yet'), findsOneWidget);
        expect(find.byIcon(Icons.library_music), findsOneWidget);
        expect(find.byType(Column), findsOneWidget);
        
        await tester.tap(find.text('Add Tracks'));
        expect(addTracksPressed, isTrue);
      });

      testWidgets('should show empty state for non-owner', (tester) async {
        await tester.pumpWidget(createTestWidget(
          child: PlaylistDetailWidgets.buildEmptyTracksState(isOwner: false),
        ));

        expect(find.text('No tracks yet'), findsOneWidget);
        expect(find.byIcon(Icons.library_music), findsOneWidget);
        expect(find.text('Add Tracks'), findsNothing);
      });
    });

    group('buildErrorTrackItem', () {
      testWidgets('should display error track item', (tester) async {
        final playlistTrack = PlaylistTrack(
          trackId: '1',
          name: 'Error Track',
          position: 0,
          points: 0,
        );

        await tester.pumpWidget(createTestWidget(
          child: PlaylistDetailWidgets.buildErrorTrackItem(
            const Key('error-track'),
            playlistTrack,
            0,
          ),
        ));

        expect(find.text('Error Track'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.byType(ListTile), findsOneWidget);
      });

      testWidgets('should show loading indicator when loading', (tester) async {
        final playlistTrack = PlaylistTrack(
          trackId: '1',
          name: 'Loading Track',
          position: 0,
          points: 0,
        );

        await tester.pumpWidget(createTestWidget(
          child: PlaylistDetailWidgets.buildErrorTrackItem(
            const Key('loading-track'),
            playlistTrack,
            0,
            isLoading: true,
          ),
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('buildTrackItem', () {
      testWidgets('should display basic track item', (tester) async {
        final track = Track(
          id: '1',
          name: 'Test Track',
          artist: 'Test Artist',
          album: 'Test Album',
          url: 'https://example.com/track.mp3',
        );

        final playlistTrack = PlaylistTrack(
          trackId: '1',
          name: 'Test Track',
          position: 0,
          points: 5,
          track: track,
        );

        await tester.pumpWidget(createTestWidget(
          child: PlaylistDetailWidgets.buildTrackItem(
            context: tester.element(find.byType(Scaffold)),
            playlistTrack: playlistTrack,
            index: 0,
            isOwner: true,
            onPlay: () {},
            onRemove: () {},
            playlistId: '1',
          ),
        ));

        expect(find.text('Test Track'), findsOneWidget);
        expect(find.text('Test Artist'), findsOneWidget);
        expect(find.byType(ListTile), findsOneWidget);
      });

      testWidgets('should show play button when track is not playing', (tester) async {
        final track = Track(
          id: '1',
          name: 'Test Track',
          artist: 'Test Artist',
          album: 'Test Album',
          url: 'https://example.com/track.mp3',
        );

        final playlistTrack = PlaylistTrack(
          trackId: '1',
          name: 'Test Track',
          position: 0,
          points: 5,
          track: track,
        );

        await tester.pumpWidget(createTestWidget(
          child: PlaylistDetailWidgets.buildTrackItem(
            context: tester.element(find.byType(Scaffold)),
            playlistTrack: playlistTrack,
            index: 0,
            isOwner: true,
            onPlay: () {},
            onRemove: () {},
            playlistId: '1',
          ),
        ));

        expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
      });

      testWidgets('should show pause button when track is playing', (tester) async {
        final track = Track(
          id: '1',
          name: 'Test Track',
          artist: 'Test Artist',
          album: 'Test Album',
          url: 'https://example.com/track.mp3',
        );

        final playlistTrack = PlaylistTrack(
          trackId: '1',
          name: 'Test Track',
          position: 0,
          points: 5,
          track: track,
        );

        await tester.pumpWidget(createTestWidget(
          child: PlaylistDetailWidgets.buildTrackItem(
            context: tester.element(find.byType(Scaffold)),
            playlistTrack: playlistTrack,
            index: 0,
            isOwner: true,
            onPlay: () {},
            onRemove: () {},
            playlistId: '1',
          ),
        ));

        expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
      });
    });

    group('buildThemedPlaylistActions', () {
      testWidgets('should display playlist actions', (tester) async {
        bool editPressed = false;
        bool sharePressed = false;

        await tester.pumpWidget(createTestWidget(
          child: PlaylistDetailWidgets.buildThemedPlaylistActions(
            tester.element(find.byType(Scaffold)),
            onPlayAll: () => editPressed = true,
            onShuffle: () => sharePressed = true,
          ),
        ));

        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(find.byIcon(Icons.shuffle), findsOneWidget);

        await tester.tap(find.byIcon(Icons.play_arrow));
        expect(editPressed, isTrue);

        await tester.tap(find.byIcon(Icons.shuffle));
        expect(sharePressed, isTrue);
      });

      testWidgets('should show required action buttons', (tester) async {
        await tester.pumpWidget(createTestWidget(
          child: PlaylistDetailWidgets.buildThemedPlaylistActions(
            tester.element(find.byType(Scaffold)),
            onPlayAll: () {},
            onShuffle: () {},
          ),
        ));

        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(find.byIcon(Icons.shuffle), findsOneWidget);
      });
    });
  });
}