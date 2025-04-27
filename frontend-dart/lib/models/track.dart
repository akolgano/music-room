class Track {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String coverArt;
  final Duration duration;
  int votes;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.coverArt,
    required this.duration,
    this.votes = 0,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      coverArt: json['cover_art'],
      duration: Duration(seconds: json['duration']),
      votes: json['votes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'cover_art': coverArt,
      'duration': duration.inSeconds,
      'votes': votes,
    };
  }
}
