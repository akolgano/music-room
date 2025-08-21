import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/music_models.dart';

class AppCardWidgets {
  
  static TextStyle _primaryStyle(BuildContext context) => TextStyle(
    color: Theme.of(context).colorScheme.onSurface, fontSize: kIsWeb ? 16.0 : 16.0.sp, fontWeight: FontWeight.w600
  );
  
  static TextStyle _secondaryStyle(BuildContext context) => TextStyle(
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: kIsWeb ? 14.0 : 14.0.sp
  );

  static Widget sectionTitle(String title) {
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          title,
          style: _primaryStyle(context).copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    });
  }

  static Widget quickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Builder(builder: (context) {
      return Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: _primaryStyle(context).copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  static Widget playlistCard({
    required Playlist playlist,
    VoidCallback? onTap,
    VoidCallback? onPlay,
    VoidCallback? onCreatorTap,
    VoidCallback? onDelete,
    bool showPlayButton = false,
    bool showDeleteButton = false,
    String? currentUsername,
  }) {
    return Builder(builder: (context) {
      return Card(
        child: ListTile(
          leading: Container(
            width: 56,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.library_music),
          ),
          title: Text(playlist.name, style: _primaryStyle(context)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${playlist.tracks.length} tracks', style: _secondaryStyle(context)),
              GestureDetector(
                onTap: onCreatorTap,
                child: Text(
                  'by ${playlist.creator}',
                  style: _secondaryStyle(context).copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showPlayButton && onPlay != null)
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: onPlay,
                  tooltip: 'Play Playlist',
                ),
              if (showDeleteButton && onDelete != null && currentUsername == playlist.creator)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete Playlist',
                ),
            ],
          ),
          onTap: onTap,
        ),
      );
    });
  }
}