import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/models/sort_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('TrackSortOption Tests', () {
    test('should provide correct default options', () {
      final defaultOptions = TrackSortOption.defaultOptions;
      
      expect(defaultOptions.isNotEmpty, isTrue);
      expect(defaultOptions.first.field, TrackSortField.position);
    });

    test('should create TrackSortOption with all properties', () {
      final sortOption = TrackSortOption(
        field: TrackSortField.name,
        order: SortOrder.ascending,
        displayName: 'Name (A-Z)',
        icon: Icons.sort_by_alpha,
      );
      
      expect(sortOption.field, TrackSortField.name);
      expect(sortOption.order, SortOrder.ascending);
      expect(sortOption.displayName, 'Name (A-Z)');
      expect(sortOption.icon, Icons.sort_by_alpha);
    });

    test('should create descending sort option', () {
      final sortOption = TrackSortOption(
        field: TrackSortField.artist,
        order: SortOrder.descending,
        displayName: 'Artist (Z-A)',
        icon: Icons.person,
      );
      
      expect(sortOption.field, TrackSortField.artist);
      expect(sortOption.order, SortOrder.descending);
      expect(sortOption.displayName, 'Artist (Z-A)');
    });

    test('should support equality comparison', () {
      final option1 = TrackSortOption(
        field: TrackSortField.name,
        order: SortOrder.ascending,
        displayName: 'Name',
        icon: Icons.sort_by_alpha,
      );
      
      final option2 = TrackSortOption(
        field: TrackSortField.name,
        order: SortOrder.ascending,
        displayName: 'Name',
        icon: Icons.sort_by_alpha,
      );
      
      final option3 = TrackSortOption(
        field: TrackSortField.artist,
        order: SortOrder.ascending,
        displayName: 'Artist',
        icon: Icons.person,
      );
      
      expect(option1, equals(option2));
      expect(option1, isNot(equals(option3)));
    });

    test('should generate correct hash codes', () {
      final option1 = TrackSortOption(
        field: TrackSortField.name,
        order: SortOrder.ascending,
        displayName: 'Name',
        icon: Icons.sort_by_alpha,
      );
      
      final option2 = TrackSortOption(
        field: TrackSortField.name,
        order: SortOrder.ascending,
        displayName: 'Name',
        icon: Icons.sort_by_alpha,
      );
      
      expect(option1.hashCode, equals(option2.hashCode));
    });

    test('should convert to string representation', () {
      final sortOption = TrackSortOption(
        field: TrackSortField.name,
        order: SortOrder.ascending,
        displayName: 'Name (A-Z)',
        icon: Icons.sort_by_alpha,
      );
      
      final stringRep = sortOption.toString();
      expect(stringRep, contains('TrackSortOption'));
    });

    test('should support copyWith method', () {
      final original = TrackSortOption(
        field: TrackSortField.name,
        order: SortOrder.ascending,
        displayName: 'Name (A-Z)',
        icon: Icons.sort_by_alpha,
      );
      
      final modified = original.copyWith(
        order: SortOrder.descending,
        displayName: 'Name (Z-A)',
      );
      
      expect(modified.field, TrackSortField.name);
      expect(modified.order, SortOrder.descending);
      expect(modified.displayName, 'Name (Z-A)');
      expect(modified.icon, Icons.sort_by_alpha);
    });

    test('should identify default option', () {
      final defaultOption = TrackSortOption(
        field: TrackSortField.position,
        order: SortOrder.ascending,
        displayName: 'Custom Order',
        icon: Icons.reorder,
      );
      
      expect(defaultOption.isDefault, isTrue);
      
      final nonDefaultOption = TrackSortOption(
        field: TrackSortField.name,
        order: SortOrder.ascending,
        displayName: 'Name',
        icon: Icons.sort_by_alpha,
      );
      
      expect(nonDefaultOption.isDefault, isFalse);
    });
  });

  group('TrackSortField Tests', () {
    test('should have all required fields', () {
      expect(TrackSortField.values.contains(TrackSortField.position), isTrue);
      expect(TrackSortField.values.contains(TrackSortField.name), isTrue);
      expect(TrackSortField.values.contains(TrackSortField.artist), isTrue);
      expect(TrackSortField.values.contains(TrackSortField.album), isTrue);
      expect(TrackSortField.values.contains(TrackSortField.dateAdded), isTrue);
      expect(TrackSortField.values.contains(TrackSortField.points), isTrue);
    });

    test('should have correct field names', () {
      expect(TrackSortField.position.name, 'position');
      expect(TrackSortField.name.name, 'name');
      expect(TrackSortField.artist.name, 'artist');
      expect(TrackSortField.album.name, 'album');
      expect(TrackSortField.dateAdded.name, 'dateAdded');
      expect(TrackSortField.points.name, 'points');
    });

    test('should support iteration over all values', () {
      final fields = TrackSortField.values;
      expect(fields.length, greaterThan(0));
      
      for (final field in fields) {
        expect(field.name, isNotEmpty);
      }
    });

    test('should be comparable', () {
      expect(TrackSortField.position.index, greaterThanOrEqualTo(0));
      expect(TrackSortField.name.index, greaterThanOrEqualTo(0));
    });
  });

  group('SortOrder Tests', () {
    test('should have both directions', () {
      expect(SortOrder.values.contains(SortOrder.ascending), isTrue);
      expect(SortOrder.values.contains(SortOrder.descending), isTrue);
    });

    test('should have correct names', () {
      expect(SortOrder.ascending.name, 'ascending');
      expect(SortOrder.descending.name, 'descending');
    });

    test('should support string representation', () {
      expect(SortOrder.ascending.toString(), contains('ascending'));
      expect(SortOrder.descending.toString(), contains('descending'));
    });
  });

  group('PlaylistSortField Tests', () {
    test('should have all required fields', () {
      expect(PlaylistSortField.values.contains(PlaylistSortField.name), isTrue);
      expect(PlaylistSortField.values.contains(PlaylistSortField.creator), isTrue);
      expect(PlaylistSortField.values.contains(PlaylistSortField.trackCount), isTrue);
      expect(PlaylistSortField.values.contains(PlaylistSortField.dateCreated), isTrue);
    });

    test('should have correct field names', () {
      expect(PlaylistSortField.name.name, 'name');
      expect(PlaylistSortField.creator.name, 'creator');
      expect(PlaylistSortField.trackCount.name, 'trackCount');
      expect(PlaylistSortField.dateCreated.name, 'dateCreated');
    });
  });
}