import 'package:collection/collection.dart';
import '../services/api_services.dart';
import '../models/music_models.dart';
import '../models/api_models.dart';
import '../models/sort_models.dart';

class TrackSortingService {
  static List<PlaylistTrack> sortTracks(List<PlaylistTrack> tracks, TrackSortOption sortOption) {
    return tracks.sorted((a, b) {
      final comparison = _getComparison(a, b, sortOption.field);
      return sortOption.order == SortOrder.ascending ? comparison : -comparison;
    });
  }

  static List<Track> sortTrackList(List<Track> tracks, TrackSortOption sortOption) {
    final playlistTracks = tracks.asMap().entries.map((entry) => PlaylistTrack(
      trackId: entry.value.id, name: entry.value.name, position: entry.key, points: 0, track: entry.value,
    )).toList();
    return sortTracks(playlistTracks, sortOption).map((pt) => pt.track!).toList();
  }

  static int _getComparison(PlaylistTrack a, PlaylistTrack b, TrackSortField field) {
    switch (field) {
      case TrackSortField.position: case TrackSortField.dateAdded: return a.position.compareTo(b.position);
      case TrackSortField.name: return compareAsciiLowerCase(a.track?.name ?? a.name, b.track?.name ?? b.name);
      case TrackSortField.artist: return compareAsciiLowerCase(a.track?.artist ?? '', b.track?.artist ?? '');
      case TrackSortField.album: return compareAsciiLowerCase(a.track?.album ?? '', b.track?.album ?? '');
      case TrackSortField.points: return a.points.compareTo(b.points);
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

  Future<List<Playlist>> getUserPlaylists(String token) async => (await _api.getSavedPlaylists(token)).playlists;

  Future<List<Playlist>> getPublicPlaylists(String token) async => (await _api.getPublicPlaylists(token)).playlists;

  Future<Playlist> getPlaylistDetails(String id, String token) async => (await _api.getPlaylist(id, token)).playlist;

  Future<String> createPlaylist(String name, String description, bool isPublic, String token, String licenseType, bool isEvent, [String? deviceUuid]) async {
    final request = CreatePlaylistRequest(name: name, description: description, public: isPublic, licenseType: licenseType, event: isEvent, deviceUuid: deviceUuid);
    final response = await _api.createPlaylist(token, request); 
    return response.playlistId;
  }

  Future<List<Track>> searchDeezerTracks(String query) async => (await _api.searchDeezerTracks(query)).data;

  Future<List<Track>> searchTracks(String query, String token) async => (await _api.searchTracks(query, token)).data;

  Future<Track?> getDeezerTrack(String trackId, String token) async => await _api.getDeezerTrack(trackId, token);

  Future<List<PlaylistTrack>> getPlaylistTracksWithDetails(String playlistId, String token) async => (await _api.getPlaylistTracks(playlistId, token)).tracks;

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
    final randomQueries = ['pop', 'rock', 'jazz', 'electronic', 'hip hop', 'classical', 'indie', 'dance', 'blues', 'reggae', 'folk', 'country', 'metal', 'punk', 'soul', 'funk', 'disco', 'house', 'techno', 'ambient', 'a', 'e', 'i', 'o', 'u', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'love', 'life', 'time', 'night', 'day', 'home', 'heart', 'world', 'dream', 'fire', 'water'];
    
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

  Future<void> deletePlaylist(String playlistId, String token) async => await _api.deletePlaylist(playlistId, token);

  Future<List<Playlist>> getSavedEvents(String token) async => (await _api.getSavedEvents(token)).playlists;

  Future<List<Playlist>> getPublicEvents(String token) async => (await _api.getPublicEvents(token)).playlists;

  Future<List<Track>> getRandomTracksFromAPI({int count = 10}) async {
    try {
      final tracksData = await _api.getRandomTracks(count: count);
      return tracksData.map((trackData) => Track.fromJson(trackData)).toList();
    } catch (e) {
      return getRandomTracks(count: count);
    }
  }

}
