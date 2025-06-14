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
