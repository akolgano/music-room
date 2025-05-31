// lib/screens/music/components/playlist_tracks_section.dart
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/playlist_track.dart';

class PlaylistTracksSection extends StatelessWidget {
  final List<PlaylistTrack> tracks;
  final bool isWebSocketConnected;
  final Function(PlaylistTrack) onRemoveTrack;
  final Function(int, int) onMoveTrack;
  final VoidCallback onAddTracks;

  const PlaylistTracksSection({
    Key? key,
    required this.tracks,
    required this.isWebSocketConnected,
    required this.onRemoveTrack,
    required this.onMoveTrack,
    required this.onAddTracks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.queue_music, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tracks (${tracks.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (isWebSocketConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sync, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Live',
                          style: TextStyle(color: Colors.green, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (tracks.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 48,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No tracks added yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add some songs to get started!',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: onAddTracks,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Songs'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tracks.length,
                onReorder: onMoveTrack,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  return Card(
                    key: ValueKey(track.trackId),
                    margin: const EdgeInsets.only(bottom: 8),
                    color: AppTheme.surfaceVariant,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        track.name,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Position: ${track.position}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.drag_handle,
                            color: Colors.grey.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => onRemoveTrack(track),
                            tooltip: 'Remove track',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
