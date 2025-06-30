// lib/services/track_sorting_service.dart
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

  static List<Track> sortTracksByField(List<Track> tracks, TrackSortOption sortOption) {
    return tracks.sorted((a, b) {
      final comparison = _getTrackComparison(a, b, sortOption.field);
      return sortOption.order == SortOrder.ascending ? comparison : -comparison;
    });
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

  static int _getTrackComparison(Track a, Track b, TrackSortField field) {
    switch (field) {
      case TrackSortField.position: return 0; 
      case TrackSortField.name: return compareAsciiLowerCase(a.name, b.name);
      case TrackSortField.artist: return compareAsciiLowerCase(a.artist, b.artist);
      case TrackSortField.album: return compareAsciiLowerCase(a.album, b.album);
      case TrackSortField.dateAdded: return 0; 
    }
  }

  static Map<String, List<PlaylistTrack>> groupTracksByField(
    List<PlaylistTrack> tracks,
    TrackSortField field,
  ) {
    return tracks.groupListsBy((track) {
      switch (field) {
        case TrackSortField.artist:
          return track.track?.artist ?? 'Unknown Artist';
        case TrackSortField.album:
          return track.track?.album ?? 'Unknown Album';
        case TrackSortField.name:
          return track.track?.name.substring(0, 1).toUpperCase() ?? 'Unknown';
        case TrackSortField.position:
          return 'Position ${track.position}';
        case TrackSortField.dateAdded:
          return 'Added';
      }
    });
  }

  static List<PlaylistTrack> filterTracks(
    List<PlaylistTrack> tracks,
    String searchTerm,
  ) {
    if (searchTerm.isEmpty) return tracks;
    final lowerSearchTerm = searchTerm.toLowerCase();
    return tracks.where((track) {
      final name = (track.track?.name ?? track.name).toLowerCase();
      final artist = (track.track?.artist ?? '').toLowerCase();
      final album = (track.track?.album ?? '').toLowerCase();
      return name.contains(lowerSearchTerm) ||
             artist.contains(lowerSearchTerm) ||
             album.contains(lowerSearchTerm);
    }).toList();
  }

  static List<String> getUniqueFieldValues(
    List<PlaylistTrack> tracks,
    TrackSortField field,
  ) {
    return tracks
        .map((track) {
          switch (field) {
            case TrackSortField.artist:
              return track.track?.artist ?? 'Unknown Artist';
            case TrackSortField.album:
              return track.track?.album ?? 'Unknown Album';
            case TrackSortField.name:
            case TrackSortField.position:
            case TrackSortField.dateAdded:
              return '';
          }
        })
        .where((value) => value.isNotEmpty)
        .toSet()
        .sorted(compareAsciiLowerCase);
  }

  static (List<PlaylistTrack>, List<PlaylistTrack>) partitionTracksByCondition(
    List<PlaylistTrack> tracks,
    bool Function(PlaylistTrack) condition,
  ) {
    final matching = tracks.where(condition).toList();
    final nonMatching = tracks.where((track) => !condition(track)).toList();
    return (matching, nonMatching);
  }

  static List<PlaylistTrack> getTopNTracks(
    List<PlaylistTrack> tracks,
    TrackSortOption sortOption,
    int count,
  ) {
    return tracks
        .sorted((a, b) {
          final comparison = _getComparison(a, b, sortOption.field);
          return sortOption.order == SortOrder.ascending ? comparison : -comparison;
        })
        .take(count)
        .toList();
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
    final option = TrackSortOption(
      field: field,
      order: order,
      displayName: '',
      icon: Icons.sort,
    );
    return sortedCopy(option);
  }
}
