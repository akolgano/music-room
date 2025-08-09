import 'package:collection/collection.dart';
import '../services/api_service.dart';
import '../models/music_models.dart';
import '../models/api_models.dart';
import '../models/sort_models.dart';
import '../core/logging_navigation_observer.dart';

class TrackSortingService {
  static List<PlaylistTrack> sortTracks(List<PlaylistTrack> tracks, TrackSortOption sortOption) {
    return tracks.sorted((a, b) {
      final comparison = _getComparison(a, b, sortOption.field);
      return sortOption.order == SortOrder.ascending ? comparison : -comparison;
    });
  }

  static List<Track> sortTrackList(List<Track> tracks, TrackSortOption sortOption) {
    return tracks.sorted((a, b) {
      final comparison = _getTrackComparison(a, b, sortOption.field);
      return sortOption.order == SortOrder.ascending ? comparison : -comparison;
    });
  }

  static int _getTrackComparison(Track a, Track b, TrackSortField field) {
    switch (field) {
      case TrackSortField.position: return 0;
      case TrackSortField.name: return compareAsciiLowerCase(a.name, b.name);
      case TrackSortField.artist: return compareAsciiLowerCase(a.artist, b.artist);
      case TrackSortField.album: return compareAsciiLowerCase(a.album, b.album);
      case TrackSortField.dateAdded: return 0;
    }
  }

  static int _getComparison(PlaylistTrack a, PlaylistTrack b, TrackSortField field) {
    switch (field) {
      case TrackSortField.position:
        return a.position.compareTo(b.position);
      case TrackSortField.name:
        final aName = a.track?.name ?? a.name;
        final bName = b.track?.name ?? b.name;
        return compareAsciiLowerCase(aName, bName);
      case TrackSortField.artist:
        final aArtist = a.track?.artist ?? '';
        final bArtist = b.track?.artist ?? '';
        return compareAsciiLowerCase(aArtist, bArtist);
      case TrackSortField.album:
        final aAlbum = a.track?.album ?? '';
        final bAlbum = b.track?.album ?? '';
        return compareAsciiLowerCase(aAlbum, bAlbum);
      case TrackSortField.dateAdded:
        return a.position.compareTo(b.position);
    }
  }

  static List<PlaylistTrack> filterTracks(List<PlaylistTrack> tracks, String searchTerm) {
    if (searchTerm.isEmpty) return tracks;
    final lowerSearchTerm = searchTerm.toLowerCase();
    return tracks.where((track) {
      final name = (track.track?.name ?? track.name).toLowerCase();
      final artist = (track.track?.artist ?? '').toLowerCase();
      final album = (track.track?.album ?? '').toLowerCase();
      return name.contains(lowerSearchTerm) || artist.contains(lowerSearchTerm) || album.contains(lowerSearchTerm);
    }).toList();
  }
}

class MusicService {
  final ApiService _api;

  MusicService(this._api);

  Future<List<Playlist>> getUserPlaylists(String token) async {
    final response = await _api.getSavedPlaylists(token); 
    return response.playlists;
  }

  Future<List<Playlist>> getPublicPlaylists(String token) async {
    AppLogger.debug('MusicService: Calling API to get public playlists', 'MusicService');
    final response = await _api.getPublicPlaylists(token); 
    AppLogger.debug('MusicService: API returned ${response.playlists.length} public playlists', 'MusicService');
    return response.playlists;
  }

  Future<Playlist> getPlaylistDetails(String id, String token) async {
    final response = await _api.getPlaylist(id, token); 
    return response.playlist;
  }

  Future<String> createPlaylist(String name, String description, bool isPublic, String token, [String? deviceUuid]) async {
    final request = CreatePlaylistRequest(name: name, description: description, public: isPublic, deviceUuid: deviceUuid);
    final response = await _api.createPlaylist(token, request); 
    return response.playlistId;
  }

  Future<List<Track>> searchDeezerTracks(String query) async {
    final response = await _api.searchDeezerTracks(query);
    return response.data;
  }

  Future<List<Track>> searchTracks(String query, String token) async {
    final response = await _api.searchTracks(query, token);
    return response.data;
  }

  Future<Track?> getDeezerTrack(String trackId, String token) async {
    return await _api.getDeezerTrack(trackId, token);
  }

  Future<List<PlaylistTrack>> getPlaylistTracksWithDetails(String playlistId, String token) async {
    final response = await _api.getPlaylistTracks(playlistId, token); 
    return response.tracks;
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId, String token) async {
    final request = AddTrackRequest(trackId: trackId);
    await _api.addTrackToPlaylist(playlistId, token, request); 
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId, String token) async {
    await _api.removeTrackFromPlaylist(playlistId, trackId, token); 
  }

  Future<void> moveTrackInPlaylist({required String playlistId, 
    required int rangeStart,
    required int insertBefore,
    int rangeLength = 1,
    required String token,
  }) async {
    final request = MoveTrackRequest(rangeStart: rangeStart, insertBefore: insertBefore, rangeLength: rangeLength);
    await _api.moveTrackInPlaylist(playlistId, token, request); 
  }

  Future<void> inviteUserToPlaylist(String playlistId, String userId, String token) async {
    final request = InviteUserRequest(userId: userId);
    await _api.inviteUserToPlaylist(playlistId, token, request); 
  }

  Future<List<Track>> getRandomTracks({int count = 10}) async {
    final randomQueries = [
      'pop', 'rock', 'jazz', 'electronic', 'hip hop', 'classical', 'indie', 'dance', 'blues', 'reggae',
      'folk', 'country', 'metal', 'punk', 'soul', 'funk', 'disco', 'house', 'techno', 'ambient',
      'a', 'e', 'i', 'o', 'u', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of',
      'love', 'life', 'time', 'night', 'day', 'home', 'heart', 'world', 'dream', 'fire', 'water'
    ];
    
    final random = DateTime.now().millisecondsSinceEpoch;
    final query = randomQueries[random % randomQueries.length];
    
    try {
      final response = await _api.searchDeezerTracks(query);
      final tracks = response.data;
      
      if (tracks.isEmpty) {
        final fallbackQuery = randomQueries[(random + 1) % randomQueries.length];
        final fallbackResponse = await _api.searchDeezerTracks(fallbackQuery);
        return fallbackResponse.data.take(count).toList();
      }
      
      tracks.shuffle();
      return tracks.take(count).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addRandomTrackToPlaylist(String playlistId, String token) async {
    final randomTracks = await getRandomTracks(count: 1);
    if (randomTracks.isNotEmpty) {
      await addTrackToPlaylist(playlistId, randomTracks.first.backendId, token);
    }
  }
}

extension PlaylistTrackSorting on List<PlaylistTrack> {

  List<PlaylistTrack> sortedCopy(TrackSortOption sortOption) {
    return TrackSortingService.sortTracks(this, sortOption);
  }

}
