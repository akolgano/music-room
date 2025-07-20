import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/models/sort_models.dart';

void main() {
  group('Sort Models Tests', () {
    test('TrackSortOption should provide correct default options', () {
      print('Testing: TrackSortOption should provide correct default options');
      final defaultOptions = TrackSortOption.defaultOptions;
      
      expect(defaultOptions.isNotEmpty, true);
      expect(defaultOptions.first.field, TrackSortField.position);
    });

    test('TrackSortField should have all required fields', () {
      print('Testing: TrackSortField should have all required fields');
      expect(TrackSortField.values.contains(TrackSortField.position), true);
      expect(TrackSortField.values.contains(TrackSortField.name), true);
      expect(TrackSortField.values.contains(TrackSortField.artist), true);
    });
  });
}
