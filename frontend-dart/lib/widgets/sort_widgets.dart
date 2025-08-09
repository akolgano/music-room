import 'package:flutter/material.dart';
import '../core/theme_core.dart';
import '../models/sort_models.dart';

class SortButton extends StatelessWidget {
  final TrackSortOption currentSort;
  final VoidCallback onPressed;
  final bool showLabel;

  const SortButton({super.key, required this.currentSort, required this.onPressed, this.showLabel = true});

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

class TrackSortBottomSheet extends StatelessWidget {
  final TrackSortOption currentSort;
  final Function(TrackSortOption) onSortChanged;

  const TrackSortBottomSheet({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                const Icon(Icons.sort, color: AppTheme.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Sort Tracks',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: TrackSortOption.defaultOptions.length,
              itemBuilder: (context, index) {
                final option = TrackSortOption.defaultOptions[index];
                final isSelected = option == currentSort;
                
                return ListTile(
                  leading: Icon(
                    option.icon,
                    color: isSelected ? AppTheme.primary : Colors.white70,
                  ),
                  title: Text(
                    option.displayName,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primary : Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppTheme.primary)
                      : null,
                  onTap: () {
                    onSortChanged(option);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static void show(
    BuildContext context, {
    required TrackSortOption currentSort,
    required Function(TrackSortOption) onSortChanged,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => TrackSortBottomSheet(
        currentSort: currentSort,
        onSortChanged: onSortChanged,
      ),
    );
  }
}

class PlaylistSortButton extends StatelessWidget {
  final PlaylistSortOption currentSort;
  final VoidCallback onPressed;
  final bool showLabel;

  const PlaylistSortButton({super.key, required this.currentSort, required this.onPressed, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    final isCustomOrder = currentSort.field == PlaylistSortField.name && currentSort == PlaylistSortOption.defaultOptions.first;
    
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


class PlaylistSortBottomSheet extends StatelessWidget {
  final PlaylistSortOption currentSort;
  final Function(PlaylistSortOption) onSortChanged;

  const PlaylistSortBottomSheet({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                const Icon(Icons.sort, color: AppTheme.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Sort Playlists',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: PlaylistSortOption.defaultOptions.length,
              itemBuilder: (context, index) {
                final option = PlaylistSortOption.defaultOptions[index];
                final isSelected = option == currentSort;
                
                return ListTile(
                  leading: Icon(
                    option.icon,
                    color: isSelected ? AppTheme.primary : Colors.white70,
                  ),
                  title: Text(
                    option.displayName,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primary : Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppTheme.primary)
                      : null,
                  onTap: () {
                    onSortChanged(option);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static void show(
    BuildContext context, {
    required PlaylistSortOption currentSort,
    required Function(PlaylistSortOption) onSortChanged,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PlaylistSortBottomSheet(
        currentSort: currentSort,
        onSortChanged: onSortChanged,
      ),
    );
  }
}

