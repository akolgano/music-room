import '../core/navigation_core.dart';

class User {
  final String id;
  final String username;
  final String? email;
  const User({required this.id, required this.username, this.email});
  factory User.fromJson(Map<String, dynamic> json) => User(id: json['id'].toString(), username: json['username'] as String, email: json['email'] as String?);
  Map<String, dynamic> toJson() => { 'id': id, 'username': username, 'email': email };
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

  String get backendId {
    if (deezerTrackId != null) { return deezerTrackId!; }
    return id;
  }


  bool get isDeezerTrack {
    return deezerTrackId != null || id.startsWith('deezer_');
  }


  factory Track.fromJson(Map<String, dynamic> json) {
    String trackId;
    String? deezerTrackId;
    
    if (json.containsKey('preview') || json.containsKey('link')) {
      final deezerIdString = json['id'].toString();
      trackId = 'deezer_$deezerIdString';
      deezerTrackId = deezerIdString;
    } else {
      trackId = json['id'].toString();
      deezerTrackId = json['deezer_track_id']?.toString();
    }
    
    return Track(
      id: trackId,
      name: json['name'] ?? json['title'] ?? '',
      artist: _extractArtist(json),
      album: _extractAlbum(json),
      url: json['url'] ?? json['link'] ?? '',
      deezerTrackId: deezerTrackId,
      previewUrl: json['preview_url'] ?? json['preview'],
      imageUrl: _extractImageUrl(json),
    );
  }

  static String _extractArtist(Map<String, dynamic> json) {
    if (json['artist'] is String) {
      return json['artist'] as String;
    }
    if (json['artist'] is Map && json['artist']['name'] is String) {
      return json['artist']['name'] as String;
    }
    return '';
  }

  static String _extractAlbum(Map<String, dynamic> json) {
    if (json['album'] is String) {
      return json['album'] as String;
    }
    if (json['album'] is Map && json['album']['title'] is String) {
      return json['album']['title'] as String;
    }
    return '';
  }

  static String? _extractImageUrl(Map<String, dynamic> json) {
    if (json['image_url'] is String) {
      return json['image_url'] as String;
    }
    if (json['album'] is Map) {
      final album = json['album'] as Map<String, dynamic>;
      if (album['cover_medium'] is String) {
        return album['cover_medium'] as String;
      }
      if (album['cover'] is String) {
        return album['cover'] as String;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name,
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
  final String licenseType;

  const Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.isPublic,
    required this.creator,
    this.tracks = const [],
    this.imageUrl,
    this.licenseType = 'open',
  });

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
    id: json['id'].toString(),
    name: (json['name'] ?? json['playlist_name']) as String,
    description: json['description'] as String,
    isPublic: json['public'] ?? false,
    creator: json['creator'] as String,
    tracks: (json['tracks'] as List<dynamic>?) ?.map((t) => Track.fromJson(t as Map<String, dynamic>)).toList() ?? [],
    imageUrl: json['image_url'] as String?,
    licenseType: json['license_type'] as String? ?? 'open',
  );

  bool canEdit(String? username) {
    if (username == creator) return true;
    if (licenseType == 'open') return true;
    return false;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'public': isPublic,
    'creator': creator, 
    'tracks': tracks.map((t) => t.toJson()).toList(), 
    'image_url': imageUrl,
    'license_type': licenseType,
  };
}

class PlaylistTrack {
  final String trackId;
  final String? playlistTrackId;
  final String name;
  final int position;
  final int points; 
  final Track? track;

  const PlaylistTrack({
    required this.trackId,
    this.playlistTrackId,
    required this.name,
    required this.position,
    this.points = 0, 
    this.track,
  });

  factory PlaylistTrack.fromJson(Map<String, dynamic> json) {
    Track? track;
    
    if (json['track'] != null) {
      try {
        track = Track.fromJson(json['track'] as Map<String, dynamic>);
      } catch (e) {
        AppLogger.error('Error parsing nested track: ${e.toString()}', null, null, 'PlaylistTrack');
      }
    } 
    else if (json['deezer_track_id'] != null) {
      final deezerTrackId = json['deezer_track_id'].toString();
      
      String? artist;
      String? album;

      if (json['artist'] != null) {
        if (json['artist'] is String) {
          artist = json['artist'] as String;
        } else if (json['artist'] is Map && json['artist']['name'] != null) {
          artist = json['artist']['name'] as String;
        }
      }

      if (json['album'] != null) {
        if (json['album'] is String) {
          album = json['album'] as String;
        } else if (json['album'] is Map && json['album']['title'] != null) {
          album = json['album']['title'] as String;
        }
      }

      track = Track(
        id: 'deezer_$deezerTrackId',
        name: json['name'] as String? ?? '',
        artist: artist ?? '', 
        album: album ?? '',   
        url: json['url'] as String? ?? '',
        deezerTrackId: deezerTrackId,
        previewUrl: json['preview_url'] as String?,
        imageUrl: json['image_url'] as String?,
      );
    }

    return PlaylistTrack(
      trackId: (json['track_id'] ?? json['id']).toString(),
      playlistTrackId: json['playlist_track_id']?.toString(),
      name: (json['name'] ?? track?.name ?? '').toString(),
      position: json['position'] as int,
      points: json['points'] as int? ?? 0, 
      track: track,
    );
  }

  Map<String, dynamic> toJson() => {
    'track_id': trackId,
    'name': name,
    'position': position,
    'points': points,
    'track': track?.toJson(),
  };

  bool get needsTrackDetails {
    if (track?.deezerTrackId == null) { return false; }
    
    final needsArtist = track?.artist.isEmpty ?? true;
    final needsAlbum = track?.album.isEmpty ?? true;
    
    final criticalInfoMissing = needsArtist || needsAlbum;
    
    if (criticalInfoMissing) {
      AppLogger.debug('Track ${track?.name} (Deezer ID: ${track?.deezerTrackId}) needs details: artist=${track?.artist.isEmpty}, album=${track?.album.isEmpty}', 'PlaylistTrack');
    }
    
    return criticalInfoMissing;
  }

  bool get hasCompleteDetails {
    return track?.deezerTrackId != null &&
           track?.artist.isNotEmpty == true &&
           track?.album.isNotEmpty == true;
  }

  String get displayName {
    final trackName = track?.name;
    return (trackName?.isNotEmpty == true) ? trackName! : name;
  }

  String get displayAlbum {
    final trackAlbum = track?.album;
    return (trackAlbum?.isNotEmpty == true) ? trackAlbum! : 'Unknown Album';
  }

  String get displayArtist {
    final trackArtist = track?.artist;
    return (trackArtist?.isNotEmpty == true) ? trackArtist! : 'Unknown Artist';
  }

  PlaylistTrack copyWithTrack(Track newTrack) {
    return PlaylistTrack(
      trackId: trackId,
      playlistTrackId: playlistTrackId,
      name: name,
      position: position,
      points: points,
      track: newTrack,
    );
  }

  PlaylistTrack copyWithPoints(int newPoints) {
    return PlaylistTrack(
      trackId: trackId,
      playlistTrackId: playlistTrackId,
      name: name,
      position: position,
      points: newPoints,
      track: track,
    );
  }

  @override
  String toString() {
    return 'PlaylistTrack(trackId: $trackId, name: $name, position: $position, points: $points, hasTrack: ${track != null}, needsDetails: $needsTrackDetails)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) { return true; }
    return other is PlaylistTrack &&
           other.trackId == trackId &&
           other.position == position;
  }

  @override
  int get hashCode => trackId.hashCode ^ position.hashCode;
}

class PlaylistInfoWithVotes {
  final int id;
  final String playlistName;
  final String description;
  final bool public;
  final String creator;
  final List<Map<String, dynamic>> tracks;

  const PlaylistInfoWithVotes({
    required this.id,
    required this.playlistName,
    required this.description,
    required this.public,
    required this.creator,
    required this.tracks,
  });

  factory PlaylistInfoWithVotes.fromJson(Map<String, dynamic> json) => 
      PlaylistInfoWithVotes(
        id: json['id'] as int,
        playlistName: json['playlist_name'] as String,
        description: json['description'] as String,
        public: json['public'] as bool,
        creator: json['creator'] as String,
        tracks: (json['tracks'] as List<dynamic>?) ?.map((track) => track as Map<String, dynamic>).toList() ?? [],
      );

  Map<String, dynamic> toJson() => {'id': id,
    'playlist_name': playlistName,
    'description': description,
    'public': public,
    'creator': creator,
    'tracks': tracks,
  };
}