import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/player_services.dart';
import '../core/theme_core.dart';
import '../core/responsive_core.dart';
import '../screens/music/detail_music.dart';

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
          height: MusicAppResponsive.isSmallScreen(context) 
            ? (isLandscape ? 45 : 60) 
            : (isLandscape ? 50 : 80),
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
                blurRadius: MusicAppResponsive.isSmallScreen(context) ? 4 : 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              playerService.duration.inSeconds == 0
                ? Container(
                    height: 2,
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  )
                : SizedBox(
                    height: 2,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                        activeTrackColor: AppTheme.primary,
                        inactiveTrackColor: AppTheme.primary.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: playerService.position.inSeconds.toDouble(),
                        max: playerService.duration.inSeconds.toDouble(),
                        onChanged: (value) => playerService.seek(Duration(seconds: value.toInt())),
                      ),
                    ),
                  ),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrackDetailScreen(track: currentTrack),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ThemeUtils.getResponsivePadding(context) * 2, 
                      vertical: MusicAppResponsive.isSmallScreen(context) 
                        ? (isLandscape ? 2 : 4) 
                        : (isLandscape ? 4 : 8)
                    ),
                    child: Row(
                      children: [
                      Container(
                        width: MusicAppResponsive.isSmallScreen(context) 
                          ? (isLandscape ? 32 : 40) 
                          : (isLandscape ? 40 : 56),
                        height: MusicAppResponsive.isSmallScreen(context) 
                          ? (isLandscape ? 24 : 32) 
                          : (isLandscape ? 32 : 48),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(ThemeUtils.getResponsiveBorderRadius(context)),
                          color: AppTheme.surfaceVariant,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(ThemeUtils.getResponsiveBorderRadius(context)),
                          child: currentTrack.imageUrl?.isNotEmpty == true
                              ? CachedNetworkImage(
                                  imageUrl: currentTrack.imageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: AppTheme.surfaceVariant,
                                    child: Icon(
                                      Icons.music_note,
                                      color: Colors.white,
                                      size: ThemeUtils.getResponsiveIconSize(context),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: AppTheme.surfaceVariant,
                                    child: Icon(
                                      Icons.music_note,
                                      color: Colors.white,
                                      size: ThemeUtils.getResponsiveIconSize(context),
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: ThemeUtils.getResponsiveIconSize(context),
                                ),
                        ),
                      ),
                      SizedBox(width: ThemeUtils.getResponsivePadding(context)),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentTrack.name,
                              style: ThemeUtils.getBodyStyle(context).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    currentTrack.artist,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      height: 1.0,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(color: Colors.green.withValues(alpha: 0.5), width: 0.5),
                                    ),
                                    child: const Text(
                                      'FULL',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        height: 1.0,
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
                                    playerService.currentTrack == null ? '' : '${playerService.currentIndex + 1} of ${playerService.playlist.length}',
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
                            height: isLandscape ? 24 : 28,
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
                            height: isLandscape ? 30 : 34,
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
                            height: isLandscape ? 24 : 28,
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
                        height: isLandscape ? 24 : 28,
                        decoration: BoxDecoration(
                          color: playerService.playbackSpeed != 1.0 
                              ? Colors.blue.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            final speeds = [1.0, 1.25, 1.5, 2.0, 0.75];
                            final currentIndex = speeds.indexOf(playerService.playbackSpeed);
                            final nextIndex = (currentIndex + 1) % speeds.length;
                            playerService.setPlaybackSpeed(speeds[nextIndex]);
                          },
                          icon: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.speed,
                                color: playerService.playbackSpeed != 1.0 
                                    ? Colors.blue 
                                    : Colors.white,
                                size: 14,
                              ),
                              if (playerService.playbackSpeed != 1.0)
                                Positioned(
                                  bottom: -2,
                                  child: Text(
                                    '${playerService.playbackSpeed}x',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 6,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          padding: EdgeInsets.zero,
                          tooltip: 'Speed: ${playerService.playbackSpeed}x',
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      Container(
                        width: isLandscape ? 28 : 32,
                        height: isLandscape ? 24 : 28,
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

}
