// lib/models/models.dart
class User {
  final String id;
  final String username;
  final String? email;
  
  User({required this.id, required this.username, this.email});
  
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'].toString(),
    username: json['username'],
    email: json['email'],
  );
}

class Track {
  final String id;
  final String name;
  final String artist;
  final String album;
  final String url;
  final String? deezerTrackId;
  final String? previewUrl;
  final String? imageUrl;
  
  const Track({
    required this.id,
    required this.name,
    required this.artist,
    required this.album,
    required this.url,
    this.deezerTrackId,
    this.previewUrl,
    this.imageUrl,
  });
  
  factory Track.fromJson(Map<String, dynamic> json) => Track(
    id: json['id'].toString(),
    name: json['name'] ?? json['title'] ?? '',
    artist: json['artist'] is String 
      ? json['artist'] 
      : json['artist']?['name'] ?? '',
    album: json['album'] is String 
      ? json['album'] 
      : json['album']?['title'] ?? '',
    url: json['url'] ?? json['link'] ?? '',
    deezerTrackId: json['deezer_track_id']?.toString(),
    previewUrl: json['preview_url'] ?? json['preview'],
    imageUrl: json['image_url'] ?? 
              json['album']?['cover_medium'] ?? 
              json['album']?['cover'],
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Playlist {
  final String id;
  final String name;
  final String description;
  final bool isPublic;
  final String creator;
  final List<Track> tracks;
  final String? imageUrl;
  
  Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.isPublic,
    required this.creator,
    required this.tracks,
    this.imageUrl,
  });
  
  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
    id: json['id'].toString(),
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    isPublic: json['public'] ?? false,
    creator: json['creator'] ?? '',
    tracks: (json['tracks'] as List?)
        ?.map((track) => Track.fromJson(track))
        .toList() ?? [],
    imageUrl: json['image_url'],
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class PlaylistTrack {
  final String trackId;
  final String name;
  final int position;
  final Track? track; 
  
  PlaylistTrack({
    required this.trackId,
    required this.name,
    required this.position,
    this.track,
  });
  
  factory PlaylistTrack.fromJson(Map<String, dynamic> json) => PlaylistTrack(
    trackId: json['track_id'].toString(),
    name: json['name'] ?? json['track']?['name'] ?? '',
    position: json['position'] ?? 0,
    track: json['track'] != null ? Track.fromJson(json['track']) : null,
  );
}

class Device {
  final String id;
  final String uuid;
  final String name;
  final bool isActive;
  final String licenseKey;
  final DateTime createdAt;
  
  Device({
    required this.id,
    required this.uuid,
    required this.name,
    required this.isActive,
    required this.licenseKey,
    required this.createdAt,
  });
  
  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id: json['id'].toString(),
    uuid: json['uuid'] ?? '',
    name: json['device_name'] ?? json['name'] ?? '',
    isActive: json['is_active'] ?? json['active'] ?? false,
    licenseKey: json['license_key'] ?? '',
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
  );
}

class Friendship {
  final String id;
  final int fromUser;
  final int toUser;
  final String status;
  final DateTime createdAt;
  
  Friendship({
    required this.id,
    required this.fromUser,
    required this.toUser,
    required this.status,
    required this.createdAt,
  });
  
  factory Friendship.fromJson(Map<String, dynamic> json) => Friendship(
    id: json['id'].toString(),
    fromUser: json['from_user'],
    toUser: json['to_user'],
    status: json['status'] ?? 'pending',
    createdAt: DateTime.parse(json['created_at']),
  );
}

enum LicenseType { free, premium, enterprise }
enum PlaylistPermission { view, edit, admin, invite }

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

enum ConflictType { trackMove, trackAdd, trackRemove, playlistEdit, simultaneousEdit }

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
    id: json['id'],
    userId: json['user_id'],
    username: json['username'],
    type: ConflictType.values.firstWhere((e) => e.name == json['type']),
    data: json['data'],
    timestamp: DateTime.parse(json['timestamp']),
    version: json['version'],
  );
}
