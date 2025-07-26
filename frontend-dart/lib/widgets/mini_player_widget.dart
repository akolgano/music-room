import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/music_player_service.dart';
import '../core/theme_utils.dart';
import '../models/music_models.dart';
import '../screens/music/track_detail_screen.dart';

class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    return Consumer<MusicPlayerService>(
      builder: (context, playerService, _) {
        final currentTrack = playerService.currentTrack;
        if (currentTrack == null) return const SizedBox.shrink();

        return Container(
          height: isLandscape ? 60 : 100,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(
              top: BorderSide(
                color: AppTheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildProgressBar(context, playerService),
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToTrackDetail(context, currentTrack),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: isLandscape ? 4 : 8),
                    child: Row(
                      children: [
                      Container(
                        width: isLandscape ? 40 : 56,
                        height: isLandscape ? 40 : 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppTheme.surfaceVariant,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: currentTrack.imageUrl?.isNotEmpty == true
                              ? CachedNetworkImage(
                                  imageUrl: currentTrack.imageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: AppTheme.surfaceVariant,
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: AppTheme.surfaceVariant,
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentTrack.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    currentTrack.artist,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (playerService.isUsingFullAudio) ...[
                                  const Text(
                                    ' • ',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(color: Colors.green.withValues(alpha: 0.5), width: 0.5),
                                    ),
                                    child: const Text(
                                      'FULL AUDIO',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                if (playerService.hasPlaylist) ...[
                                  const Text(
                                    ' • ',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    playerService.currentTrackInfo,
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: isLandscape ? 28 : 32,
                            height: isLandscape ? 28 : 32,
                            decoration: BoxDecoration(
                              color: playerService.hasPreviousTrack 
                                  ? Colors.grey.withValues(alpha: 0.3)
                                  : Colors.grey.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: playerService.hasPreviousTrack 
                                  ? () => playerService.playPrevious()
                                  : null,
                              icon: Icon(
                                Icons.skip_previous,
                                color: playerService.hasPreviousTrack 
                                    ? Colors.white 
                                    : Colors.grey,
                                size: 16,
                              ),
                              padding: EdgeInsets.zero,
                              tooltip: 'Previous track',
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          Container(
                            width: isLandscape ? 36 : 40,
                            height: isLandscape ? 36 : 40,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () => playerService.togglePlay(),
                              icon: Icon(
                                playerService.isPlaying 
                                    ? Icons.pause 
                                    : Icons.play_arrow,
                                color: Colors.black,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              tooltip: playerService.isPlaying ? 'Pause' : 'Play',
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          Container(
                            width: isLandscape ? 28 : 32,
                            height: isLandscape ? 28 : 32,
                            decoration: BoxDecoration(
                              color: playerService.hasNextTrack 
                                  ? Colors.grey.withValues(alpha: 0.3)
                                  : Colors.grey.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: playerService.hasNextTrack 
                                  ? () => playerService.playNext()
                                  : null,
                              icon: Icon(
                                Icons.skip_next,
                                color: playerService.hasNextTrack 
                                    ? Colors.white 
                                    : Colors.grey,
                                size: 16,
                              ),
                              padding: EdgeInsets.zero,
                              tooltip: 'Next track',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      
                      Container(
                        width: isLandscape ? 28 : 32,
                        height: isLandscape ? 28 : 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => playerService.stop(),
                          icon: const Icon(Icons.close, color: Colors.white, size: 16),
                          padding: EdgeInsets.zero,
                          tooltip: 'Stop',
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(BuildContext context, MusicPlayerService playerService) {
    final duration = playerService.duration;
    final position = playerService.position;
    
    if (duration.inSeconds == 0) {
      return Container(
        height: 3,
        color: AppTheme.primary.withValues(alpha: 0.2),
      );
    }

    return SizedBox(
      height: 3,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
          activeTrackColor: AppTheme.primary,
          inactiveTrackColor: AppTheme.primary.withValues(alpha: 0.2),
        ),
        child: Slider(
          value: position.inSeconds.toDouble(),
          max: duration.inSeconds.toDouble(),
          onChanged: (value) => playerService.seek(Duration(seconds: value.toInt())),
        ),
      ),
    );
  }

  void _navigateToTrackDetail(BuildContext context, Track? track) {
    if (track == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackDetailScreen(track: track),
      ),
    );
  }
}
