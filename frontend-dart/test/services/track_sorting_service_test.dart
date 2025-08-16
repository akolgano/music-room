import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:music_room/services/music_services.dart';
import 'package:music_room/models/music_models.dart';
import 'package:music_room/models/sort_models.dart';

void main() {
  group('Track Sorting Service Tests', () {
    test('TrackSortingService should sort tracks by name ascending', () {
      final tracks = [
        const PlaylistTrack(trackId: '1', name: 'Z Song', position: 1),
        const PlaylistTrack(trackId: '2', name: 'A Song', position: 2),
        const PlaylistTrack(trackId: '3', name: 'M Song', position: 3),
      ];
      
      const sortOption = TrackSortOption(
        displayName: 'By Name',
        field: TrackSortField.name,
        order: SortOrder.ascending,
        icon: Icons.sort_by_alpha,
      );
      
      final sorted = TrackSortingService.sortTracks(tracks, sortOption);
      
      expect(sorted[0].name, 'A Song');
      expect(sorted[1].name, 'M Song');
      expect(sorted[2].name, 'Z Song');
    });

    test('TrackSortingService should sort tracks by position ascending', () {
      final tracks = [
        const PlaylistTrack(trackId: '1', name: 'Song 1', position: 3, points: 5),
        const PlaylistTrack(trackId: '2', name: 'Song 2', position: 1, points: 10),
        const PlaylistTrack(trackId: '3', name: 'Song 3', position: 2, points: 3),
      ];
      
      const sortOption = TrackSortOption(
        displayName: 'By Position',
        field: TrackSortField.position,
        order: SortOrder.ascending,
        icon: Icons.reorder,
      );
      
      final sorted = TrackSortingService.sortTracks(tracks, sortOption);
      
      expect(sorted[0].position, 1);
      expect(sorted[1].position, 2);
      expect(sorted[2].position, 3);
    });

    test('TrackSortingService should handle empty track list', () {
      const List<PlaylistTrack> tracks = [];
      
      const sortOption = TrackSortOption(
        displayName: 'By Name',
        field: TrackSortField.name,
        order: SortOrder.ascending,
        icon: Icons.sort_by_alpha,
      );
      
      final sorted = TrackSortingService.sortTracks(tracks, sortOption);
      
      expect(sorted, isEmpty);
    });

    test('TrackSortingService should sort tracks by points descending', () {
      final tracks = [
        const PlaylistTrack(trackId: '1', name: 'Song 1', position: 1, points: 5),
        const PlaylistTrack(trackId: '2', name: 'Song 2', position: 2, points: 15),
        const PlaylistTrack(trackId: '3', name: 'Song 3', position: 3, points: 10),
      ];
      
      final sortOption = TrackSortOption(
        displayName: 'By Points',
        field: TrackSortField.points,
        order: SortOrder.descending,
        icon: Icons.star,
      );
      
      final sorted = TrackSortingService.sortTracks(tracks, sortOption);
      
      expect(sorted[0].points, 15);
      expect(sorted[1].points, 10);
      expect(sorted[2].points, 5);
    });

    test('TrackSortingService should sort Track list correctly', () {
      final tracks = [
        const Track(id: '1', name: 'Z Song', artist: 'Artist Z', album: 'Album Z', url: ''),
        const Track(id: '2', name: 'A Song', artist: 'Artist A', album: 'Album A', url: ''),
      ];
      
      const sortOption = TrackSortOption(
        displayName: 'By Name',
        field: TrackSortField.name,
        order: SortOrder.ascending,
        icon: Icons.sort_by_alpha,
      );
      
      final sorted = TrackSortingService.sortTrackList(tracks, sortOption);
      
      expect(sorted[0].name, 'A Song');
      expect(sorted[1].name, 'Z Song');
    });
  });
}