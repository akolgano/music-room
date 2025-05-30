// lib/widgets/music_player_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/music_player_service.dart';
import '../models/track.dart';

class MusicColors {
  static const Color primary = Color(0xFF1DB954);
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF282828);
  static const Color surfaceVariant = Color(0xFF333333);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFB3B3B3);
  static const Color error = Color(0xFFE91429);
}

class MusicPlayerWidget extends StatelessWidget {
  final bool showTrackInfo;
  final bool mini;

  const MusicPlayerWidget({
    Key? key,
    this.showTrackInfo = true,
    this.mini = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<MusicPlayerService>(context);
    final track = playerService.currentTrack;

    if (track == null) {
      return const SizedBox.shrink();
    }

    return mini ? _buildMiniPlayer(context, playerService, track) : _buildFullPlayer(context, playerService, track);
  }

  Widget _buildMiniPlayer(BuildContext context, MusicPlayerService playerService, Track track) {
    return Container(
      color: MusicColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: MusicColors.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(
            Icons.music_note,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          track.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          track.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: () {
                playerService.togglePlay();
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
              ),
              onPressed: () {
                playerService.stop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullPlayer(BuildContext context, MusicPlayerService playerService, Track track) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTrackInfo) ...[
            _buildTrackImage(track),
            const SizedBox(height: 16),
            Text(
              track.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${track.artist} • ${track.album}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
          _buildProgressBar(playerService),
          const SizedBox(height: 4),
          _buildTimeLabels(playerService),
          const SizedBox(height: 24),
          _buildControls(playerService),
        ],
      ),
    );
  }

  Widget _buildTrackImage(Track track) {
    if (track.imageUrl != null && track.imageUrl!.isNotEmpty) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          image: DecorationImage(
            image: NetworkImage(track.imageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: MusicColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.music_note,
          size: 80,
          color: Colors.white.withOpacity(0.5),
        ),
      );
    }
  }

  Widget _buildProgressBar(MusicPlayerService playerService) {
    return SliderTheme(
      data: const SliderThemeData(
        trackHeight: 4.0,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 12.0),
        trackShape: RoundedRectSliderTrackShape(),
      ),
      child: Slider(
        value: playerService.position.inMilliseconds.toDouble().clamp(
              0.0,
              math.max(playerService.duration.inMilliseconds.toDouble(), 1.0),
            ),
        max: math.max(playerService.duration.inMilliseconds.toDouble(), 1.0),       
        min: 0,
        onChanged: (value) {
          playerService.seekTo(Duration(milliseconds: value.round()));
        },
        activeColor: MusicColors.primary,
        inactiveColor: Colors.white.withOpacity(0.3),
      ),
    );
  }

  Widget _buildTimeLabels(MusicPlayerService playerService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatDuration(playerService.position),
            style: TextStyle(
              fontSize: 12, 
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            _formatDuration(playerService.duration),
            style: TextStyle(
              fontSize: 12, 
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(MusicPlayerService playerService) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle,
            color: Colors.white.withOpacity(0.7),
            size: 24,
          ),
          onPressed: () {
          },
        ),
        IconButton(
          icon: Icon(
            Icons.skip_previous,
            color: Colors.white,
            size: 32,
          ),
          onPressed: () {
          },
        ),
        const SizedBox(width: 8),
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              playerService.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.black,
              size: 32,
            ),
            onPressed: () {
              playerService.togglePlay();
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(
            Icons.skip_next,
            color: Colors.white,
            size: 32,
          ),
          onPressed: () {
          },
        ),
        IconButton(
          icon: Icon(
            Icons.repeat,
            color: Colors.white.withOpacity(0.7),
            size: 24,
          ),
          onPressed: () {
          },
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
