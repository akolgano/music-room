import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/models/sort_models.dart';

void main() {
  group('TrackSortOption Tests', () {
    test('should provide correct default options', () {
      final defaultOptions = TrackSortOption.defaultOptions;
      
      expect(defaultOptions.isNotEmpty, isTrue);
      expect(defaultOptions.first.field, TrackSortField.position);
    });

    test('should create TrackSortOption with all properties', () {
      final sortOption = TrackSortOption(
        field: TrackSortField.name,
        direction: SortDirection.ascending,
        displayName: 'Name (A-Z)',
      );
      
      expect(sortOption.field, TrackSortField.name);
      expect(sortOption.direction, SortDirection.ascending);
      expect(sortOption.displayName, 'Name (A-Z)');
    });

    test('should create descending sort option', () {
      final sortOption = TrackSortOption(
        field: TrackSortField.artist,
        direction: SortDirection.descending,
        displayName: 'Artist (Z-A)',
      );
      
      expect(sortOption.field, TrackSortField.artist);
      expect(sortOption.direction, SortDirection.descending);
      expect(sortOption.displayName, 'Artist (Z-A)');
    });

    test('should support equality comparison', () {
      final option1 = TrackSortOption(
        field: TrackSortField.name,
        direction: SortDirection.ascending,
        displayName: 'Name',
      );
      
      final option2 = TrackSortOption(
        field: TrackSortField.name,
        direction: SortDirection.ascending,
        displayName: 'Name',
      );
      
      final option3 = TrackSortOption(
        field: TrackSortField.artist,
        direction: SortDirection.ascending,
        displayName: 'Artist',
      );
      
      expect(option1, equals(option2));
      expect(option1, isNot(equals(option3)));
    });

    test('should generate correct hash codes', () {
      final option1 = TrackSortOption(
        field: TrackSortField.name,
        direction: SortDirection.ascending,
        displayName: 'Name',
      );
      
      final option2 = TrackSortOption(
        field: TrackSortField.name,
        direction: SortDirection.ascending,
        displayName: 'Name',
      );
      
      expect(option1.hashCode, equals(option2.hashCode));
    });

    test('should convert to string representation', () {
      final sortOption = TrackSortOption(
        field: TrackSortField.name,
        direction: SortDirection.ascending,
        displayName: 'Name (A-Z)',
      );
      
      final stringRep = sortOption.toString();
      expect(stringRep, contains('TrackSortOption'));
      expect(stringRep, contains('name'));
      expect(stringRep, contains('ascending'));
    });
  });

  group('TrackSortField Tests', () {
    test('should have all required fields', () {
      expect(TrackSortField.values.contains(TrackSortField.position), isTrue);
      expect(TrackSortField.values.contains(TrackSortField.name), isTrue);
      expect(TrackSortField.values.contains(TrackSortField.artist), isTrue);
      expect(TrackSortField.values.contains(TrackSortField.album), isTrue);
      expect(TrackSortField.values.contains(TrackSortField.duration), isTrue);
      expect(TrackSortField.values.contains(TrackSortField.dateAdded), isTrue);
    });

    test('should have correct field names', () {
      expect(TrackSortField.position.name, 'position');
      expect(TrackSortField.name.name, 'name');
      expect(TrackSortField.artist.name, 'artist');
      expect(TrackSortField.album.name, 'album');
      expect(TrackSortField.duration.name, 'duration');
      expect(TrackSortField.dateAdded.name, 'dateAdded');
    });

    test('should support iteration over all values', () {
      final fields = TrackSortField.values;
      expect(fields.length, greaterThan(0));
      
      for (final field in fields) {
        expect(field.name, isNotEmpty);
      }
    });

    test('should be comparable', () {
      expect(TrackSortField.position.index, lessThan(TrackSortField.name.index));
    });
  });

  group('SortDirection Tests', () {
    test('should have both directions', () {
      expect(SortDirection.values.contains(SortDirection.ascending), isTrue);
      expect(SortDirection.values.contains(SortDirection.descending), isTrue);
    });

    test('should have correct names', () {
      expect(SortDirection.ascending.name, 'ascending');
      expect(SortDirection.descending.name, 'descending');
    });

    test('should support opposite direction', () {
      expect(SortDirection.ascending.opposite, SortDirection.descending);
      expect(SortDirection.descending.opposite, SortDirection.ascending);
    });

    test('should support string representation', () {
      expect(SortDirection.ascending.toString(), contains('ascending'));
      expect(SortDirection.descending.toString(), contains('descending'));
    });
  });

  group('PlaylistSortOption Tests', () {
    test('should create playlist sort option with all properties', () {
      final sortOption = PlaylistSortOption(
        field: PlaylistSortField.name,
        direction: SortDirection.ascending,
        displayName: 'Name (A-Z)',
      );
      
      expect(sortOption.field, PlaylistSortField.name);
      expect(sortOption.direction, SortDirection.ascending);
      expect(sortOption.displayName, 'Name (A-Z)');
    });

    test('should support all playlist sort fields', () {
      expect(PlaylistSortField.values.contains(PlaylistSortField.name), isTrue);
      expect(PlaylistSortField.values.contains(PlaylistSortField.dateCreated), isTrue);
      expect(PlaylistSortField.values.contains(PlaylistSortField.dateModified), isTrue);
      expect(PlaylistSortField.values.contains(PlaylistSortField.trackCount), isTrue);
      expect(PlaylistSortField.values.contains(PlaylistSortField.duration), isTrue);
    });

    test('should provide default playlist sort options', () {
      final defaultOptions = PlaylistSortOption.defaultOptions;
      
      expect(defaultOptions, isNotEmpty);
      expect(defaultOptions.every((option) => option.displayName.isNotEmpty), isTrue);
    });
  });

  group('SortComparator Tests', () {
    test('should create ascending comparator for strings', () {
      final comparator = SortComparator.string(SortDirection.ascending);
      
      expect(comparator('apple', 'banana'), lessThan(0));
      expect(comparator('banana', 'apple'), greaterThan(0));
      expect(comparator('apple', 'apple'), equals(0));
    });

    test('should create descending comparator for strings', () {
      final comparator = SortComparator.string(SortDirection.descending);
      
      expect(comparator('apple', 'banana'), greaterThan(0));
      expect(comparator('banana', 'apple'), lessThan(0));
      expect(comparator('apple', 'apple'), equals(0));
    });

    test('should create ascending comparator for integers', () {
      final comparator = SortComparator.integer(SortDirection.ascending);
      
      expect(comparator(1, 2), lessThan(0));
      expect(comparator(2, 1), greaterThan(0));
      expect(comparator(1, 1), equals(0));
    });

    test('should create descending comparator for integers', () {
      final comparator = SortComparator.integer(SortDirection.descending);
      
      expect(comparator(1, 2), greaterThan(0));
      expect(comparator(2, 1), lessThan(0));
      expect(comparator(1, 1), equals(0));
    });

    test('should create datetime comparator', () {
      final now = DateTime.now();
      final later = now.add(const Duration(hours: 1));
      final earlier = now.subtract(const Duration(hours: 1));
      
      final ascComparator = SortComparator.datetime(SortDirection.ascending);
      expect(ascComparator(earlier, later), lessThan(0));
      expect(ascComparator(later, earlier), greaterThan(0));
      expect(ascComparator(now, now), equals(0));
      
      final descComparator = SortComparator.datetime(SortDirection.descending);
      expect(descComparator(earlier, later), greaterThan(0));
      expect(descComparator(later, earlier), lessThan(0));
    });

    test('should handle null values in string comparison', () {
      final comparator = SortComparator.stringNullable(SortDirection.ascending);
      
      expect(comparator(null, 'test'), lessThan(0));
      expect(comparator('test', null), greaterThan(0));
      expect(comparator(null, null), equals(0));
      expect(comparator('apple', 'banana'), lessThan(0));
    });
  });
}
