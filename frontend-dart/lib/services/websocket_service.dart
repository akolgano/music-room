// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/models.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final StreamController<PlaylistUpdateEvent> _playlistUpdatesController = 
      StreamController<PlaylistUpdateEvent>.broadcast();
  
  String? _currentPlaylistId;
  bool _isConnected = false;
  bool _isConnecting = false; 

  Stream<PlaylistUpdateEvent> get playlistUpdates => _playlistUpdatesController.stream;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting; 
  String? get currentPlaylistId => _currentPlaylistId;

  Future<void> connectToPlaylist(String playlistId, String authToken) async {
    await disconnect();
    
    _currentPlaylistId = playlistId;
    _isConnecting = true; 
    
    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      final wsUrl = baseUrl.replaceFirst('http', 'ws');
      final uri = Uri.parse('$wsUrl/ws/playlists/$playlistId/');
      
      _channel = WebSocketChannel.connect(
        uri,
        protocols: null,
      );
      
      _isConnected = true;
      _isConnecting = false; 
      
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
        cancelOnError: false,
      );

      print('WebSocket connected to playlist $playlistId');
    } catch (e) {
      print('WebSocket connection error: $e');
      _isConnected = false;
      _isConnecting = false; 
      _playlistUpdatesController.addError(
        WebSocketException('Failed to connect: $e')
      );
    }
  }

  void _handleMessage(dynamic message) {
    try {
      if (message is String) {
        final data = jsonDecode(message);
        if (data['type'] == 'playlist_update') {
          final event = PlaylistUpdateEvent.fromJson(data);
          _playlistUpdatesController.add(event);
          print('Playlist update processed');
        }
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
      _playlistUpdatesController.addError(e);
    }
  }

  void _handleError(error) {
    print('WebSocket error: $error');
    _isConnected = false;
    _isConnecting = false; 
    _playlistUpdatesController.addError(error);
  }

  void _handleDisconnection() {
    print('WebSocket disconnected');
    _isConnected = false;
    _isConnecting = false; 
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(message));
        print('Sent WebSocket message: $message');
      } catch (e) {
        print('Error sending WebSocket message: $e');
      }
    } else {
      print('Cannot send message: WebSocket not connected');
    }
  }

  Future<void> disconnect() async {
    print('Disconnecting WebSocket...');
    
    _isConnecting = false; 
    
    if (_subscription != null) {
      await _subscription!.cancel();
      _subscription = null;
    }
    
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
    
    _isConnected = false;
    _currentPlaylistId = null;
  }

  void dispose() {
    disconnect();
    _playlistUpdatesController.close();
  }
}

class PlaylistUpdateEvent {
  final int playlistId;
  final String type;
  final List<PlaylistTrackUpdate> data;

  const PlaylistUpdateEvent({
    required this.playlistId,
    required this.type,
    required this.data,
  });

  factory PlaylistUpdateEvent.fromJson(Map<String, dynamic> json) {
    return PlaylistUpdateEvent(
      playlistId: json['playlist_id'] as int,
      type: json['type'] as String,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => PlaylistTrackUpdate.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class PlaylistTrackUpdate {
  final int id;
  final Track track;
  final int position;
  final int points;

  const PlaylistTrackUpdate({
    required this.id,
    required this.track,
    required this.position,
    required this.points,
  });

  factory PlaylistTrackUpdate.fromJson(Map<String, dynamic> json) {
    return PlaylistTrackUpdate(
      id: json['id'] as int,
      track: Track.fromJson(json['track'] as Map<String, dynamic>),
      position: json['position'] as int,
      points: json['points'] as int,
    );
  }

  PlaylistTrack toPlaylistTrack() {
    return PlaylistTrack(
      trackId: id.toString(),
      name: track.name,
      position: position,
      points: points,
      track: track,
    );
  }
}

class WebSocketException implements Exception {
  final String message;
  const WebSocketException(this.message);
  
  @override
  String toString() => 'WebSocketException: $message';
}
