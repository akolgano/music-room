// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/models.dart';
import '../core/constants.dart';

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
      if (_isConnected && _currentPlaylistId != playlistId) {
        await disconnect();
      }

      if (_isConnected && _currentPlaylistId == playlistId) {
        print('Already connected to playlist $playlistId');
        return;
      }

      _currentPlaylistId = playlistId;
      final wsUrl = '$_baseWebSocketUrl/ws/playlists/$playlistId/';
      
      print('Connecting to WebSocket: $wsUrl');
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      await _channel!.ready;
      _isConnected = true;
      
      print('WebSocket connected to playlist $playlistId');
      _connectionStatusController.add('Connected to playlist $playlistId');
      notifyListeners();

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

    } catch (e) {
      print('WebSocket connection error: $e');
      _isConnected = false;
      _connectionStatusController.add('Connection failed: $e');
      notifyListeners();
      rethrow;
    }
  }

  void _handleMessage(dynamic message) {
    try {
      print('WebSocket message received: $message');
      
      final data = json.decode(message);
      final messageType = data['type'];
      final playlistId = data['playlist_id']?.toString();

      switch (messageType) {
        case 'playlist_update':
          _handlePlaylistUpdate(data['data'], playlistId);
          break;
        default:
          print('Unknown WebSocket message type: $messageType');
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  void _handlePlaylistUpdate(dynamic tracksData, String? playlistId) {
    try {
      if (tracksData is List) {
        final tracks = tracksData.map((trackData) {
          return PlaylistTrack(
            trackId: trackData['track']['id'].toString(),
            name: trackData['track']['name'] ?? '',
            position: trackData['position'] ?? 0,
          );
        }).toList();

        print('Received playlist update: ${tracks.length} tracks');
        _playlistTracksController.add(tracks);
      }
    } catch (e) {
      print('Error processing playlist update: $e');
    }
  }

  void _handleError(error) {
    print('WebSocket error: $error');
    _isConnected = false;
    _connectionStatusController.add('Connection error: $error');
    notifyListeners();
  }

  void _handleDisconnection() {
    print('WebSocket disconnected');
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
      print('WebSocket disconnected');
      notifyListeners();
    } catch (e) {
      print('Error disconnecting WebSocket: $e');
    }
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(json.encode(message));
    } else {
      print('Cannot send message: WebSocket not connected');
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
