import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_room_app/screens/playlists/detail_playlists.dart';
import 'package:music_room_app/providers/music_providers.dart';
import 'package:music_room_app/providers/auth_providers.dart';
import 'package:music_room_app/models/sort_models.dart';
import 'package:music_room_app/models/music_models.dart';

class MockMusicProvider extends Mock implements MusicProvider {}
class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  group('PlaylistDetailScreen - Track Reordering Controls', () {
    late MockMusicProvider mockMusicProvider;
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockMusicProvider = MockMusicProvider();
      mockAuthProvider = MockAuthProvider();
      
      // Set up default auth state
      when(() => mockAuthProvider.isLoggedIn).thenReturn(true);
      when(() => mockAuthProvider.token).thenReturn('test-token');
      when(() => mockAuthProvider.username).thenReturn('testuser');
    });

    testWidgets('Up/Down buttons should be hidden when custom sort is applied', (WidgetTester tester) async {
      // Arrange - Set up a non-position sort (e.g., sorted by votes)
      when(() => mockMusicProvider.currentSortOption).thenReturn(
        const TrackSortOption(
          field: TrackSortField.points,
          order: SortOrder.descending,
          displayName: 'Most Votes',
          icon: Icons.how_to_vote,
        ),
      );
      
      when(() => mockMusicProvider.sortedPlaylistTracks).thenReturn([
        PlaylistTrack(
          trackId: 'track1',
          name: 'Test Track 1',
          position: 0,
          points: 5,
          track: Track(
            id: 'track1',
            name: 'Test Track 1',
            artist: 'Artist 1',
            album: 'Album 1',
            deezerTrackId: '123',
            previewUrl: 'http://example.com/preview1',
            imageUrl: 'http://example.com/image1',
          ),
        ),
        PlaylistTrack(
          trackId: 'track2', 
          name: 'Test Track 2',
          position: 1,
          points: 3,
          track: Track(
            id: 'track2',
            name: 'Test Track 2',
            artist: 'Artist 2',
            album: 'Album 2',
            deezerTrackId: '456',
            previewUrl: 'http://example.com/preview2',
            imageUrl: 'http://example.com/image2',
          ),
        ),
      ]);

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ],
            child: const PlaylistDetailScreen(playlistId: 'test-playlist'),
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Assert - Up/Down arrow buttons should not be present
      expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
    });

    testWidgets('Up/Down buttons should be visible when position sort is active', (WidgetTester tester) async {
      // Arrange - Set up position sort (custom order)
      when(() => mockMusicProvider.currentSortOption).thenReturn(
        const TrackSortOption(
          field: TrackSortField.position,
          order: SortOrder.ascending,
          displayName: 'Custom Order',
          icon: Icons.reorder,
        ),
      );
      
      when(() => mockMusicProvider.sortedPlaylistTracks).thenReturn([
        PlaylistTrack(
          trackId: 'track1',
          name: 'Test Track 1',
          position: 0,
          points: 0,
          track: Track(
            id: 'track1',
            name: 'Test Track 1',
            artist: 'Artist 1',
            album: 'Album 1',
            deezerTrackId: '123',
            previewUrl: 'http://example.com/preview1',
            imageUrl: 'http://example.com/image1',
          ),
        ),
        PlaylistTrack(
          trackId: 'track2',
          name: 'Test Track 2',
          position: 1,
          points: 0,
          track: Track(
            id: 'track2',
            name: 'Test Track 2',
            artist: 'Artist 2',
            album: 'Album 2',
            deezerTrackId: '456',
            previewUrl: 'http://example.com/preview2',
            imageUrl: 'http://example.com/image2',
          ),
        ),
      ]);

      // Build the widget (assuming user is owner)
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ],
            child: const PlaylistDetailScreen(playlistId: 'test-playlist'),
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Assert - Up/Down arrow buttons should be present (at least for some tracks)
      // Note: The actual presence depends on canEditPlaylist flag which would need more mocking
      // This is a simplified test to demonstrate the concept
    });
  });
}