import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:music_room/widgets/track_sort_bottom_sheet.dart';
import 'package:music_room/models/sort_models.dart';

void main() {
  group('Sort Button Tests', () {
    late TrackSortOption sortOption;
    late VoidCallback onPressed;

    setUp(() {
      sortOption = const TrackSortOption(
        displayName: 'Test Sort',
        field: TrackSortField.name,
        order: SortOrder.ascending,
        icon: Icons.sort,
      );
      onPressed = () {};
    });

    test('SortButton should be instantiable', () {
      final widget = SortButton(
        currentSort: sortOption,
        onPressed: onPressed,
      );
      expect(widget, isA<SortButton>());
    });

    test('SortButton should extend StatelessWidget', () {
      final widget = SortButton(
        currentSort: sortOption,
        onPressed: onPressed,
      );
      expect(widget, isA<StatelessWidget>());
    });

    test('SortButton should accept required parameters', () {
      final widget = SortButton(
        currentSort: sortOption,
        onPressed: onPressed,
      );
      expect(widget.currentSort, sortOption);
      expect(widget.onPressed, onPressed);
    });

    test('SortButton should handle showLabel parameter', () {
      final widget = SortButton(
        currentSort: sortOption,
        onPressed: onPressed,
        showLabel: false,
      );
      expect(widget.showLabel, false);
    });

    test('SortButton should default showLabel to true', () {
      final widget = SortButton(
        currentSort: sortOption,
        onPressed: onPressed,
      );
      expect(widget.showLabel, true);
    });

    test('SortButton should handle key parameter', () {
      const key = Key('sort_button');
      final widget = SortButton(
        key: key,
        currentSort: sortOption,
        onPressed: onPressed,
      );
      expect(widget.key, key);
    });

    test('SortButton should have build method', () {
      final widget = SortButton(
        currentSort: sortOption,
        onPressed: onPressed,
      );
      expect(widget.build, isA<Function>());
    });

    test('SortButton should handle position sort field', () {
      const positionSort = TrackSortOption(
        displayName: 'Position Sort',
        field: TrackSortField.position,
        order: SortOrder.ascending,
        icon: Icons.reorder,
      );
      final widget = SortButton(
        currentSort: positionSort,
        onPressed: onPressed,
      );
      expect(widget.currentSort.field, TrackSortField.position);
    });
  });
}