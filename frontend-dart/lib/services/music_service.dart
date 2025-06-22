// lib/services/music_service.dart
import '../services/api_service.dart';
import '../models/models.dart';
import '../models/api_models.dart';

class MusicService {
  final ApiService _api;

  MusicService(this._api);

  Future<List<PlaylistTrack>> getPlaylistTracksWithDetails(String playlistId, String token) async {
    try {
      print('Fetching playlist tracks for playlist $playlistId');
      
      final response = await _api.getPlaylistTracks(playlistId, 'Token $token');
      
      print('Loaded ${response.tracks.length} tracks with full details');
      return response.tracks;
      
    } catch (e) {
      print('Error fetching playlist tracks: $e');
      rethrow;
    }
  }

  Future<Track?> getTrackWithDetails(String trackId, String token) async {
    try {
      if (trackId.startsWith('deezer_')) {
        final deezerTrackId = trackId.substring(7);
        return await getDeezerTrack(deezerTrackId);
      }
      
      print('Track ID $trackId not found in current context');
      return null;
    } catch (e) {
      print('Failed to get track details for $trackId: $e');
      return null;
    }
  }

  Future<List<Playlist>> getUserPlaylists(String token) async {
    final response = await _api.getSavedPlaylists('Token $token');
    return response.playlists;
  }

  Future<List<Playlist>> getPublicPlaylists(String token) async {
    final response = await _api.getPublicPlaylists('Token $token');
    return response.playlists;
  }

  Future<Playlist> getPlaylistDetails(String id, String token) async {
    final response = await _api.getPlaylist(id, 'Token $token');
    return response.playlist;
  }

  Future<String> createPlaylist(String name, String description, bool isPublic, String token, [String? deviceUuid]) async {
    final request = CreatePlaylistRequest(name: name, description: description, public: isPublic, deviceUuid: deviceUuid);
    final response = await _api.createPlaylist('Token $token', request);
    return response.playlistId;
  }

  Future<void> updatePlaylist(String id, String token, {String? name, String? description, bool? isPublic}) async {
    final request = UpdatePlaylistRequest(
      name: name,
      description: description,
      public: isPublic,
    );
    await _api.updatePlaylist(id, 'Token $token', request);
  }

  Future<List<Track>> searchDeezerTracks(String query) async {
    final response = await _api.searchDeezerTracks(query);
    return response.data;
  }

  Future<Track?> getDeezerTrack(String trackId) async {
    try {
      return await _api.getDeezerTrack(trackId);
    } catch (e) {
      print('Failed to get Deezer track $trackId: $e');
      return null;
    }
  }

  Future<void> addTrackFromDeezer(String deezerTrackId, String token) async {
    final request = AddDeezerTrackRequest(deezerTrackId: deezerTrackId);
    await _api.addTrackFromDeezer('Token $token', request);
  }

  Future<List<PlaylistTrack>> getPlaylistTracks(String playlistId, String token) async {
    final response = await _api.getPlaylistTracks(playlistId, 'Token $token');
    return response.tracks;
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId, String token) async {
    final request = AddTrackRequest(trackId: trackId);
    await _api.addTrackToPlaylist(playlistId, 'Token $token', request);
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId, String token) async {
    await _api.removeTrackFromPlaylist(playlistId, trackId, 'Token $token');
  }

  Future<void> moveTrackInPlaylist({
    required String playlistId,
    required int rangeStart,
    required int insertBefore,
    int rangeLength = 1,
    required String token,
  }) async {
    final request = MoveTrackRequest(rangeStart: rangeStart, insertBefore: insertBefore, rangeLength: rangeLength);
    await _api.moveTrackInPlaylist(playlistId, 'Token $token', request);
  }

  Future<void> changePlaylistVisibility(String playlistId, bool isPublic, String token) async {
    final request = VisibilityRequest(public: isPublic);
    await _api.changePlaylistVisibility(playlistId, 'Token $token', request);
  }

  Future<void> inviteUserToPlaylist(String playlistId, int userId, String token) async {
    final request = InviteUserRequest(userId: userId);
    await _api.inviteUserToPlaylist(playlistId, 'Token $token', request);
  }
}
