// lib/services/music_service.dart
import '../services/api_service.dart';
import '../models/models.dart';
import '../models/api_models.dart';

class MusicService {
  final ApiService _api;

  MusicService(this._api);

  Future<String> getInternalTrackId(String deezerTrackId, String token) async {
    try {
      final response = await _api.searchTracksByDeezerId(deezerTrackId, token);
      final tracks = response['tracks'] as List<dynamic>?;
      if (tracks?.isNotEmpty == true) {
        return tracks!.first['id'].toString();
      }
      return deezerTrackId;
    } catch (e) {
      print('Track search failed for $deezerTrackId: $e');
      return deezerTrackId;
    }
  }

  Future<List<PlaylistTrack>> getPlaylistTracksWithDetails(String playlistId, String token) async {
    try {
      print('Fetching playlist tracks with full details for playlist $playlistId');
      
      final basicResponse = await _api.getPlaylistTracks(playlistId, 'Token $token');
      final basicTracks = basicResponse.tracks;
      
      if (basicTracks.isEmpty) return basicTracks;
      
      print('Found ${basicTracks.length} tracks, fetching detailed information...');
      
      final enhancedTracks = <PlaylistTrack>[];
      
      for (int i = 0; i < basicTracks.length; i++) {
        final playlistTrack = basicTracks[i];
        
        try {
          Track? fullTrack = await _api.getTrackByAnyId(playlistTrack.trackId, 'Token $token');
          
          enhancedTracks.add(PlaylistTrack(
            trackId: playlistTrack.trackId,
            name: playlistTrack.name,
            position: playlistTrack.position,
            track: fullTrack,
          ));
          
          print('Enhanced track ${i + 1}/${basicTracks.length}: ${playlistTrack.name} ${fullTrack?.deezerTrackId != null ? '✓' : '✗'}');
        } catch (e) {
          print('Failed to enhance track ${playlistTrack.name}: $e');
          enhancedTracks.add(playlistTrack);
        }
        
        if (i < basicTracks.length - 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      
      print('Enhanced ${enhancedTracks.length} tracks successfully');
      return enhancedTracks;
      
    } catch (e) {
      print('Error fetching playlist tracks with details: $e');
      final basicResponse = await _api.getPlaylistTracks(playlistId, 'Token $token');
      return basicResponse.tracks;
    }
  }

  Future<Track?> getTrackWithDetails(String trackId, String token) async {
    try {
      return await _api.getTrackByAnyId(trackId, 'Token $token');
    } catch (e) {
      print('Failed to get track details for $trackId: $e');
      return null;
    }
  }

  Future<List<PlaylistTrack>> enhancePlaylistTracks(List<PlaylistTrack> tracks, String token) async {
    final enhancedTracks = <PlaylistTrack>[];
    
    for (final track in tracks) {
      if (track.track?.deezerTrackId != null) {
        enhancedTracks.add(track);
      } else {
        try {
          final fullTrack = await getTrackWithDetails(track.trackId, token);
          enhancedTracks.add(PlaylistTrack(
            trackId: track.trackId, 
            name: track.name, 
            position: track.position, 
            track: fullTrack
          ));
        } catch (e) {
          print('Failed to enhance track ${track.name}: $e');
          enhancedTracks.add(track);
        }
      }
    }
    
    return enhancedTracks;
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

  Future<void> addTrackFromDeezerToTracks(String trackId, String token) async {
    try {
      await _api.addTrackFromDeezerToTracks(trackId, 'Token $token');
    } catch (e) {
      print('Failed to add track to tracks database (endpoint might not exist): $e');
    }
  }
}
