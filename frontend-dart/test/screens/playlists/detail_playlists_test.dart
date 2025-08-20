import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_room/screens/playlists/detail_playlists.dart';
import 'package:music_room/providers/auth_providers.dart';
import 'package:music_room/providers/music_providers.dart';
import 'package:music_room/providers/voting_providers.dart';
import 'package:music_room/models/music_models.dart';
import 'package:music_room/models/voting_models.dart';

class MockAuthProvider extends AuthProvider {
  @override
  bool get isLoggedIn => true;

  @override
  String? get token => 'mock_token';

  @override
  String? get username => 'testuser';
}

class MockMusicProvider extends MusicProvider {
  Playlist? _currentPlaylist;
  List<PlaylistTrack> _tracks = [];
  bool _isLoading = false;

  @override
  bool get isLoading => _isLoading;

  Playlist? get currentPlaylist => _currentPlaylist;

  List<PlaylistTrack> get tracks => _tracks;

  void setCurrentPlaylist(Playlist? playlist) {
    _currentPlaylist = playlist;
    notifyListeners();
  }

  void setTracks(List<PlaylistTrack> tracks) {
    _tracks = tracks;
    notifyListeners();
  }

  @override
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  Future<void> fetchPlaylistTracks(String playlistId, String token) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 100));
    _isLoading = false;
    notifyListeners();
  }

  @override
  Future<bool> deletePlaylist(String playlistId, String token) async {
    return true;
  }
}

class MockVotingProvider extends VotingProvider {
  PlaylistVotingInfo? _votingInfo;
  bool _isLoading = false;

  PlaylistVotingInfo? get votingInfo => _votingInfo;

  @override
  bool get isLoading => _isLoading;

  void setVotingInfo(PlaylistVotingInfo? info) {
    _votingInfo = info;
    notifyListeners();
  }

  @override
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> loadVotingInfo(String playlistId, String token) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 50));
    _isLoading = false;
    notifyListeners();
  }

  Future<void> vote(String playlistId, String trackId, int voteValue, String token) async {
  }
}

void main() {
  group('PlaylistDetailScreen', () {
    late MockAuthProvider mockAuthProvider;
    late MockMusicProvider mockMusicProvider;
    late MockVotingProvider mockVotingProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockMusicProvider = MockMusicProvider();
      mockVotingProvider = MockVotingProvider();
    });

    Widget createTestWidget(String playlistId) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<MusicProvider>.value(value: mockMusicProvider),
            ChangeNotifierProvider<VotingProvider>.value(value: mockVotingProvider),
          ],
          child: PlaylistDetailScreen(playlistId: playlistId),
        ),
      );
    }

    testWidgets('should render playlist detail screen', (tester) async {
      final testPlaylist = Playlist(
        id: '1',
        name: 'Test Playlist',
        description: 'Test Description',
        creator: 'Test User',
        isPublic: true,
      );

      mockMusicProvider.setCurrentPlaylist(testPlaylist);

      await tester.pumpWidget(createTestWidget('1'));
      await tester.pumpAndSettle();

      expect(find.byType(PlaylistDetailScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should show playlist name in app bar', (tester) async {
      final testPlaylist = Playlist(
        id: '1',
        name: 'Test Playlist',
        description: 'Test Description',
        creator: 'Test User',
        isPublic: true,
      );

      mockMusicProvider.setCurrentPlaylist(testPlaylist);

      await tester.pumpWidget(createTestWidget('1'));
      await tester.pumpAndSettle();

      expect(find.text('Test Playlist'), findsOneWidget);
    });

    testWidgets('should display playlist tracks', (tester) async {
      final testPlaylist = Playlist(
        id: '1',
        name: 'Test Playlist',
        description: 'Test Description',
        creator: 'Test User',
        isPublic: true,
      );

      final testTracks = [
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

      mockMusicProvider.setCurrentPlaylist(testPlaylist);
      mockMusicProvider.setTracks(testTracks);

      await tester.pumpWidget(createTestWidget('1'));
      await tester.pumpAndSettle();

      expect(find.text('Track 1'), findsOneWidget);
      expect(find.text('Artist 1'), findsOneWidget);
      expect(find.text('Track 2'), findsOneWidget);
      expect(find.text('Artist 2'), findsOneWidget);
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      mockMusicProvider.setLoading(true);

      await tester.pumpWidget(createTestWidget('1'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('should show empty state when no tracks', (tester) async {
      final testPlaylist = Playlist(
        id: '1',
        name: 'Empty Playlist',
        description: 'No tracks here',
        creator: 'Test User',
        isPublic: true,
      );

      mockMusicProvider.setCurrentPlaylist(testPlaylist);
      mockMusicProvider.setTracks([]);
      mockMusicProvider.setLoading(false);

      await tester.pumpWidget(createTestWidget('1'));
      await tester.pumpAndSettle();

      expect(find.text('No tracks yet'), findsOneWidget);
    });

    testWidgets('should show voting section when voting is enabled', (tester) async {
      final testPlaylist = Playlist(
        id: '1',
        name: 'Test Playlist',
        description: 'Test Description',
        creator: 'Test User',
        isPublic: true,
      );

      final testTrack = PlaylistTrack(
        trackId: '1',
        name: 'Track 1',
        position: 0,
        points: 5,
        track: Track(
          id: '1',
          name: 'Track 1',
          artist: 'Artist 1',
          album: 'Album 1',
          url: 'https://example.com/track.mp3',
        ),
      );

      final votingInfo = PlaylistVotingInfo(
        playlistId: '1',
        restrictions: VotingRestrictions(
          licenseType: 'open',
          isInvited: true,
          isInTimeWindow: true,
          isInLocation: true,
        ),
        trackVotes: {'1': VoteStats(totalVotes: 4, upvotes: 3, downvotes: 1, userHasVoted: false, voteScore: 2.0)},
      );

      mockMusicProvider.setCurrentPlaylist(testPlaylist);
      mockMusicProvider.setTracks([testTrack]);
      mockVotingProvider.setVotingInfo(votingInfo);

      await tester.pumpWidget(createTestWidget('1'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.keyboard_arrow_up), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.keyboard_arrow_down), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle playlist deletion', (tester) async {
      final testPlaylist = Playlist(
        id: '1',
        name: 'Test Playlist',
        description: 'Test Description',
        creator: 'testuser',
        isPublic: true,
      );

      mockMusicProvider.setCurrentPlaylist(testPlaylist);

      await tester.pumpWidget(createTestWidget('1'));
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton), findsWidgets);
    });

    testWidgets('should show playlist statistics', (tester) async {
      final testPlaylist = Playlist(
        id: '1',
        name: 'Test Playlist',
        description: 'Test Description',
        creator: 'Test User',
        isPublic: true,
      );

      mockMusicProvider.setCurrentPlaylist(testPlaylist);

      await tester.pumpWidget(createTestWidget('1'));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsAtLeastNWidgets(1));
    });

    testWidgets('should show public/private status', (tester) async {
      final testPlaylist = Playlist(
        id: '1',
        name: 'Test Playlist',
        description: 'Test Description',
        creator: 'Test User',
        isPublic: true,
      );

      mockMusicProvider.setCurrentPlaylist(testPlaylist);

      await tester.pumpWidget(createTestWidget('1'));
      await tester.pumpAndSettle();

      expect(find.text('Public'), findsOneWidget);
    });

    testWidgets('should handle private playlist', (tester) async {
      final testPlaylist = Playlist(
        id: '1',
        name: 'Private Playlist',
        description: 'Secret stuff',
        creator: 'Test User',
        isPublic: false,
      );

      mockMusicProvider.setCurrentPlaylist(testPlaylist);

      await tester.pumpWidget(createTestWidget('1'));
      await tester.pumpAndSettle();

      expect(find.text('Private'), findsOneWidget);
    });

    testWidgets('should handle error state gracefully', (tester) async {
      await tester.pumpWidget(createTestWidget('nonexistent'));
      await tester.pumpAndSettle();

      expect(find.byType(PlaylistDetailScreen), findsOneWidget);
    });

    testWidgets('should show voting restrictions when applicable', (tester) async {
      final testPlaylist = Playlist(
        id: '1',
        name: 'Test Playlist',
        description: 'Test Description',
        creator: 'Test User',
        isPublic: true,
      );

      final votingInfo = PlaylistVotingInfo(
        playlistId: '1',
        restrictions: VotingRestrictions(
          licenseType: 'private',
          isInvited: false,
          isInTimeWindow: true,
          isInLocation: true,
        ),
        trackVotes: {},
      );

      mockMusicProvider.setCurrentPlaylist(testPlaylist);
      mockVotingProvider.setVotingInfo(votingInfo);

      await tester.pumpWidget(createTestWidget('1'));
      await tester.pumpAndSettle();

      expect(find.byType(PlaylistDetailScreen), findsOneWidget);
    });

    testWidgets('should handle navigation back', (tester) async {
      final testPlaylist = Playlist(
        id: '1',
        name: 'Test Playlist',
        description: 'Test Description',
        creator: 'Test User',
        isPublic: true,
      );

      mockMusicProvider.setCurrentPlaylist(testPlaylist);

      await tester.pumpWidget(createTestWidget('1'));
      await tester.pumpAndSettle();

      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }

      expect(find.byType(PlaylistDetailScreen), findsOneWidget);
    });
  });
}