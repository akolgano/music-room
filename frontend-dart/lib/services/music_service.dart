// lib/services/music_service.dart
import '../services/api_service.dart';
import '../models/models.dart';
import '../models/api_models.dart';

class MusicService {
  final ApiService _api;

  MusicService(this._api);

  Future<String> getInternalTrackId(String deezerTrackId, String token) async {
    try {
      final response = await _api.lookupTrackByDeezerId(deezerTrackId, token);
      return response['id'].toString();
    } catch (e) {
      print('Track lookup failed, trying search approach: $e');
      
      try {
        final response = await _api.searchTracksByDeezerId(deezerTrackId, token);
        final tracks = response['tracks'] as List<dynamic>?;
        if (tracks?.isNotEmpty == true) {
          return tracks!.first['id'].toString();
        }
      } catch (e2) {
        print('Track search also failed: $e2');
      }
      
      return deezerTrackId;
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

  Future<Track> getDeezerTrack(String trackId) async {
    return await _api.getDeezerTrack(trackId);
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

  Future<void> addTrackFromDeezerToTracks(String trackId, String token) async {
    await _api.addTrackFromDeezerToTracks(trackId, 'Token $token');
  }
}
