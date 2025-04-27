import 'package:flutter/material.dart';
import 'package:music_room/models/playlist.dart';
import 'package:music_room/models/track.dart';
import 'package:music_room/services/api_service.dart';

class MusicServiceProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Playlist> _playlists = [];
  List<Track> _voteTracks = [];
  bool _isLoading = false;
  String? _error;

  List<Playlist> get playlists => _playlists;
  List<Track> get voteTracks => _voteTracks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> createVoteEvent({
    required String name,
    required String description,
    required bool isPublic,
    List<String>? invitedUsers,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = {
        'name': name,
        'description': description,
        'is_public': isPublic,
        'invited_users': invitedUsers ?? [],
      };

      await _apiService.post('/music/vote-events', data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> getVoteEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/music/vote-events');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> voteForTrack(String eventId, String trackId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.post('/music/vote', {
        'event_id': eventId,
        'track_id': trackId,
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createPlaylist({
    required String name,
    required String description,
    required bool isPublic,
    List<String>? invitedUsers,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = {
        'name': name,
        'description': description,
        'is_public': isPublic,
        'invited_users': invitedUsers ?? [],
      };

      await _apiService.post('/music/playlists', data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> getPlaylists() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/music/playlists');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> addTrackToPlaylist(String playlistId, Track track) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.post('/music/playlists/$playlistId/tracks', {
        'track': track.toJson(),
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> reorderPlaylistTracks(String playlistId, int oldIndex, int newIndex) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.put('/music/playlists/$playlistId/reorder', {
        'old_index': oldIndex,
        'new_index': newIndex,
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> delegateControl(String userId, String deviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.post('/music/delegate', {
        'user_id': userId,
        'device_id': deviceId,
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> revokeControl(String userId, String deviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('/music/delegate/$userId/$deviceId');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
