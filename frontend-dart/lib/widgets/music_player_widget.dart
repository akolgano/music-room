// widgets/music_player_widget.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/music_player_service.dart';
import '../models/track.dart';

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

    return Card(
      margin: EdgeInsets.zero,
      child: mini ? _buildMiniPlayer(context, playerService, track) : _buildFullPlayer(context, playerService, track),
    );
  }

  Widget _buildMiniPlayer(BuildContext context, MusicPlayerService playerService, Track track) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.indigo.withOpacity(0.2),
        child: Icon(
          playerService.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.indigo,
        ),
      ),
      title: Text(
        track.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          playerService.stop();
        },
      ),
      onTap: () {
        playerService.togglePlay();
      },
    );
  }

  Widget _buildFullPlayer(BuildContext context, MusicPlayerService playerService, Track track) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTrackInfo) ...[
            Text(
              track.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${track.artist} - ${track.album}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          _buildProgressBar(playerService),
          const SizedBox(height: 8),
          _buildTimeLabels(playerService),
          const SizedBox(height: 16),
          _buildControls(playerService),
        ],
      ),
    );
  }

  Widget _buildProgressBar(MusicPlayerService playerService) {
    return SliderTheme(
      data: const SliderThemeData(
        trackHeight: 4.0,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0),
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
        activeColor: Colors.indigo,
        inactiveColor: Colors.grey[300],
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
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            _formatDuration(playerService.duration),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
          icon: const Icon(Icons.replay_10),
          onPressed: () {
            final newPosition = playerService.position - const Duration(seconds: 10);
            playerService.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
          },
        ),
        const SizedBox(width: 16),
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.indigo,
          child: IconButton(
            icon: Icon(
              playerService.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              playerService.togglePlay();
            },
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.forward_10),
          onPressed: () {
            final newPosition = playerService.position + const Duration(seconds: 10);
            playerService.seekTo(
              newPosition > playerService.duration ? playerService.duration : newPosition,
            );
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
