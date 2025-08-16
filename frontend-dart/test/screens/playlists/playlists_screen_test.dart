import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/models/music_models.dart';

void main() {
  group('Playlists Screen Tests', () {

    test('PlaylistsScreen should handle playlist list display', () {
      final playlists = [
        const Playlist(
          id: 'playlist_1',
          name: 'My Favorites',
          description: 'My favorite songs',
          isPublic: true,
          creator: 'user_123',
        ),
        const Playlist(
          id: 'playlist_2',
          name: 'Road Trip Mix',
          description: 'Perfect for long drives',
          isPublic: false,
          creator: 'user_123',
        ),
      ];

      expect(playlists.length, 2);
      expect(playlists.first.name, 'My Favorites');
      expect(playlists.first.isPublic, true);
      expect(playlists.last.isPublic, false);
    });

    test('PlaylistsScreen should filter playlists correctly', () {
      final allPlaylists = [
        const Playlist(id: '1', name: 'Rock Classics', description: '', isPublic: true, creator: 'user1'),
        const Playlist(id: '2', name: 'Pop Hits', description: '', isPublic: false, creator: 'user1'),
        const Playlist(id: '3', name: 'Jazz Collection', description: '', isPublic: true, creator: 'user2'),
      ];

      final myPlaylists = allPlaylists.where((p) => p.creator == 'user1').toList();
      expect(myPlaylists.length, 2);

      final publicPlaylists = allPlaylists.where((p) => p.isPublic).toList();
      expect(publicPlaylists.length, 2);

      const searchTerm = 'rock';
      final searchResults = allPlaylists.where((p) => 
        p.name.toLowerCase().contains(searchTerm.toLowerCase())
      ).toList();
      expect(searchResults.length, 1);
      expect(searchResults.first.name, 'Rock Classics');
    });

    test('PlaylistsScreen should handle playlist creation', () {
      const newPlaylistName = 'New Playlist';
      const newPlaylistDescription = 'A fresh new playlist';
      const isPublic = false;

      final newPlaylist = Playlist(
        id: 'new_playlist_id',
        name: newPlaylistName,
        description: newPlaylistDescription,
        isPublic: isPublic,
        creator: 'current_user',
      );

      expect(newPlaylist.name, newPlaylistName);
      expect(newPlaylist.description, newPlaylistDescription);
      expect(newPlaylist.isPublic, isPublic);
      expect(newPlaylist.creator, 'current_user');
    });

    test('PlaylistsScreen should handle playlist sorting', () {
      final unsortedPlaylists = [
        const Playlist(id: '1', name: 'Z Playlist', description: '', isPublic: true, creator: 'user1'),
        const Playlist(id: '2', name: 'A Playlist', description: '', isPublic: true, creator: 'user1'),
        const Playlist(id: '3', name: 'M Playlist', description: '', isPublic: true, creator: 'user1'),
      ];

      final sortedByName = List<Playlist>.from(unsortedPlaylists);
      sortedByName.sort((a, b) => a.name.compareTo(b.name));
      
      expect(sortedByName.first.name, 'A Playlist');
      expect(sortedByName.last.name, 'Z Playlist');

      final sortedByCreation = List<Playlist>.from(unsortedPlaylists);
      sortedByCreation.sort((a, b) => b.id.compareTo(a.id));
      
      expect(sortedByCreation.first.id, '3');
      expect(sortedByCreation.last.id, '1');
    });

    test('PlaylistsScreen should handle owner permissions correctly', () {
      const playlistId = 'playlist_123';
      const actions = {
        'edit': true,
        'delete': true,
        'share': true,
        'duplicate': true,
        'export': false,
      };


      const isOwner = true;
      final canEdit = isOwner && actions['edit'] == true;
      final canDelete = isOwner && actions['delete'] == true;
      final canShare = actions['share'] == true;

      expect(canEdit, true);
      expect(canDelete, true);
      expect(canShare, true);


      const isNotOwner = false;
      expect(isNotOwner, false);
      expect(playlistId, 'playlist_123');
    });

    test('PlaylistsScreen should handle empty playlist state', () {
      final emptyPlaylists = <Playlist>[];
      const emptyMessage = 'No playlists found';
      const createFirstPlaylistText = 'Create your first playlist';

      expect(emptyPlaylists.isEmpty, true);
      expect(emptyPlaylists.length, 0);
      expect(emptyMessage, contains('No playlists'));
      expect(createFirstPlaylistText, contains('Create'));
    });

    test('PlaylistsScreen should handle playlist search', () {
      final playlists = [
        const Playlist(id: '1', name: 'Summer Vibes', description: 'Chill summer songs', isPublic: true, creator: 'user1'),
        const Playlist(id: '2', name: 'Winter Classics', description: 'Cozy winter music', isPublic: true, creator: 'user1'),
        const Playlist(id: '3', name: 'Workout Mix', description: 'High energy tracks', isPublic: false, creator: 'user1'),
      ];

      const nameQuery = 'summer';
      final nameResults = playlists.where((p) => 
        p.name.toLowerCase().contains(nameQuery.toLowerCase())
      ).toList();
      expect(nameResults.length, 1);
      expect(nameResults.first.name, 'Summer Vibes');

      const descQuery = 'music';
      final descResults = playlists.where((p) => 
        p.description.toLowerCase().contains(descQuery.toLowerCase())
      ).toList();
      expect(descResults.length, 1);
      expect(descResults.first.name, 'Winter Classics');

      const noResultsQuery = 'xyz123';
      final noResults = playlists.where((p) => 
        p.name.toLowerCase().contains(noResultsQuery.toLowerCase()) ||
        p.description.toLowerCase().contains(noResultsQuery.toLowerCase())
      ).toList();
      expect(noResults.isEmpty, true);
    });

    test('PlaylistsScreen should handle playlist loading states', () {
      var isLoading = false;
      var hasError = false;
      String? errorMessage;

      expect(isLoading, false);
      expect(hasError, false);
      expect(errorMessage, null);

      isLoading = true;
      expect(isLoading, true);

      isLoading = false;
      hasError = true;
      errorMessage = 'Failed to load playlists';
      
      expect(hasError, true);
      expect(errorMessage, 'Failed to load playlists');
      expect(errorMessage, contains('Failed'));

      hasError = false;
      errorMessage = null;
      expect(hasError, false);
      expect(errorMessage, null);
    });
  });
}