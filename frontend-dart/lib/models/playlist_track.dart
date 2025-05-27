// lib/models/playlist_track.dart
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
