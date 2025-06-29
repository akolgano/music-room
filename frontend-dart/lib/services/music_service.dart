// lib/services/music_service.dart
import '../services/api_service.dart';
import '../models/models.dart';
import '../models/api_models.dart';

class MusicService {
  final ApiService _api;
  
  MusicService(this._api);

  Future<List<Playlist>> getUserPlaylists(String token) async {
    final response = await _api.getSavedPlaylists(token); 
    return response.playlists;
  }

  Future<List<Playlist>> getPublicPlaylists(String token) async {
    final response = await _api.getPublicPlaylists(token); 
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

  Future<Track?> getDeezerTrack(String trackId, String token) async {
    try {
      return await _api.getDeezerTrack(trackId, token); 
    } catch (e) {
      print('Failed to get Deezer track $trackId: $e');
      return null;
    }
  }

  Future<void> addTrackFromDeezer(String deezerTrackId, String token) async {
    await _api.addTrackFromDeezer(int.parse(deezerTrackId), token);
  }

  Future<List<PlaylistTrack>> getPlaylistTracksWithDetails(String playlistId, String token) async {
    try {
      final response = await _api.getPlaylistTracks(playlistId, token); 
      print('Loaded ${response.tracks.length} tracks with full details');
      return response.tracks;
    } catch (e) {
      print('Error fetching playlist tracks: $e');
      rethrow;
    }
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId, String token) async {
    print('Adding track to playlist: backendId=$trackId');
    final request = AddTrackRequest(trackId: trackId);
    await _api.addTrackToPlaylist(playlistId, token, request); 
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackId, String token) async {
    await _api.removeTrackFromPlaylist(playlistId, trackId, token); 
  }

  Future<void> moveTrackInPlaylist({
    required String playlistId, 
    required int rangeStart,
    required int insertBefore,
    int rangeLength = 1,
    required String token,
  }) async {
    final request = MoveTrackRequest(rangeStart: rangeStart, insertBefore: insertBefore, rangeLength: rangeLength);
    await _api.moveTrackInPlaylist(playlistId, token, request); 
  }

  Future<void> inviteUserToPlaylist(String playlistId, int userId, String token) async {
    final request = InviteUserRequest(userId: userId);
    await _api.inviteUserToPlaylist(playlistId, token, request); 
  }
}
