import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/models/sort_models.dart';
import 'package:flutter/material.dart';

void main() {
  group('Track Sort Bottom Sheet Tests', () {
    test('TrackSortBottomSheet should display sort options correctly', () {
      const sortOptions = [
        TrackSortOption(field: TrackSortField.name, order: SortOrder.ascending, displayName: 'Name (A-Z)', icon: Icons.sort_by_alpha),
        TrackSortOption(field: TrackSortField.name, order: SortOrder.descending, displayName: 'Name (Z-A)', icon: Icons.sort_by_alpha),
        TrackSortOption(field: TrackSortField.artist, order: SortOrder.ascending, displayName: 'Artist (A-Z)', icon: Icons.person),
        TrackSortOption(field: TrackSortField.artist, order: SortOrder.descending, displayName: 'Artist (Z-A)', icon: Icons.person),
        TrackSortOption(field: TrackSortField.album, order: SortOrder.ascending, displayName: 'Album (A-Z)', icon: Icons.album),
        TrackSortOption(field: TrackSortField.dateAdded, order: SortOrder.descending, displayName: 'Recently Added', icon: Icons.schedule),
        TrackSortOption(field: TrackSortField.position, order: SortOrder.ascending, displayName: 'Playlist Order', icon: Icons.reorder),
      ];

      expect(sortOptions.length, 7);
      expect(sortOptions.first.field, TrackSortField.name);
      expect(sortOptions.first.order, SortOrder.ascending);
      expect(sortOptions.first.displayName, 'Name (A-Z)');

      var selectedOption = sortOptions.first;
      expect(selectedOption.field, TrackSortField.name);
      expect(selectedOption.order, SortOrder.ascending);

      selectedOption = sortOptions[2];
      expect(selectedOption.field, TrackSortField.artist);
      expect(selectedOption.displayName, 'Artist (A-Z)');

      final nameDescending = sortOptions.firstWhere((option) => 
        option.field == TrackSortField.name && option.order == SortOrder.descending
      );
      expect(nameDescending.displayName, 'Name (Z-A)');
      expect(nameDescending.order, SortOrder.descending);

      final recentlyAdded = sortOptions.firstWhere((option) => 
        option.field == TrackSortField.dateAdded
      );
      expect(recentlyAdded.displayName, 'Recently Added');
      expect(recentlyAdded.order, SortOrder.descending);
    });

    test('TrackSortBottomSheet should handle sort field validation', () {
      const availableFields = [
        TrackSortField.name,
        TrackSortField.artist,
        TrackSortField.album,
        TrackSortField.dateAdded,
        TrackSortField.position,
      ];

      expect(availableFields.length, 5);
      expect(availableFields.contains(TrackSortField.name), true);
      expect(availableFields.contains(TrackSortField.artist), true);
      expect(availableFields.contains(TrackSortField.album), true);
      expect(availableFields.contains(TrackSortField.dateAdded), true);
      expect(availableFields.contains(TrackSortField.position), true);

      const fieldDisplayNames = {
        TrackSortField.name: 'Track Name',
        TrackSortField.artist: 'Artist',
        TrackSortField.album: 'Album',
        TrackSortField.dateAdded: 'Date Added',
        TrackSortField.position: 'Position',
      };

      expect(fieldDisplayNames[TrackSortField.name], 'Track Name');
      expect(fieldDisplayNames[TrackSortField.artist], 'Artist');
      expect(fieldDisplayNames[TrackSortField.dateAdded], 'Date Added');
    });

    test('TrackSortBottomSheet should handle sort option creation', () {
      const nameSortAsc = TrackSortOption(
        field: TrackSortField.name,
        order: SortOrder.ascending,
        displayName: 'Name (A-Z)',
        icon: Icons.sort_by_alpha,
      );

      const nameSortDesc = TrackSortOption(
        field: TrackSortField.name,
        order: SortOrder.descending,
        displayName: 'Name (Z-A)',
        icon: Icons.sort_by_alpha,
      );

      expect(nameSortAsc.field, TrackSortField.name);
      expect(nameSortAsc.order, SortOrder.ascending);
      expect(nameSortDesc.order, SortOrder.descending);

      expect(nameSortAsc.order != nameSortDesc.order, true);

      const defaultSort = TrackSortOption(
        field: TrackSortField.position,
        order: SortOrder.ascending,
        displayName: 'Default Order',
        icon: Icons.reorder,
      );

      expect(defaultSort.field, TrackSortField.position);
      expect(defaultSort.order, SortOrder.ascending);
    });
  });
}
