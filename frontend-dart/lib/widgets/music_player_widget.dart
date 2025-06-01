// lib/widgets/music_player_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/music_player_service.dart';
import '../core/theme.dart';

class MusicPlayerWidget extends StatelessWidget {
  final bool mini;
  final bool showTrackInfo;

  const MusicPlayerWidget({
    Key? key,
    this.mini = false,
    this.showTrackInfo = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicPlayerService>(
      builder: (context, playerService, child) {
        final track = playerService.currentTrack;
        
        if (track == null) {
          return const SizedBox.shrink();
        }

        if (mini) {
          return Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    image: track.imageUrl != null && track.imageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(track.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: track.imageUrl == null || track.imageUrl!.isEmpty
                      ? const Icon(Icons.music_note, color: Colors.white)
                      : null,
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          track.artist,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                
                IconButton(
                  icon: Icon(
                    playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: playerService.togglePlay,
                ),
                
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: playerService.stop,
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showTrackInfo) ...[
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        image: track.imageUrl != null && track.imageUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(track.imageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: track.imageUrl == null || track.imageUrl!.isEmpty
                          ? const Icon(Icons.music_note, color: Colors.white, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track.artist,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    iconSize: 32,
                    onPressed: () {},
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                      ),
                      iconSize: 32,
                      onPressed: playerService.togglePlay,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    iconSize: 32,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
