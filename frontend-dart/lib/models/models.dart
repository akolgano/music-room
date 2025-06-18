// lib/models/models.dart
class User {
  final String id;
  final String username;
  final String? email;

  const User({required this.id, required this.username, this.email});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'].toString(),
    username: json['username'] as String,
    email: json['email'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
  };
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
    artist: _extractArtist(json),
    album: _extractAlbum(json),
    url: json['url'] ?? json['link'] ?? '',
    deezerTrackId: json['deezer_track_id']?.toString(),
    previewUrl: json['preview_url'] ?? json['preview'],
    imageUrl: _extractImageUrl(json),
  );

  static String _extractArtist(Map<String, dynamic> json) {
    if (json['artist'] is String) return json['artist'];
    if (json['artist'] is Map && json['artist']['name'] != null) {
      return json['artist']['name'];
    }
    return '';
  }

  static String _extractAlbum(Map<String, dynamic> json) {
    if (json['album'] is String) return json['album'];
    if (json['album'] is Map && json['album']['title'] != null) {
      return json['album']['title'];
    }
    return '';
  }

  static String? _extractImageUrl(Map<String, dynamic> json) {
    if (json['image_url'] != null) return json['image_url'];
    if (json['album'] is Map) {
      return json['album']['cover_medium'] ?? json['album']['cover'];
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'artist': artist,
    'album': album,
    'url': url,
    'deezer_track_id': deezerTrackId,
    'preview_url': previewUrl,
    'image_url': imageUrl,
  };
}

class Playlist {
  final String id;
  final String name;
  final String description;
  final bool isPublic;
  final String creator;
  final List<Track> tracks;
  final String? imageUrl;

  const Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.isPublic,
    required this.creator,
    this.tracks = const [],
    this.imageUrl,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
    id: json['id'].toString(),
    name: (json['name'] ?? json['playlist_name']) as String,
    description: json['description'] as String,
    isPublic: json['public'] ?? false,
    creator: json['creator'] as String,
    tracks: (json['tracks'] as List<dynamic>?)
        ?.map((t) => Track.fromJson(t as Map<String, dynamic>))
        .toList() ?? [],
    imageUrl: json['image_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'public': isPublic,
    'creator': creator,
    'tracks': tracks.map((t) => t.toJson()).toList(),
    'image_url': imageUrl,
  };
}

class PlaylistTrack {
  final String trackId;
  final String name;
  final int position;
  final Track? track;

  const PlaylistTrack({
    required this.trackId,
    required this.name,
    required this.position,
    this.track,
  });

  factory PlaylistTrack.fromJson(Map<String, dynamic> json) => PlaylistTrack(
    trackId: json['track_id'].toString(),
    name: json['name'] as String,
    position: json['position'] as int,
    track: json['track'] != null 
        ? Track.fromJson(json['track'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'track_id': trackId,
    'name': name,
    'position': position,
    'track': track?.toJson(),
  };
}

class Device {
  final String id;
  final String uuid;
  final String name;
  final bool isActive;
  final String licenseKey;
  final DateTime createdAt;

  const Device({
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid,
    'device_name': name,
    'is_active': isActive,
    'license_key': licenseKey,
    'created_at': createdAt.toIso8601String(),
  };
}

class Friendship {
  final String id;
  final int fromUser;
  final int toUser;
  final String status;
  final DateTime createdAt;

  const Friendship({
    required this.id,
    required this.fromUser,
    required this.toUser,
    required this.status,
    required this.createdAt,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) => Friendship(
    id: json['id'].toString(),
    fromUser: json['from_user'] as int,
    toUser: json['to_user'] as int,
    status: json['status'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'from_user': fromUser,
    'to_user': toUser,
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };
}

class AddTrackResult {
  final bool success;
  final String message;
  final bool isDuplicate;

  const AddTrackResult({
    required this.success,
    required this.message,
    this.isDuplicate = false,
  });

  factory AddTrackResult.fromJson(Map<String, dynamic> json) => AddTrackResult(
    success: json['success'] as bool,
    message: json['message'] as String,
    isDuplicate: json['is_duplicate'] ?? false,
  );
}

class BatchAddResult {
  final int totalTracks;
  final int successCount;
  final int duplicateCount;
  final int failureCount;
  final List<String> errors;

  const BatchAddResult({
    required this.totalTracks,
    required this.successCount,
    required this.duplicateCount,
    required this.failureCount,
    this.errors = const [],
  });

  factory BatchAddResult.fromJson(Map<String, dynamic> json) => BatchAddResult(
    totalTracks: json['total_tracks'] as int,
    successCount: json['success_count'] as int,
    duplicateCount: json['duplicate_count'] as int,
    failureCount: json['failure_count'] as int,
    errors: (json['errors'] as List<dynamic>?)?.cast<String>() ?? [],
  );

  bool get hasErrors => failureCount > 0;
  bool get hasPartialSuccess => successCount > 0 && failureCount > 0;
  bool get isCompleteSuccess => successCount == totalTracks;
  
  String get summaryMessage {
    if (isCompleteSuccess) return 'All $totalTracks tracks added successfully!';
    else if (hasPartialSuccess) return '$successCount/$totalTracks tracks added successfully';
    else return 'Failed to add tracks to playlist';
  }

  String get detailedMessage {
    final parts = <String>[];
    if (successCount > 0) parts.add('$successCount added');
    if (duplicateCount > 0) parts.add('$duplicateCount duplicates');
    if (failureCount > 0) parts.add('$failureCount failed');
    return parts.join(', ');
  }
}

class SocialLoginResult {
  final bool success;
  final String? token;
  final String? provider;
  final String? error;

  const SocialLoginResult._({required this.success, this.token, this.provider, this.error});

  factory SocialLoginResult.success(String token, String provider) => 
      SocialLoginResult._(success: true, token: token, provider: provider);

  factory SocialLoginResult.error(String error) => 
      SocialLoginResult._(success: false, error: error);
}
