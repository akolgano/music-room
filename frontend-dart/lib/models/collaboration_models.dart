// lib/models/collaboration_models.dart
import 'package:flutter/material.dart';

enum ConflictType {trackAdd, trackRemove, trackMove, playlistEdit, permission}

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

  factory PlaylistOperation.fromJson(Map<String, dynamic> json) {
    return PlaylistOperation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      type: ConflictType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ConflictType.playlistEdit,
      ),
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      version: json['version'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'type': type.toString().split('.').last,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'version': version,
    };
  }
}

enum PermissionType {edit, view, comment, share}

class PlaylistPermission {
  final PermissionType type;
  final String name;
  final String description;
  final bool isGranted;

  PlaylistPermission({
    required this.type,
    required this.name,
    required this.description,
    this.isGranted = false,
  });

  factory PlaylistPermission.fromJson(Map<String, dynamic> json) {
    return PlaylistPermission(
      type: PermissionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => PermissionType.view,
      ),
      name: json['name'] as String,
      description: json['description'] as String,
      isGranted: json['is_granted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'name': name,
      'description': description,
      'is_granted': isGranted,
    };
  }
}

class PlaylistCollaborator {
  final String userId;
  final String username;
  final String email;
  final List<PlaylistPermission> permissions;
  final bool isOnline;
  final DateTime? lastSeen;
  final String role;

  PlaylistCollaborator({
    required this.userId,
    required this.username,
    required this.email,
    required this.permissions,
    this.isOnline = false,
    this.lastSeen,
    this.role = 'viewer',
  });

  factory PlaylistCollaborator.fromJson(Map<String, dynamic> json) {
    final permissionsJson = json['permissions'] as List<dynamic>? ?? [];
    final permissions = permissionsJson
        .map((p) => PlaylistPermission.fromJson(p as Map<String, dynamic>))
        .toList();

    return PlaylistCollaborator(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      permissions: permissions,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen'] != null 
          ? DateTime.parse(json['last_seen'] as String)
          : null,
      role: json['role'] as String? ?? 'viewer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'permissions': permissions.map((p) => p.toJson()).toList(),
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
      'role': role,
    };
  }

  bool hasPermission(PermissionType type) {
    return permissions.any((p) => p.type == type && p.isGranted);
  }
}

class ConflictResolution {
  final String operationId;
  final String resolution;
  final String resolvedBy;
  final DateTime resolvedAt;
  final Map<String, dynamic> metadata;

  ConflictResolution({
    required this.operationId,
    required this.resolution,
    required this.resolvedBy,
    required this.resolvedAt,
    this.metadata = const {},
  });

  factory ConflictResolution.fromJson(Map<String, dynamic> json) {
    return ConflictResolution(
      operationId: json['operation_id'] as String,
      resolution: json['resolution'] as String,
      resolvedBy: json['resolved_by'] as String,
      resolvedAt: DateTime.parse(json['resolved_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operation_id': operationId,
      'resolution': resolution,
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}
