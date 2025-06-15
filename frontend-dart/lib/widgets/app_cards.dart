// lib/widgets/app_cards.dart
import 'package:flutter/material.dart';
import '../core/consolidated_core.dart';
import '../models/models.dart';
import 'app_widgets.dart';

class AppCards {
  static Widget track({
    Key? key,
    required Track track,
    bool isSelected = false,
    bool isInPlaylist = false,
    bool showAddButton = true,
    bool showPlayButton = true,
    VoidCallback? onTap,
    VoidCallback? onAdd,
    VoidCallback? onPlay,
    VoidCallback? onRemove,
    VoidCallback? onAddToLibrary,
    ValueChanged<bool?>? onSelectionChanged,
  }) => AppWidgets.trackCard(
    key: key,
    track: track,
    isSelected: isSelected,
    isInPlaylist: isInPlaylist,
    showAddButton: showAddButton,
    showPlayButton: showPlayButton,
    onTap: onTap,
    onAdd: onAdd,
    onPlay: onPlay,
    onRemove: onRemove,
    onAddToLibrary: onAddToLibrary,
    onSelectionChanged: onSelectionChanged,
  );

  static Widget info({
    required String title,
    required String message,
    required IconData icon,
    Color color = AppTheme.primary,
    VoidCallback? onTap,
  }) => AppWidgets.infoBanner(
    title: title,
    message: message,
    icon: icon,
    color: color,
    onAction: onTap,
  );
}
