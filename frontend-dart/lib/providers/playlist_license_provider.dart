// lib/providers/playlist_license_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/license_models.dart';
import 'base_provider.dart';

class PlaylistLicenseProvider with ChangeNotifier, BaseProvider {
  final ApiService _api = ApiService();
  
  PlaylistLicense? _currentLicense;
  List<PlaylistCollaborator> _collaborators = [];
  Map<String, bool> _userPermissions = {};

  PlaylistLicense? get currentLicense => _currentLicense;
  List<PlaylistCollaborator> get collaborators => List.unmodifiable(_collaborators);
  
  bool canUserEdit(String userId) => _userPermissions[userId] ?? false;
  bool get canCurrentUserEdit => _currentLicense?.canEdit ?? false;

  Future<void> loadPlaylistLicense(String playlistId, String token) async {
    await execute(() async {
      final response = await _api.get('/playlists/$playlistId/license/', token);
      _currentLicense = PlaylistLicense.fromJson(response['license']);
      
      final collaboratorsData = response['collaborators'] as List<dynamic>;
      _collaborators = collaboratorsData
          .map((c) => PlaylistCollaborator.fromJson(c))
          .toList();
      
      _userPermissions.clear();
      for (final collaborator in _collaborators) {
        _userPermissions[collaborator.userId] = collaborator.hasPermission(PlaylistPermission.edit);
      }
    });
  }

  Future<bool> updateLicensePermissions(String playlistId, String userId, 
      List<PlaylistPermission> permissions, String token) async {
    return await execute(() async {
      await _api.post('/playlists/$playlistId/permissions/', {
        'user_id': userId,
        'permissions': permissions.map((p) => p.name).toList(),
      }, token);
      
      await loadPlaylistLicense(playlistId, token);
      return true;
    }) ?? false;
  }

  Future<bool> setInviteOnlyMode(String playlistId, bool inviteOnly, String token) async {
    return await execute(() async {
      await _api.post('/playlists/$playlistId/license/update/', {
        'invite_only_edit': inviteOnly,
      }, token);
      
      if (_currentLicense != null) {
        _currentLicense = PlaylistLicense(
          id: _currentLicense!.id,
          playlistId: _currentLicense!.playlistId,
          type: _currentLicense!.type,
          permissions: _currentLicense!.permissions,
          allowPublicEdit: _currentLicense!.allowPublicEdit,
          inviteOnlyEdit: inviteOnly,
          expiresAt: _currentLicense!.expiresAt,
          restrictions: _currentLicense!.restrictions,
        );
      }
      return true;
    }) ?? false;
  }

  void updateCollaboratorStatus(String userId, bool isOnline) {
    final index = _collaborators.indexWhere((c) => c.userId == userId);
    if (index != -1) {
      final collaborator = _collaborators[index];
      _collaborators[index] = PlaylistCollaborator(
        userId: collaborator.userId,
        username: collaborator.username,
        permissions: collaborator.permissions,
        joinedAt: collaborator.joinedAt,
        isOnline: isOnline,
        lastActivity: isOnline ? DateTime.now() : collaborator.lastActivity,
      );
      notifyListeners();
    }
  }
}
