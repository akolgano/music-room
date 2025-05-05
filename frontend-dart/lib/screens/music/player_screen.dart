// screens/music/player_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/music_player_service.dart';
import '../../models/track.dart';

class MusicColors {
  static const Color primary = Color(0xFF1DB954);
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF282828);
  static const Color surfaceVariant = Color(0xFF333333);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFB3B3B3);
  static const Color error = Color(0xFFE91429);
}

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<MusicPlayerService>(context);
    final track = playerService.currentTrack;

    if (track == null) {
      Navigator.of(context).pop();
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: MusicColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Text(
              'NOW PLAYING',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
                color: MusicColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              _buildAlbumArt(),
              const Spacer(flex: 1),
              _buildTrackInfo(track),
              const Spacer(flex: 1),
              _buildProgressBar(playerService),
              const SizedBox(height: 8),
              _buildTimeLabels(playerService),
              const SizedBox(height: 24),
              _buildControls(playerService),
              const Spacer(flex: 1),
              _buildAdditionalControls(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt() {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        color: MusicColors.surfaceVariant,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.music_note,
          size: 120,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildTrackInfo(Track track) {
    return Column(
      children: [
        Text(
          track.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          track.artist,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressBar(MusicPlayerService playerService) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
        thumbColor: Colors.white,
        activeTrackColor: MusicColors.primary,
        inactiveTrackColor: Colors.white.withOpacity(0.3),
        overlayColor: MusicColors.primary.withOpacity(0.2),
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
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            _formatDuration(playerService.duration),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
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
            size: 36,
          ),
          onPressed: () {
          },
        ),
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              playerService.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.black,
              size: 36,
            ),
            onPressed: () {
              playerService.togglePlay();
            },
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.skip_next,
            color: Colors.white,
            size: 36,
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

  Widget _buildAdditionalControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            Icons.devices,
            color: Colors.white.withOpacity(0.7),
            size: 24,
          ),
          onPressed: () {
          },
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.favorite_border,
                color: Colors.white.withOpacity(0.7),
                size: 24,
              ),
              onPressed: () {
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.playlist_add,
                color: Colors.white.withOpacity(0.7),
                size: 24,
              ),
              onPressed: () {
              },
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            Icons.share,
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
