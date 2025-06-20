// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/collaboration_models.dart';

class WebSocketService with ChangeNotifier {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  String? _currentPlaylistId;
  String? _currentUserId;
  bool _isConnected = false;
  
  final StreamController<PlaylistOperation> _operationsController = 
      StreamController<PlaylistOperation>.broadcast();
  final StreamController<List<PlaylistCollaborator>> _collaboratorsController = 
      StreamController<List<PlaylistCollaborator>>.broadcast();
  final StreamController<String> _notificationsController = 
      StreamController<String>.broadcast();

  bool get isConnected => _isConnected;
  String? get currentPlaylistId => _currentPlaylistId;
  Stream<PlaylistOperation> get operationsStream => _operationsController.stream;
  Stream<List<PlaylistCollaborator>> get collaboratorsStream => _collaboratorsController.stream;
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
        case 'playlist_operation':
          final operation = PlaylistOperation.fromJson(data['operation']);
          _operationsController.add(operation);
          break;
          
        case 'collaborators_update':
          final collaboratorsData = data['collaborators'] as List<dynamic>;
          final collaborators = collaboratorsData
              .map((c) => PlaylistCollaborator.fromJson(c))
              .toList();
          _collaboratorsController.add(collaborators);
          break;
          
        case 'conflict_detected':
          _notificationsController.add(data['message']);
          break;
          
        case 'user_joined':
          _notificationsController.add('${data['username']} joined the playlist');
          break;
          
        case 'user_left':
          _notificationsController.add('${data['username']} left the playlist');
          break;
          
        case 'permission_changed':
          _notificationsController.add(
            '${data['username']} permissions updated by ${data['changed_by']}'
          );
          break;
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  void sendOperation(PlaylistOperation operation) {
    if (_isConnected && _channel != null) {
      _sendMessage({
        'type': 'playlist_operation',
        'operation': operation.toJson(),
      });
    }
  }

  void sendTrackMove(String trackId, int oldIndex, int newIndex, String username) {
    final operation = PlaylistOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _currentUserId!,
      username: username,
      type: ConflictType.trackMove,
      data: {
        'track_id': trackId,
        'old_index': oldIndex,
        'new_index': newIndex,
      },
      timestamp: DateTime.now(),
      version: 1,
    );
    
    sendOperation(operation);
  }

  void sendTrackAdd(String trackId, int position, String username) {
    final operation = PlaylistOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _currentUserId!,
      username: username,
      type: ConflictType.trackAdd,
      data: {
        'track_id': trackId,
        'position': position,
      },
      timestamp: DateTime.now(),
      version: 1,
    );
    
    sendOperation(operation);
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
    _notificationsController.add('Connection error: $error');
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
          _sendMessage({'type': 'user_left', 'user_id': _currentUserId, 'timestamp': DateTime.now().toIso8601String()});
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
    _operationsController.close();
    _collaboratorsController.close();
    _notificationsController.close();
    super.dispose();
  }
}
