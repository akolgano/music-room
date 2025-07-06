// lib/providers/websocket_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../core/base_provider.dart';
import '../core/service_locator.dart';
import '../services/websocket_service.dart';
import '../models/models.dart';

class WebSocketProvider extends BaseProvider {
  final WebSocketService _webSocketService = getIt<WebSocketService>();
  
  String? _currentPlaylistId;
  bool _isConnected = false;
  StreamSubscription<PlaylistUpdateEvent>? _updateSubscription;
  final StreamController<PlaylistUpdateEvent> _eventController = 
      StreamController<PlaylistUpdateEvent>.broadcast();

  String? get currentPlaylistId => _currentPlaylistId;
  bool get isConnected => _isConnected;
  Stream<PlaylistUpdateEvent> get playlistUpdates => _eventController.stream;

  String get connectionStatus {
    return _isConnected ? 'Connected' : 'Disconnected';
  }

  Future<bool> connectToPlaylist(String playlistId, String authToken) async {
    return await executeBool(
      () async {
        print('WebSocketProvider: Connecting to playlist $playlistId');
        _currentPlaylistId = playlistId;
        
        await _webSocketService.connectToPlaylist(playlistId, authToken);
        _setupEventListening();
        
        _isConnected = _webSocketService.isConnected;
        print('WebSocketProvider: Successfully connected to playlist $playlistId');
      },
      successMessage: 'Connected to real-time updates',
      errorMessage: 'Failed to connect to real-time updates',
    );
  }

  Future<void> disconnect() async {
    await executeAsync(
      () async {
        print('WebSocketProvider: Disconnecting...');
        await _updateSubscription?.cancel();
        _updateSubscription = null;
        await _webSocketService.disconnect();
        _isConnected = false;
        _currentPlaylistId = null;
        print('WebSocketProvider: Disconnected successfully');
      },
      errorMessage: 'Error during disconnect',
    );
  }

  void sendMessage(Map<String, dynamic> message) {
    try {
      _webSocketService.sendMessage(message);
      print('WebSocketProvider: Message sent - ${message['type']}');
    } catch (e) {
      print('WebSocketProvider: Failed to send message - $e');
      setError('Failed to send message: $e');
    }
  }

  void _setupEventListening() {
    _updateSubscription?.cancel();
    _updateSubscription = _webSocketService.playlistUpdates.listen(
      (event) {
        _eventController.add(event);
        notifyListeners();
        print('WebSocketProvider: Received event - ${event.type}');
      },
      onError: (error) {
        print('WebSocketProvider: WebSocket error - $error');
        setError('WebSocket error: $error');
        _isConnected = false;
        notifyListeners();
      },
    );
  }

  bool isConnectedToPlaylist(String playlistId) {
    return _isConnected && _currentPlaylistId == playlistId;
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    _eventController.close();
    disconnect();
    super.dispose();
  }
}
