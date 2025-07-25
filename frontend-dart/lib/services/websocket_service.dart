import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/music_models.dart';

enum PlaylistWebSocketMessageType {
  playlistUpdate('playlist_update');
  
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
  
  PlaylistUpdateMessage({
    required this.playlistId,
    required this.tracks,
  });
  
  factory PlaylistUpdateMessage.fromJson(Map<String, dynamic> json) {
    return PlaylistUpdateMessage(
      playlistId: json['playlist_id'].toString(),
      tracks: (json['data'] as List<dynamic>)
          .map((trackData) => PlaylistTrack.fromJson(trackData))
          .toList(),
    );
  }
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
    if (kDebugMode) {
      debugPrint('[WebSocketService] $message');
    }
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

    await _attemptConnection(playlistId, token);
  }

  Future<void> _attemptConnection(String playlistId, String token) async {
    try {
      String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      
      String wsUrl = baseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');
      
      if (wsUrl.endsWith('/')) {
        wsUrl = wsUrl.substring(0, wsUrl.length - 1);
      }
      
      final uri = Uri.parse('$wsUrl/ws/playlists/$playlistId/');
      
      _log('Connecting to: $uri (attempt ${_reconnectAttempts + 1})');

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
    _log('Received message: $message');
    
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      
      _rawMessageController?.add(data);
      
      final messageType = PlaylistWebSocketMessageType.fromString(data['type']);
      
      switch (messageType) {
        case PlaylistWebSocketMessageType.playlistUpdate:
          try {
            final updateMessage = PlaylistUpdateMessage.fromJson(data);
            _playlistUpdateController?.add(updateMessage);
            _log('Parsed playlist update: ${updateMessage.tracks.length} tracks');
          } catch (e) {
            _log('Error parsing playlist update: $e');
          }
          break;
        case null:
          _log('Unknown message type: ${data['type']}');
          break;
      }
    } catch (e) {
      _log('Error parsing message: $e');
    }
  }

  void _handleConnectionIssue() {
    _cleanup();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts < _maxReconnectAttempts && 
        _currentPlaylistId != null && 
        _currentToken != null) {
      
      _reconnectAttempts++;
      
      _log('Scheduling reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts in ${_reconnectDelay.inSeconds}s');
      
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(_reconnectDelay, () {
        if (_currentPlaylistId != null && _currentToken != null) {
          _attemptConnection(_currentPlaylistId!, _currentToken!);
        }
      });
    } else if (_reconnectAttempts >= _maxReconnectAttempts) {
      _log('Max reconnect attempts reached. Giving up.');
      if (!_playlistUpdateController!.isClosed) {
        _playlistUpdateController?.addError('WebSocket connection failed after $_maxReconnectAttempts attempts');
      }
      if (!_rawMessageController!.isClosed) {
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
    if (_currentPlaylistId != null && _currentToken != null) {
      final playlistId = _currentPlaylistId!;
      final token = _currentToken!;
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

  void dispose() {
    disconnect();
  }
}