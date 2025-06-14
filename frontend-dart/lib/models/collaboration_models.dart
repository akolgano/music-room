// lib/models/collaboration_models.dart
enum ConflictType { trackMove, trackAdd, trackRemove, trackUpdate }

enum PlaylistPermission { read, edit, share, delete }

class PlaylistOperation {
  final String id;
  final String userId;
  final String username;
  final ConflictType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int version;

  PlaylistOperation({
    required this.id,
    required this.userId,
    required this.username,
    required this.type,
    required this.data,
    required this.timestamp,
    required this.version,
  });

  factory PlaylistOperation.fromJson(Map<String, dynamic> json) => PlaylistOperation(
    id: json['id'].toString(),
    userId: json['user_id'].toString(),
    username: json['username'] ?? 'User',
    type: ConflictType.values.firstWhere((t) => t.name == json['type'], orElse: () => ConflictType.trackUpdate),
    data: json['data'] ?? {},
    timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    version: json['version'] ?? 1,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'username': username,
    'type': type.name,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'version': version,
  };
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

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'username': username,
    'permissions': permissions.map((p) => p.name).toList(),
    'joined_at': joinedAt.toIso8601String(),
    'is_online': isOnline,
    'last_activity': lastActivity?.toIso8601String(),
  };
}
