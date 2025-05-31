// lib/providers/app_provider.dart
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'music_provider.dart';
import 'auth_provider.dart';

class AppProvider with ChangeNotifier {
  final MusicProvider _musicProvider = MusicProvider();
  final AuthProvider _authProvider = AuthProvider();

  List<Playlist> get playlists => _musicProvider.playlists;
  bool get isLoading => _musicProvider.isLoading || _authProvider.isLoading;
  String? get errorMessage => _musicProvider.errorMessage ?? _authProvider.errorMessage;

  Future<void> fetchPlaylists({bool publicOnly = false}) async {
    if (_authProvider.token != null) {
      if (publicOnly) {
        await _musicProvider.fetchPublicPlaylists(_authProvider.token!);
      } else {
        await _musicProvider.fetchUserPlaylists(_authProvider.token!);
      }
    }
  }
}
