// lib/models/license_models.dart
enum LicenseType {
  free,
  premium,
  enterprise,
}

enum PlaylistPermission {
  view,
  edit,
  admin,
  invite,
}

class PlaylistLicense {
  final String id;
  final String playlistId;
  final LicenseType type;
  final List<PlaylistPermission> permissions;
  final bool allowPublicEdit;
  final bool inviteOnlyEdit;
  final DateTime? expiresAt;
  final Map<String, dynamic> restrictions;

  PlaylistLicense({
    required this.id,
    required this.playlistId,
    required this.type,
    required this.permissions,
    this.allowPublicEdit = true,
    this.inviteOnlyEdit = false,
    this.expiresAt,
    this.restrictions = const {},
  });

  factory PlaylistLicense.fromJson(Map<String, dynamic> json) => PlaylistLicense(
    id: json['id'].toString(),
    playlistId: json['playlist_id'].toString(),
    type: LicenseType.values.firstWhere((e) => e.name == json['type']),
    permissions: (json['permissions'] as List)
        .map((p) => PlaylistPermission.values.firstWhere((e) => e.name == p))
        .toList(),
    allowPublicEdit: json['allow_public_edit'] ?? true,
    inviteOnlyEdit: json['invite_only_edit'] ?? false,
    expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    restrictions: json['restrictions'] ?? {},
  );

  bool hasPermission(PlaylistPermission permission) => permissions.contains(permission);
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get canEdit => hasPermission(PlaylistPermission.edit) && !isExpired;
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
    this.isOnline = false,
    this.lastActivity,
  });

  factory PlaylistCollaborator.fromJson(Map<String, dynamic> json) => PlaylistCollaborator(
    userId: json['user_id'].toString(),
    username: json['username'],
    permissions: (json['permissions'] as List)
        .map((p) => PlaylistPermission.values.firstWhere((e) => e.name == p))
        .toList(),
    joinedAt: DateTime.parse(json['joined_at']),
    isOnline: json['is_online'] ?? false,
    lastActivity: json['last_activity'] != null ? DateTime.parse(json['last_activity']) : null,
  );

  bool hasPermission(PlaylistPermission permission) => permissions.contains(permission);
}
