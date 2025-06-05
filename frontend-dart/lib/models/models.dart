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
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    if (email != null) 'email': email,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track &&
          runtimeType == other.runtimeType &&
          id == other.id;

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
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'public': isPublic,
    'creator': creator,
    'tracks': tracks.map((track) => track.toJson()).toList(),
    'image_url': imageUrl,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class PlaylistTrack {
  final String trackId;
  final String name;
  final int position;
  
  PlaylistTrack({
    required this.trackId,
    required this.name,
    required this.position,
  });
  
  factory PlaylistTrack.fromJson(Map<String, dynamic> json) => PlaylistTrack(
    trackId: json['track_id'].toString(),
    name: json['name'] ?? '',
    position: json['position'] ?? 0,
  );
  
  Map<String, dynamic> toJson() => {
    'track_id': trackId,
    'name': name,
    'position': position,
  };
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
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid,
    'device_name': name,
    'is_active': isActive,
    'license_key': licenseKey,
    'created_at': createdAt.toIso8601String(),
  };
}
