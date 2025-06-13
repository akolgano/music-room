// lib/providers/playlist_license_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'base_provider.dart';

enum PlaylistPermission { read, edit, share, delete }

class PlaylistLicense {
  final String id;
  final String playlistId;
  final String type;
  final List<PlaylistPermission> permissions;
  final bool allowPublicEdit;
  final bool inviteOnlyEdit;
  final DateTime? expiresAt;
  final Map<String, dynamic> restrictions;
  final bool canEdit;

  PlaylistLicense({
    required this.id,
    required this.playlistId,
    required this.type,
    required this.permissions,
    required this.allowPublicEdit,
    required this.inviteOnlyEdit,
    this.expiresAt,
    required this.restrictions,
    this.canEdit = true,
  });

  factory PlaylistLicense.fromJson(Map<String, dynamic> json) => PlaylistLicense(
    id: json['id'].toString(),
    playlistId: json['playlist_id'].toString(),
    type: json['type'] ?? 'basic',
    permissions: (json['permissions'] as List?)?.map((p) => PlaylistPermission.values.firstWhere((perm) => perm.name == p)).toList() ?? [],
    allowPublicEdit: json['allow_public_edit'] ?? false,
    inviteOnlyEdit: json['invite_only_edit'] ?? false,
    expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    restrictions: json['restrictions'] ?? {},
    canEdit: json['can_edit'] ?? true,
  );
}

class PlaylistCollaborator {
  final String userId;
  final String username;
  final List<PlaylistPermission> permissions;
  final DateTime joinedAt;
  final bool isOnline;
  final DateTime? lastActivity;

  PlaylistCollaborator({
    required this.userId,
    required this.username,
    required this.permissions,
    required this.joinedAt,
    required this.isOnline,
    this.lastActivity,
  });

  factory PlaylistCollaborator.fromJson(Map<String, dynamic> json) => PlaylistCollaborator(
    userId: json['user_id'].toString(),
    username: json['username'] ?? 'User',
    permissions: (json['permissions'] as List?)?.map((p) => PlaylistPermission.values.firstWhere((perm) => perm.name == p)).toList() ?? [],
    joinedAt: DateTime.parse(json['joined_at'] ?? DateTime.now().toIso8601String()),
    isOnline: json['is_online'] ?? false,
    lastActivity: json['last_activity'] != null ? DateTime.parse(json['last_activity']) : null,
  );

  bool hasPermission(PlaylistPermission permission) => permissions.contains(permission);
}

class PlaylistLicenseProvider extends ChangeNotifier with StateManagement {
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
