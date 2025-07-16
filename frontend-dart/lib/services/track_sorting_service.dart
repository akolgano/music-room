import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../models/sort_models.dart';

class TrackSortingService {
  static List<PlaylistTrack> sortTracks(List<PlaylistTrack> tracks, TrackSortOption sortOption) {
    return tracks.sorted((a, b) {
      final comparison = _getComparison(a, b, sortOption.field);
      return sortOption.order == SortOrder.ascending ? comparison : -comparison;
    });
  }

  static List<Track> sortTrackList(List<Track> tracks, TrackSortOption sortOption) {
    return tracks.sorted((a, b) {
      final comparison = _getTrackComparison(a, b, sortOption.field);
      return sortOption.order == SortOrder.ascending ? comparison : -comparison;
    });
  }

  static int _getTrackComparison(Track a, Track b, TrackSortField field) {
    switch (field) {
      case TrackSortField.position: return 0;
      case TrackSortField.name: return compareAsciiLowerCase(a.name, b.name);
      case TrackSortField.artist: return compareAsciiLowerCase(a.artist, b.artist);
      case TrackSortField.album: return compareAsciiLowerCase(a.album, b.album);
      case TrackSortField.dateAdded: return 0;
    }
  }

  static int _getComparison(PlaylistTrack a, PlaylistTrack b, TrackSortField field) {
    switch (field) {
      case TrackSortField.position:
        return a.position.compareTo(b.position);
      case TrackSortField.name:
        final aName = a.track?.name ?? a.name;
        final bName = b.track?.name ?? b.name;
        return compareAsciiLowerCase(aName, bName);
      case TrackSortField.artist:
        final aArtist = a.track?.artist ?? '';
        final bArtist = b.track?.artist ?? '';
        return compareAsciiLowerCase(aArtist, bArtist);
      case TrackSortField.album:
        final aAlbum = a.track?.album ?? '';
        final bAlbum = b.track?.album ?? '';
        return compareAsciiLowerCase(aAlbum, bAlbum);
      case TrackSortField.dateAdded:
        return a.position.compareTo(b.position);
    }
  }

  static List<PlaylistTrack> filterTracks(List<PlaylistTrack> tracks, String searchTerm) {
    if (searchTerm.isEmpty) return tracks;
    final lowerSearchTerm = searchTerm.toLowerCase();
    return tracks.where((track) {
      final name = (track.track?.name ?? track.name).toLowerCase();
      final artist = (track.track?.artist ?? '').toLowerCase();
      final album = (track.track?.album ?? '').toLowerCase();
      return name.contains(lowerSearchTerm) || artist.contains(lowerSearchTerm) || album.contains(lowerSearchTerm);
    }).toList();
  }
}

extension PlaylistTrackSorting on List<PlaylistTrack> {
  void sortInPlace(TrackSortOption sortOption) {
    sort((a, b) {
      final comparison = TrackSortingService._getComparison(a, b, sortOption.field);
      return sortOption.order == SortOrder.ascending ? comparison : -comparison;
    });
  }

  List<PlaylistTrack> sortedCopy(TrackSortOption sortOption) {
    return TrackSortingService.sortTracks(this, sortOption);
  }

  List<PlaylistTrack> thenSortBy(TrackSortField field, [SortOrder order = SortOrder.ascending]) {
    final option = TrackSortOption(field: field, order: order, displayName: '', icon: Icons.sort);
    return sortedCopy(option);
  }
}
