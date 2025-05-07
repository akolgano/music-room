// models/track.dart
class Track {
  final String id;
  final String name;
  final String artist;
  final String album;
  final String url;
  final String? deezerTrackId;
  final String? previewUrl;
  final String? imageUrl;
  
  Track({
    required this.id,
    required this.name,
    required this.artist,
    required this.album,
    required this.url,
    this.deezerTrackId,
    this.previewUrl,
    this.imageUrl,
  });
  
  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'].toString(),
      name: json['name'],
      artist: json['artist'],
      album: json['album'] ?? '',
      url: json['url'] ?? '',
      deezerTrackId: json['deezer_track_id']?.toString(),
      previewUrl: json['preview_url'],
      imageUrl: json['image_url'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
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
}
