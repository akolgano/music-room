import 'package:flutter/material.dart';
import '../core/theme_core.dart';
import '../models/sort_models.dart';

class SortButton<T> extends StatelessWidget {
  final T currentSort;
  final VoidCallback onPressed;
  final bool showLabel;

  const SortButton({super.key, required this.currentSort, required this.onPressed, this.showLabel = true});

  @override
  Widget build(BuildContext context) {
    final isCustomOrder = (currentSort as dynamic).isDefault ?? false;
    final icon = (currentSort as dynamic).icon ?? Icons.sort;
    final displayName = (currentSort as dynamic).displayName ?? 'Sort';
    
    if (showLabel) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          isCustomOrder ? 'Sort' : displayName,
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
          icon,
          color: isCustomOrder ? Colors.white : AppTheme.primary,
        ),
        tooltip: displayName,
      );
    }
  }
}

class _GenericSortBottomSheet<T> extends StatelessWidget {
  final T currentSort;
  final Function(T) onSortChanged;
  final String title;
  final List<T> options;

  const _GenericSortBottomSheet({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
    required this.title,
    required this.options,
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
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
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
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option == currentSort;
                final icon = (option as dynamic).icon ?? Icons.sort;
                final displayName = (option as dynamic).displayName ?? '';
                
                return ListTile(
                  leading: Icon(
                    icon,
                    color: isSelected ? AppTheme.primary : Colors.white70,
                  ),
                  title: Text(
                    displayName,
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
    return _GenericSortBottomSheet<TrackSortOption>(
      currentSort: currentSort,
      onSortChanged: onSortChanged,
      title: 'Sort Tracks',
      options: TrackSortOption.defaultOptions,
    );
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
    return _GenericSortBottomSheet<PlaylistSortOption>(
      currentSort: currentSort,
      onSortChanged: onSortChanged,
      title: 'Sort Playlists',
      options: PlaylistSortOption.defaultOptions,
    );
  }
}
