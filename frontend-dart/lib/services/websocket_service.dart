// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WebSocketService with ChangeNotifier {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  String? _currentPlaylistId;
  String? _currentUserId;
  bool _isConnected = false;
  
  final StreamController<String> _notificationsController = 
      StreamController<String>.broadcast();

  bool get isConnected => _isConnected;
  String? get currentPlaylistId => _currentPlaylistId;
  Stream<String> get notificationsStream => _notificationsController.stream;

  String get _baseWebSocketUrl {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    return baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
  }

  Future<void> connectToPlaylist(String playlistId, String userId, String token) async {
    try {
      if (_isConnected && _currentPlaylistId != playlistId) await disconnect();
      if (_isConnected && _currentPlaylistId == playlistId) return;

      _currentPlaylistId = playlistId;
      _currentUserId = userId;
      
      _channel = WebSocketChannel.connect(
        Uri.parse('$_baseWebSocketUrl/ws/playlists/$playlistId/?token=$token')
      );
      
      await _channel!.ready;
      _isConnected = true;
      notifyListeners();

      _sendMessage({
        'type': 'user_joined',
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection
      );

    } catch (e) {
      _isConnected = false;
      notifyListeners();
      rethrow;
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      
      switch (data['type']) {
        case 'playlist_updated':
          _notificationsController.add('Playlist was updated by ${data['username'] ?? 'someone'}');
          break;
        case 'user_joined':
          _notificationsController.add('${data['username'] ?? 'Someone'} joined the playlist');
          break;
        case 'user_left':
          _notificationsController.add('${data['username'] ?? 'Someone'} left the playlist');
          break;
        case 'track_added':
          _notificationsController.add('${data['username'] ?? 'Someone'} added a track');
          break;
        case 'track_removed':
          _notificationsController.add('${data['username'] ?? 'Someone'} removed a track');
          break;
        default:
          _notificationsController.add('Playlist activity detected');
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  void sendPresenceUpdate() {
    if (_isConnected && _channel != null) {
      _sendMessage({
        'type': 'presence_update',
        'user_id': _currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(json.encode(message));
    }
  }

  void _handleError(error) {
    _isConnected = false;
    notifyListeners();
    _notificationsController.add('Connection error occurred');
  }

  void _handleDisconnection() {
    _isConnected = false;
    _currentPlaylistId = null;
    _currentUserId = null;
    notifyListeners();
  }

  Future<void> disconnect() async {
    try {
      if (_channel != null) {
        if (_isConnected && _currentUserId != null) {
          _sendMessage({
            'type': 'user_left', 
            'user_id': _currentUserId, 
            'timestamp': DateTime.now().toIso8601String()
          });
        }
        
        await _channel!.sink.close();
        _channel = null;
      }
      _isConnected = false;
      _currentPlaylistId = null;
      _currentUserId = null;
      notifyListeners();
    } catch (e) {
      print('Error disconnecting WebSocket: $e');
    }
  }

  @override
  void dispose() {
    disconnect();
    _notificationsController.close();
    super.dispose();
  }
}
