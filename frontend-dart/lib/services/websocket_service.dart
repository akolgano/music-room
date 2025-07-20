import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _streamController;
  String? _currentPlaylistId;
  String? _currentToken;
  
  Stream<Map<String, dynamic>> get stream => _streamController?.stream ?? const Stream.empty();
  
  bool get isConnected => _channel != null && _streamController != null && !_streamController!.isClosed;

  Future<void> connectToPlaylist(String playlistId, String token) async {
    if (_currentPlaylistId == playlistId && isConnected) {
      if (kDebugMode) {
        debugPrint('[WebSocketService] Already connected to playlist $playlistId');
      }
      return;
    }

    await disconnect();

    try {
      String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
      
      String wsUrl = baseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');
      
      if (wsUrl.endsWith('/')) {
        wsUrl = wsUrl.substring(0, wsUrl.length - 1);
      }
      
      final uri = Uri.parse('$wsUrl/ws/playlists/$playlistId/');
      
      if (kDebugMode) {
        debugPrint('[WebSocketService] Connecting to: $uri');
      }

      _channel = WebSocketChannel.connect(
        uri,
        protocols: ['Authorization', 'Token $token'],
      );

      _streamController = StreamController<Map<String, dynamic>>.broadcast();
      _currentPlaylistId = playlistId;
      _currentToken = token;

      _channel!.stream.listen(
        (dynamic message) {
          if (kDebugMode) {
            debugPrint('[WebSocketService] Received message: $message');
          }
          
          try {
            final data = jsonDecode(message as String) as Map<String, dynamic>;
            _streamController?.add(data);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('[WebSocketService] Error parsing message: $e');
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            debugPrint('[WebSocketService] WebSocket error: $error');
          }
          _handleConnectionError();
        },
        onDone: () {
          if (kDebugMode) {
            debugPrint('[WebSocketService] WebSocket connection closed');
          }
          _handleConnectionClosed();
        },
      );

      if (kDebugMode) {
        debugPrint('[WebSocketService] Successfully connected to playlist $playlistId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WebSocketService] Failed to connect: $e');
      }
      _handleConnectionError();
    }
  }

  void _handleConnectionError() {
    if (!_streamController!.isClosed) {
      _streamController?.addError('WebSocket connection error');
    }
    _cleanup();
  }

  void _handleConnectionClosed() {
    _cleanup();
  }

  void _cleanup() {
    _channel?.sink.close();
    _channel = null;
    _streamController?.close();
    _streamController = null;
    _currentPlaylistId = null;
    _currentToken = null;
  }

  Future<void> disconnect() async {
    if (kDebugMode && _currentPlaylistId != null) {
      debugPrint('[WebSocketService] Disconnecting from playlist $_currentPlaylistId');
    }
    
    _cleanup();
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null && isConnected) {
      try {
        _channel!.sink.add(jsonEncode(message));
        if (kDebugMode) {
          debugPrint('[WebSocketService] Sent message: $message');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[WebSocketService] Error sending message: $e');
        }
      }
    } else {
      if (kDebugMode) {
        debugPrint('[WebSocketService] Cannot send message: not connected');
      }
    }
  }

  void dispose() {
    disconnect();
  }
}