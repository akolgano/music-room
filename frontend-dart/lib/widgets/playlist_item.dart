// widgets/playlist_item.dart
import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../screens/music/enhanced_playlist_editor_screen.dart';
import '../config/theme.dart';

class MusicColors {
  static const Color primary = Color(0xFF1DB954);
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF282828);
  static const Color surfaceVariant = Color(0xFF333333);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFB3B3B3);
  static const Color error = Color(0xFFE91429);
}

class PlaylistItem extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onPlay;
  final VoidCallback? onShare;
  
  const PlaylistItem({
    Key? key, 
    required this.playlist, 
    this.onPlay,
    this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: MusicColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => EnhancedPlaylistEditorScreen(playlistId: playlist.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildPlaylistCover(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${playlist.tracks.length} songs • ${playlist.creator}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (playlist.isPublic)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: MusicColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'PUBLIC',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: MusicColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onPlay != null)
                    IconButton(
                      icon: Container(
                        decoration: const BoxDecoration(
                          color: MusicColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                      onPressed: onPlay,
                    ),
                  if (onShare != null)
                    IconButton(
                      icon: const Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 20,
                      ),
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

  Widget _buildPlaylistCover() {
    if (playlist.imageUrl != null && playlist.imageUrl!.isNotEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          image: DecorationImage(
            image: NetworkImage(playlist.imageUrl!),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) {
              print('Error loading image: $exception');
            },
          ),
        ),
      );
    }
    
    final colors = [
      Colors.purple,
      Colors.pink,
      Colors.blue,
      Colors.teal,
      Colors.orange,
      Colors.red,
    ];
    final int colorIndex = playlist.id.hashCode % colors.length;
    final Color coverColor = colors[colorIndex];
    
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            coverColor,
            coverColor.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Icon(
          playlist.tracks.isEmpty ? Icons.playlist_add : Icons.music_note,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}
