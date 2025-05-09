// lib/widgets/track_item.dart
import 'package:flutter/material.dart';
import '../models/track.dart';
import '../config/theme.dart';

class TrackItem extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final bool isSelected;
  final VoidCallback? onPlay;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onSelectionChanged;

  const TrackItem({
    Key? key,
    required this.track,
    this.isPlaying = false,
    this.isSelected = false,
    this.onPlay,
    this.onAdd,
    this.onRemove,
    this.onTap,
    this.onSelectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected ? Colors.blue.withOpacity(0.1) : null,
      child: ListTile(
        leading: _buildLeading(),
        title: Text(track.name),
        subtitle: Text('${track.artist} - ${track.album}'),
        trailing: _buildTrailing(),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLeading() {
    if (track.imageUrl != null && track.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          track.imageUrl!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackImage(),
        ),
      );
    }
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return isSelected
        ? Icon(Icons.check_circle, color: Colors.blue)
        : CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.music_note, color: Colors.grey[700]),
          );
  }

  Widget _buildTrailing() {
    if (onSelectionChanged != null) {
      return Checkbox(
        value: isSelected,
        onChanged: onSelectionChanged,
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onPlay != null)
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: isPlaying ? AppTheme.primary : null,
            ),
            onPressed: onPlay,
          ),
        if (onAdd != null)
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: onAdd,
          ),
        if (onRemove != null)
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: onRemove,
          ),
      ],
    );
  }
}
