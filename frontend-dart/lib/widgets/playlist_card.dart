// lib/widgets/playlist_card.dart
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/playlist.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onShare;

  const PlaylistCard({
    Key? key,
    required this.playlist,
    this.onTap,
    this.onPlay,
    this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildCover(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${playlist.tracks.length} songs • ${playlist.creator}',
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 8),
                    if (playlist.isPublic)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'PUBLIC',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ),
                  ],
                ),
              ),
              if (onPlay != null || onShare != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onPlay != null)
                      IconButton(
                        icon: Container(
                          decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                          padding: const EdgeInsets.all(4.0),
                          child: const Icon(Icons.play_arrow, color: Colors.black, size: 20),
                        ),
                        onPressed: onPlay,
                      ),
                    if (onShare != null)
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.white, size: 20),
                        onPressed: onShare,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    if (playlist.imageUrl != null && playlist.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          playlist.imageUrl!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackCover(),
        ),
      );
    }
    return _buildFallbackCover();
  }

  Widget _buildFallbackCover() {
    final colors = [Colors.purple, Colors.pink, Colors.blue, Colors.teal, Colors.orange, Colors.red];
    final colorIndex = playlist.id.hashCode % colors.length;
    
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors[colorIndex], colors[colorIndex].withOpacity(0.6)],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        playlist.tracks.isEmpty ? Icons.playlist_add : Icons.music_note,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}
