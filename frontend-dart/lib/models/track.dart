// lib/models/track.dart
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
