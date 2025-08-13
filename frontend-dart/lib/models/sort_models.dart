import 'package:flutter/material.dart';

enum TrackSortField { name, artist, album, position, dateAdded }

enum PlaylistSortField { name, creator, trackCount, dateCreated }

enum SortOrder { ascending, descending }

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

  bool get isDefault => field == TrackSortField.position;

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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackSortOption &&
          runtimeType == other.runtimeType &&
          field == other.field &&
          order == other.order;

  @override
  int get hashCode => field.hashCode ^ order.hashCode;

  static const List<TrackSortOption> defaultOptions = [
    TrackSortOption(
      field: TrackSortField.position,
      order: SortOrder.ascending,
      displayName: 'Custom Order',
      icon: Icons.reorder,
    ),
    TrackSortOption(
      field: TrackSortField.name,
      order: SortOrder.ascending,
      displayName: 'Track Name (A-Z)',
      icon: Icons.sort_by_alpha,
    ),
    TrackSortOption(
      field: TrackSortField.name,
      order: SortOrder.descending,
      displayName: 'Track Name (Z-A)',
      icon: Icons.sort_by_alpha,
    ),
    TrackSortOption(
      field: TrackSortField.artist,
      order: SortOrder.ascending,
      displayName: 'Artist (A-Z)',
      icon: Icons.person,
    ),
    TrackSortOption(
      field: TrackSortField.artist,
      order: SortOrder.descending,
      displayName: 'Artist (Z-A)',
      icon: Icons.person,
    ),
    TrackSortOption(
      field: TrackSortField.album,
      order: SortOrder.ascending,
      displayName: 'Album (A-Z)',
      icon: Icons.album,
    ),
    TrackSortOption(
      field: TrackSortField.album,
      order: SortOrder.descending,
      displayName: 'Album (Z-A)',
      icon: Icons.album,
    ),
    TrackSortOption(
      field: TrackSortField.dateAdded,
      order: SortOrder.descending,
      displayName: 'Recently Added',
      icon: Icons.schedule,
    ),
    TrackSortOption(
      field: TrackSortField.dateAdded,
      order: SortOrder.ascending,
      displayName: 'Oldest First',
      icon: Icons.schedule,
    ),
  ];
}

class PlaylistSortOption {
  final PlaylistSortField field;
  final SortOrder order;
  final String displayName;
  final IconData icon;

  const PlaylistSortOption({
    required this.field,
    required this.order,
    required this.displayName,
    required this.icon,
  });

  bool get isDefault => field == PlaylistSortField.name && this == defaultOptions.first;

  PlaylistSortOption copyWith({
    PlaylistSortField? field,
    SortOrder? order,
    String? displayName,
    IconData? icon,
  }) {
    return PlaylistSortOption(
      field: field ?? this.field,
      order: order ?? this.order,
      displayName: displayName ?? this.displayName,
      icon: icon ?? this.icon,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistSortOption &&
          runtimeType == other.runtimeType &&
          field == other.field &&
          order == other.order;

  @override
  int get hashCode => field.hashCode ^ order.hashCode;

  static const List<PlaylistSortOption> defaultOptions = [
    PlaylistSortOption(
      field: PlaylistSortField.name,
      order: SortOrder.ascending,
      displayName: 'Name (A-Z)',
      icon: Icons.sort_by_alpha,
    ),
    PlaylistSortOption(
      field: PlaylistSortField.name,
      order: SortOrder.descending,
      displayName: 'Name (Z-A)',
      icon: Icons.sort_by_alpha,
    ),
    PlaylistSortOption(
      field: PlaylistSortField.creator,
      order: SortOrder.ascending,
      displayName: 'Creator (A-Z)',
      icon: Icons.person,
    ),
    PlaylistSortOption(
      field: PlaylistSortField.creator,
      order: SortOrder.descending,
      displayName: 'Creator (Z-A)',
      icon: Icons.person,
    ),
    PlaylistSortOption(
      field: PlaylistSortField.trackCount,
      order: SortOrder.descending,
      displayName: 'Most Tracks',
      icon: Icons.music_note,
    ),
    PlaylistSortOption(
      field: PlaylistSortField.trackCount,
      order: SortOrder.ascending,
      displayName: 'Fewest Tracks',
      icon: Icons.music_note,
    ),
    PlaylistSortOption(
      field: PlaylistSortField.dateCreated,
      order: SortOrder.descending,
      displayName: 'Recently Created',
      icon: Icons.schedule,
    ),
    PlaylistSortOption(
      field: PlaylistSortField.dateCreated,
      order: SortOrder.ascending,
      displayName: 'Oldest First',
      icon: Icons.schedule,
    ),
  ];
}
