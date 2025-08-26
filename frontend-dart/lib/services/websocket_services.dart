import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/music_models.dart';
import '../core/navigation_core.dart';
import '../core/locator_core.dart';
import '../core/theme_core.dart';
import '../providers/music_providers.dart';
import '../providers/voting_providers.dart';
import 'notification_services.dart';

enum PlaylistWebSocketMessageType {
  playlistUpdate('playlist_update'),
  playlistUpdateDot('playlist.update');
  
  const PlaylistWebSocketMessageType(this.value);
  final String value;
  
  static PlaylistWebSocketMessageType? fromString(String? value) {
    for (PlaylistWebSocketMessageType type in PlaylistWebSocketMessageType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return null;
  }
}

class PlaylistUpdateMessage {
  final String playlistId;
  final List<PlaylistTrack> tracks;
  final String? action;
  final String? updateType;
  
  PlaylistUpdateMessage({
    required this.playlistId,
    required this.tracks,
    this.action,
    this.updateType,
  });
  
  factory PlaylistUpdateMessage.fromJson(Map<String, dynamic> json) {
    return PlaylistUpdateMessage(
      playlistId: json['playlist_id'].toString(),
      tracks: (json['data'] as List<dynamic>? ?? json['tracks'] as List<dynamic>? ?? [])
          .map((trackData) => PlaylistTrack.fromJson(trackData))
          .toList(),
      action: json['action'] as String?,
      updateType: json['update_type'] as String?,
    );
  }
  
  bool get isPositionChange => action == 'reorder' || updateType == 'position_change';
  bool get isAddition => action == 'add' || updateType == 'track_added';
  bool get isRemoval => action == 'remove' || updateType == 'track_removed';
}

class _NotificationInfo {
  final String title;
  final String message;
  final Color backgroundColor;
  final IconData icon;

  _NotificationInfo({
    required this.title,
    required this.message,
    required this.backgroundColor,
    required this.icon,
  });
}

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<PlaylistUpdateMessage>? _playlistUpdateController;
  StreamController<Map<String, dynamic>>? _rawMessageController;
  String? _currentPlaylistId;
  String? _currentToken;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  
  void _log(String message) {
    AppLogger.debug(message, 'WebSocketService');
  }
  
  Stream<PlaylistUpdateMessage> get playlistUpdateStream => 
      _playlistUpdateController?.stream ?? const Stream.empty();
  
  Stream<Map<String, dynamic>> get rawMessageStream => 
      _rawMessageController?.stream ?? const Stream.empty();
  
  bool get isConnected => _channel != null && 
      _playlistUpdateController != null && 
      !_playlistUpdateController!.isClosed;

  Future<void> connectToPlaylist(String playlistId, String token) async {
    if (_currentPlaylistId == playlistId && isConnected) {
      _log('Already connected to playlist $playlistId');
      return;
    }

    await disconnect();
    _reconnectAttempts = 0;

    await _attemptConnectionToPlaylist(playlistId, token);
  }

  Future<void> _attemptConnectionToPlaylist(String playlistId, String token) async {
    try {
      String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      
      String wsUrl = baseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');
      
      if (wsUrl.endsWith('/')) {
        wsUrl = wsUrl.substring(0, wsUrl.length - 1);
      }
      
      final uri = Uri.parse('$wsUrl/ws/playlists/$playlistId/?token=$token');
      
      _log('Connecting to: $wsUrl/ws/playlists/$playlistId/?token=[MASKED] (attempt ${_reconnectAttempts + 1})');

      _channel = WebSocketChannel.connect(uri);

      _playlistUpdateController = StreamController<PlaylistUpdateMessage>.broadcast();
      _rawMessageController = StreamController<Map<String, dynamic>>.broadcast();
      _currentPlaylistId = playlistId;
      _currentToken = token;
      _reconnectAttempts = 0;

      _channel!.stream.listen(
        (dynamic message) {
          _handleIncomingMessage(message);
        },
        onError: (error) {
          _log('WebSocket error: $error');
          _handleConnectionIssue();
        },
        onDone: () {
          _log('WebSocket connection closed');
          _handleConnectionIssue();
        },
      );

      _log('Successfully connected to playlist $playlistId');
    } catch (e) {
      _log('Failed to connect: $e');
      _handleConnectionIssue();
    }
  }

  void _handleIncomingMessage(dynamic message) {
    _log('Received WebSocket message');
    
    final data = _parseMessage(message);
    if (data == null) return;
    
    _rawMessageController?.add(data);
    _showNotificationForMessage(data);
    _processMessageByType(data);
  }

  Map<String, dynamic>? _parseMessage(dynamic message) {
    try {
      return jsonDecode(message as String) as Map<String, dynamic>;
    } catch (e) {
      _log('Error parsing message: $e');
      return null;
    }
  }

  void _showNotificationForMessage(Map<String, dynamic> data) {
    if (!getIt.isRegistered<NotificationService>()) return;
    
    final hasVotingData = _hasVotingData(data);
    final notificationInfo = _getNotificationInfo(hasVotingData);
    
    getIt<NotificationService>().showNotification(
      title: notificationInfo.title,
      message: notificationInfo.message,
      backgroundColor: notificationInfo.backgroundColor,
      icon: notificationInfo.icon,
    );
  }

  bool _hasVotingData(Map<String, dynamic> data) {
    return data['data'] != null && 
           data['data'] is List && 
           (data['data'] as List).isNotEmpty;
  }

  _NotificationInfo _getNotificationInfo(bool hasVotingData) {
    return hasVotingData
        ? _NotificationInfo(
            title: 'Playlist Updated',
            message: 'New votes received!',
            backgroundColor: Colors.orange.withValues(alpha: 0.9),
            icon: Icons.how_to_vote,
          )
        : _NotificationInfo(
            title: 'Playlist Activity',
            message: 'Playlist has been updated',
            backgroundColor: AppTheme.primary.withValues(alpha: 0.9),
            icon: Icons.playlist_play,
          );
  }

  void _processMessageByType(Map<String, dynamic> data) {
    final messageType = PlaylistWebSocketMessageType.fromString(data['type']);
    
    switch (messageType) {
      case PlaylistWebSocketMessageType.playlistUpdate:
      case PlaylistWebSocketMessageType.playlistUpdateDot:
        _handlePlaylistUpdate(data);
        break;
      case null:
        _log('Unknown message type: ${data['type']}');
        break;
    }
  }

  void _handlePlaylistUpdate(Map<String, dynamic> data) {
    try {
      _log('Raw WebSocket data received: ${jsonEncode(data)}');
      
      final updateMessage = PlaylistUpdateMessage.fromJson(data);
      _playlistUpdateController?.add(updateMessage);
      
      _log('Parsed playlist update: ${updateMessage.tracks.length} tracks, action: ${updateMessage.action}, updateType: ${updateMessage.updateType}');
      
      if (updateMessage.tracks.isNotEmpty) {
        final firstTrack = updateMessage.tracks.first;
        _log('First track info - ID: ${firstTrack.trackId}, Name: ${firstTrack.name}, Has track object: ${firstTrack.track != null}');
        if (firstTrack.track != null) {
          _log('Track details - DeezerID: ${firstTrack.track!.deezerTrackId}, Image: ${firstTrack.track!.imageUrl != null}, Preview: ${firstTrack.track!.previewUrl != null}');
        }
      }
      
      if (updateMessage.isPositionChange) {
        _log('Position change detected in WebSocket message - triggering full refresh');
      } else if (updateMessage.isAddition) {
        _log('Track addition detected in WebSocket message');
      } else if (updateMessage.isRemoval) {
        _log('Track removal detected in WebSocket message');
      }
      
      _updateProvidersWithPlaylistData(updateMessage);
    } catch (e) {
      _log('Error parsing playlist update: $e');
      _log('Failed data: ${jsonEncode(data)}');
    }
  }

  void _handleConnectionIssue() {
    _cleanup();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts < _maxReconnectAttempts && _currentToken != null) {
      _reconnectAttempts++;
      
      _log('Scheduling reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts in ${_reconnectDelay.inSeconds}s');
      
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(_reconnectDelay, () {
        if (_currentToken != null && _currentPlaylistId != null) {
          _attemptConnectionToPlaylist(_currentPlaylistId!, _currentToken!);
        }
      });
    } else if (_reconnectAttempts >= _maxReconnectAttempts) {
      _log('Max reconnect attempts reached. Giving up.');
      if (_playlistUpdateController != null && !_playlistUpdateController!.isClosed) {
        _playlistUpdateController?.addError('WebSocket connection failed after $_maxReconnectAttempts attempts');
      }
      if (_rawMessageController != null && !_rawMessageController!.isClosed) {
        _rawMessageController?.addError('WebSocket connection failed after $_maxReconnectAttempts attempts');
      }
    }
  }

  void _cleanup() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    _channel?.sink.close();
    _channel = null;
    
    _playlistUpdateController?.close();
    _playlistUpdateController = null;
    
    _rawMessageController?.close();
    _rawMessageController = null;
  }

  Future<void> forceReconnect() async {
    if (_currentToken != null && _currentPlaylistId != null) {
      final token = _currentToken!;
      final playlistId = _currentPlaylistId!;
      await disconnect();
      await connectToPlaylist(playlistId, token);
    }
  }

  Future<void> disconnect() async {
    if (_currentPlaylistId != null) {
      _log('Disconnecting from playlist $_currentPlaylistId');
    }
    
    _currentPlaylistId = null;
    _currentToken = null;
    _reconnectAttempts = 0;
    
    _cleanup();
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null && isConnected) {
      try {
        _channel!.sink.add(jsonEncode(message));
        _log('Sent message: $message');
      } catch (e) {
        _log('Error sending message: $e');
      }
    } else {
      _log('Cannot send message: not connected');
    }
  }

  void _updateProvidersWithPlaylistData(PlaylistUpdateMessage updateMessage) {
    try {
      _log('Updating providers for comprehensive cross-tab sync: ${updateMessage.tracks.length} tracks for playlist ${updateMessage.playlistId}');
      
      if (_currentPlaylistId != updateMessage.playlistId) {
        _log('Ignoring update for playlist ${updateMessage.playlistId} (current: $_currentPlaylistId)');
        return;
      }
      
      if (getIt.isRegistered<MusicProvider>()) {
        final musicProvider = getIt<MusicProvider>();
        
        musicProvider.updatePlaylistTracksWithPreload(updateMessage.tracks);
        
        final trackList = updateMessage.tracks
            .map((pt) => pt.track)
            .where((t) => t != null)
            .cast<Track>()
            .toList();
        
        if (trackList.isNotEmpty) {
          musicProvider.updatePlaylistInCache(updateMessage.playlistId, tracks: trackList);
        }
        
        _log('Comprehensively updated MusicProvider with ${updateMessage.tracks.length} playlist tracks including preload and cache');
      }
      
      if (getIt.isRegistered<VotingProvider>()) {
        final votingProvider = getIt<VotingProvider>();
        votingProvider.refreshVotingData(updateMessage.tracks);
        _log('Updated VotingProvider with new track points for ${updateMessage.tracks.length} tracks');
      }
      
    } catch (e) {
      _log('Error updating providers with playlist data: $e');
    }
  }

  void dispose() {
    disconnect();
  }
}
