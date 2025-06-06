// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/models.dart';
import '../core/app_core.dart';

class WebSocketService with ChangeNotifier {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  String? _currentPlaylistId;
  bool _isConnected = false;
  
  final StreamController<List<PlaylistTrack>> _playlistTracksController = 
      StreamController<List<PlaylistTrack>>.broadcast();
  final StreamController<String> _connectionStatusController = 
      StreamController<String>.broadcast();

  bool get isConnected => _isConnected;
  Stream<List<PlaylistTrack>> get playlistTracksStream => _playlistTracksController.stream;
  Stream<String> get connectionStatusStream => _connectionStatusController.stream;
  String? get currentPlaylistId => _currentPlaylistId;

  String get _baseWebSocketUrl {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? AppConstants.defaultApiBaseUrl;
    return baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
  }

  Future<void> connectToPlaylist(String playlistId) async {
    try {
      if (_isConnected && _currentPlaylistId != playlistId) await disconnect();
      if (_isConnected && _currentPlaylistId == playlistId) return;

      _currentPlaylistId = playlistId;
      _channel = WebSocketChannel.connect(
        Uri.parse('$_baseWebSocketUrl/ws/playlists/$playlistId/')
      );
      
      await _channel!.ready;
      _isConnected = true;
      _connectionStatusController.add('Connected to playlist $playlistId');
      notifyListeners();

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection
      );
    } catch (e) {
      _isConnected = false;
      _connectionStatusController.add('Connection failed: $e');
      notifyListeners();
      rethrow;
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      if (data['type'] == 'playlist_update') {
        final tracksData = data['data'] as List<dynamic>;
        final tracks = tracksData.map((trackData) {
          final track = Track.fromJson(trackData['track']);
          return PlaylistTrack(
            trackId: track.id,
            name: track.name,
            position: trackData['position'] ?? 0,
            track: track,
          );
        }).toList();
        
        _playlistTracksController.add(tracks);
        notifyListeners();
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  void _handleError(error) {
    _isConnected = false;
    _connectionStatusController.add('Connection error: $error');
    notifyListeners();
  }

  void _handleDisconnection() {
    _isConnected = false;
    _currentPlaylistId = null;
    _connectionStatusController.add('Disconnected');
    notifyListeners();
  }

  Future<void> disconnect() async {
    try {
      if (_channel != null) {
        await _channel!.sink.close();
        _channel = null;
      }
      _isConnected = false;
      _currentPlaylistId = null;
      notifyListeners();
    } catch (e) {
      print('Error disconnecting WebSocket: $e');
    }
  }

  @override
  void dispose() {
    disconnect();
    _playlistTracksController.close();
    _connectionStatusController.close();
    super.dispose();
  }
}
