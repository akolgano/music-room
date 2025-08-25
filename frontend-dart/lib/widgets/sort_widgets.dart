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
    final s = currentSort as dynamic;
    final isCustom = s.isDefault ?? false;
    final icon = s.icon ?? Icons.sort;
    final name = s.displayName ?? 'Sort';
    
    return showLabel ? ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(isCustom ? 'Sort' : name, style: const TextStyle(fontSize: 14)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCustom ? AppTheme.surface : AppTheme.primary,
        foregroundColor: isCustom ? Colors.white : Colors.black,
        side: BorderSide(color: isCustom ? Colors.white54 : AppTheme.primary),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ) : IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: isCustom ? Colors.white : AppTheme.primary),
      tooltip: name,
    );
  }
}

class _GenericSortBottomSheet<T> extends StatelessWidget {
  final T currentSort;
  final Function(T) onSortChanged;
  final String title;
  final List<T> options;

  const _GenericSortBottomSheet({super.key, required this.currentSort, required this.onSortChanged, required this.title, required this.options});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            const Icon(Icons.sort, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
          ]),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final o = options[index] as dynamic;
              final selected = o == currentSort;
              return ListTile(
                leading: Icon(o.icon ?? Icons.sort, color: selected ? AppTheme.primary : Colors.white70),
                title: Text(o.displayName ?? '', style: TextStyle(
                  color: selected ? AppTheme.primary : Colors.white,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                )),
                trailing: selected ? const Icon(Icons.check, color: AppTheme.primary) : null,
                onTap: () { onSortChanged(o); Navigator.pop(context); },
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}

class TrackSortBottomSheet extends StatelessWidget {
  final TrackSortOption currentSort;
  final Function(TrackSortOption) onSortChanged;
  final bool isEvent;
  
  const TrackSortBottomSheet({
    super.key, 
    required this.currentSort, 
    required this.onSortChanged,
    this.isEvent = false,
  });

  @override
  Widget build(BuildContext context) => _GenericSortBottomSheet<TrackSortOption>(
    currentSort: currentSort, 
    onSortChanged: onSortChanged,
    title: 'Sort Tracks', 
    options: TrackSortOption.getOptionsForPlaylist(isEvent: isEvent),
  );
}

class PlaylistSortBottomSheet extends StatelessWidget {
  final PlaylistSortOption currentSort;
  final Function(PlaylistSortOption) onSortChanged;
  const PlaylistSortBottomSheet({super.key, required this.currentSort, required this.onSortChanged});

  @override
  Widget build(BuildContext context) => _GenericSortBottomSheet<PlaylistSortOption>(
    currentSort: currentSort, onSortChanged: onSortChanged,
    title: 'Sort Playlists', options: PlaylistSortOption.defaultOptions,
  );
}