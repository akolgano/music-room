// lib/widgets/sort_button.dart
import 'package:flutter/material.dart';
import '../core/core.dart';
import '../models/sort_models.dart';

class SortButton extends StatelessWidget {
  final TrackSortOption currentSort;
  final VoidCallback onPressed;
  final bool showLabel;

  const SortButton({Key? key, required this.currentSort, required this.onPressed, this.showLabel = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCustomOrder = currentSort.field == TrackSortField.position;
    
    if (showLabel) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(currentSort.icon, size: 18),
        label: Text(
          isCustomOrder ? 'Sort' : currentSort.displayName,
          style: const TextStyle(fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isCustomOrder ? AppTheme.surface : AppTheme.primary,
          foregroundColor: isCustomOrder ? Colors.white : Colors.black,
          side: BorderSide(
            color: isCustomOrder ? Colors.white54 : AppTheme.primary,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
    } else {
      return IconButton(
        onPressed: onPressed,
        icon: Icon(
          currentSort.icon,
          color: isCustomOrder ? Colors.white : AppTheme.primary,
        ),
        tooltip: currentSort.displayName,
      );
    }
  }
}
