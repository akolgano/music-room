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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MusicColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.music_note, size: 12, color: MusicColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'NOW PLAYING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: MusicColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/player');
                },
                icon: const Icon(Icons.expand_less, size: 16, color: Colors.white),
                label: const Text('Full Player', style: TextStyle(fontSize: 10, color: Colors.white)),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      playerService.togglePlay();
                    },
                    icon: Icon(
                      playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 16,
                    ),
                    label: Text(
                      playerService.isPlaying ? 'Pause' : 'Play',
                      style: const TextStyle(fontSize: 10),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MusicColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      playerService.stop();
                    },
                    icon: const Icon(Icons.stop, size: 16, color: Colors.white),
                    label: const Text('Stop', style: TextStyle(fontSize: 10, color: Colors.white)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              _buildProgressBar(playerService),
              const SizedBox(height: 4),
              _buildTimeLabels(playerService),
            ],
          ),
        ],
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: MusicColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MusicColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.music_note, size: 16, color: MusicColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'NOW PLAYING',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: MusicColors.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildTrackImage(track),
            const SizedBox(height: 16),
            Text(
              track.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'by ${track.artist}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (track.album.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'from ${track.album}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
          ],
          _buildProgressBar(playerService),
          const SizedBox(height: 4),
          _buildTimeLabels(playerService),
          const SizedBox(height: 24),
          _buildControls(playerService),
          const SizedBox(height: 16),
          _buildSecondaryControls(),
        ],
      ),
    );
  }

  Widget _buildTrackImage(Track track) {
    if (track.imageUrl != null && track.imageUrl!.isNotEmpty) {
      return Container(
        width: 180,
        height: 180,
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
        width: 180,
        height: 180,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              size: 60,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No Cover Art',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
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
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.shuffle,
                color: Colors.white.withOpacity(0.7),
                size: 24,
              ),
              onPressed: () {
              },
              tooltip: 'Shuffle tracks',
            ),
            Text(
              'Shuffle',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.skip_previous,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () {
              },
              tooltip: 'Previous track',
            ),
            Text(
              'Previous',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
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
                tooltip: playerService.isPlaying ? 'Pause music' : 'Play music',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              playerService.isPlaying ? 'Pause' : 'Play',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.skip_next,
                color: Colors.white,
                size: 32,
              ),
              onPressed: () {
              },
              tooltip: 'Next track',
            ),
            Text(
              'Next',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.repeat,
                color: Colors.white.withOpacity(0.7),
                size: 24,
              ),
              onPressed: () {
              },
              tooltip: 'Repeat mode',
            ),
            Text(
              'Repeat',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton.icon(
          icon: Icon(
            Icons.favorite_border,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          label: Text(
            'Like',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          onPressed: () {
          },
        ),
        TextButton.icon(
          icon: Icon(
            Icons.playlist_add,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          label: Text(
            'Add to Playlist',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          onPressed: () {
          },
        ),
        TextButton.icon(
          icon: Icon(
            Icons.share,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          label: Text(
            'Share',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
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
