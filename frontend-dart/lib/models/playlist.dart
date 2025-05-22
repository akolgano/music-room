// lib/models/playlist.dart
import 'track.dart';

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
}
