// screens/music/player_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/music_player_service.dart';
import '../../models/track.dart';

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
      appBar: AppBar(
        title: const Text('Now Playing'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade700,
              Colors.indigo.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAlbumArt(),
                _buildTrackInfo(track),
                _buildProgressBar(playerService),
                _buildControls(playerService),
                _buildVolumeControl(playerService),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt() {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.music_note,
          size: 120,
          color: Colors.indigo.shade300,
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
            color: Colors.white.withOpacity(0.8),
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          track.album,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressBar(MusicPlayerService playerService) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
            thumbColor: Colors.white,
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            overlayColor: Colors.white.withOpacity(0.2),
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(playerService.position),
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
              Text(
                _formatDuration(playerService.duration),
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(MusicPlayerService playerService) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10, color: Colors.white, size: 36),
          onPressed: () {
            final newPosition = playerService.position - const Duration(seconds: 10);
            playerService.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
          },
        ),
        const SizedBox(width: 32),
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.white,
          child: IconButton(
            icon: Icon(
              playerService.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.indigo,
              size: 42,
            ),
            onPressed: () {
              playerService.togglePlay();
            },
          ),
        ),
        const SizedBox(width: 32),
        IconButton(
          icon: const Icon(Icons.forward_10, color: Colors.white, size: 36),
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

  Widget _buildVolumeControl(MusicPlayerService playerService) {
    return Row(
      children: [
        const Icon(Icons.volume_down, color: Colors.white),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              thumbColor: Colors.white,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              overlayColor: Colors.white.withOpacity(0.2),
            ),
            child: Slider(
              value: 1.0,
              max: 1.0,
              min: 0.0,
              onChanged: (value) {
                playerService.audioPlayer.setVolume(value);
              },
            ),
          ),
        ),
        const Icon(Icons.volume_up, color: Colors.white),
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
