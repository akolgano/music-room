// lib/models/sort_models.dart
import 'package:flutter/material.dart';

enum TrackSortField {
  name,
  artist, 
  album,
  position,
  dateAdded,
}

enum SortOrder {
  ascending,
  descending,
}

class TrackSortOption {
  final TrackSortField field;
  final SortOrder order;
  final String displayName;
  final IconData icon;

  const TrackSortOption({
    required this.field,
    required this.order,
    required this.displayName,
    required this.icon,
  });

  TrackSortOption copyWith({
    TrackSortField? field,
    SortOrder? order,
    String? displayName,
    IconData? icon,
  }) {
    return TrackSortOption(
      field: field ?? this.field,
      order: order ?? this.order,
      displayName: displayName ?? this.displayName,
      icon: icon ?? this.icon,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is TrackSortOption && runtimeType == other.runtimeType && field == other.field && order == other.order;

  @override
  int get hashCode => field.hashCode ^ order.hashCode;

  static const List<TrackSortOption> defaultOptions = [
    TrackSortOption(field: TrackSortField.position, order: SortOrder.ascending, displayName: 'Custom Order', icon: Icons.reorder),
    TrackSortOption(field: TrackSortField.name, order: SortOrder.ascending, displayName: 'Track Name (A-Z)', icon: Icons.sort_by_alpha),
    TrackSortOption(field: TrackSortField.name, order: SortOrder.descending, displayName: 'Track Name (Z-A)', icon: Icons.sort_by_alpha),
    TrackSortOption(field: TrackSortField.artist, order: SortOrder.ascending, displayName: 'Artist (A-Z)', icon: Icons.person),
    TrackSortOption(field: TrackSortField.artist, order: SortOrder.descending, displayName: 'Artist (Z-A)', icon: Icons.person),
    TrackSortOption(field: TrackSortField.album, order: SortOrder.ascending, displayName: 'Album (A-Z)', icon: Icons.album),
    TrackSortOption(field: TrackSortField.album, order: SortOrder.descending, displayName: 'Album (Z-A)', icon: Icons.album),
    TrackSortOption(field: TrackSortField.dateAdded, order: SortOrder.descending, displayName: 'Recently Added', icon: Icons.schedule),
    TrackSortOption(field: TrackSortField.dateAdded, order: SortOrder.ascending, displayName: 'Oldest First', icon: Icons.schedule),
  ];
}
