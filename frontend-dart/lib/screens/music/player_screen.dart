// lib/screens/music/player_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/music_player_service.dart';
import '../../models/track.dart';
import '../../core/theme.dart';
import '../../core/dimensions.dart';
import '../../core/ui_constants.dart';
import '../../core/app_strings.dart';
import '../../core/ui_tooltips.dart'; 

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<MusicPlayerService>(context);
    final track = playerService.currentTrack;

    if (track == null) {
      return const Scaffold(backgroundColor: AppTheme.background, body: Center(child: Text("No track selected.", style: TextStyle(color: Colors.white))));
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: UITooltips.minimizePlayer, 
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppStrings.nowPlaying,
              style: TextStyle(
                fontSize: AppDimensions.textSmall,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
            tooltip: 'More options',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              _buildAlbumArt(context, track),
              const Spacer(flex: 1),
              _buildTrackInfo(track),
              const Spacer(flex: 1),
              _buildProgressSection(playerService),
              SizedBox(height: AppDimensions.paddingLarge),
              _buildControls(playerService),
              const Spacer(flex: 1),
              _buildAdditionalControls(),
              SizedBox(height: AppDimensions.paddingLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt(BuildContext context, Track track) {
    return Container(
      width: UIConstants.albumArtFullSize,
      height: UIConstants.albumArtFullSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: AppTheme.defaultShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: track.imageUrl != null && track.imageUrl!.isNotEmpty
            ? Image.network(
                track.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultAlbumArt(),
              )
            : _buildDefaultAlbumArt(),
      ),
    );
  }

  Widget _buildDefaultAlbumArt() {
    return Container(
      color: AppTheme.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.music_note,
          size: UIConstants.albumArtFullSize * 0.4,
          color: Colors.white.withOpacity(UIConstants.disabledOpacity),
        ),
      ),
    );
  }

  Widget _buildTrackInfo(Track track) {
    return Column(
      children: [
        Text(
          track.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: AppDimensions.textTitle,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: AppDimensions.paddingSmall),
        Text(
          track.artist,
          style: TextStyle(
            color: Colors.white.withOpacity(UIConstants.subtleOpacity),
            fontSize: AppDimensions.textMedium,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (track.album.isNotEmpty) ...[
          SizedBox(height: AppDimensions.paddingXSmall),
          Text(
            track.album,
            style: TextStyle(
              color: Colors.white.withOpacity(UIConstants.disabledOpacity),
              fontSize: AppDimensions.textSmall,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildProgressSection(MusicPlayerService playerService) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3.0,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: AppDimensions.paddingXSmall,
            ),
            thumbColor: Colors.white,
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: Colors.white.withOpacity(UIConstants.subtleOpacity),
            overlayColor: AppTheme.primary.withOpacity(UIConstants.lightShadowOpacity), 
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
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(playerService.position),
                style: TextStyle(
                  color: Colors.white.withOpacity(UIConstants.subtleOpacity),
                  fontSize: AppDimensions.textSmall,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatDuration(playerService.duration),
                style: TextStyle(
                  color: Colors.white.withOpacity(UIConstants.subtleOpacity),
                  fontSize: AppDimensions.textSmall,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(MusicPlayerService playerService) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle,
            color: Colors.white.withOpacity(UIConstants.subtleOpacity),
            size: AppDimensions.iconMedium,
          ),
          onPressed: () {
          },
          tooltip: UITooltips.toggleShuffle, 
        ),
        IconButton(
          icon: Icon(
            Icons.skip_previous,
            color: Colors.white,
            size: AppDimensions.iconLarge,
          ),
          onPressed: () {
          },
          tooltip: 'Previous track',
        ),
        Container(
          width: UIConstants.playButtonSize,
          height: UIConstants.playButtonSize,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              playerService.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.black,
              size: AppDimensions.iconLarge,
            ),
            onPressed: () {
              playerService.togglePlay();
            },
            tooltip: playerService.isPlaying 
                ? UITooltips.pauseTrack 
                : UITooltips.playTrack, 
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.skip_next,
            color: Colors.white,
            size: AppDimensions.iconLarge,
          ),
          onPressed: () {
          },
          tooltip: 'Next track',
        ),
        IconButton(
          icon: Icon(
            Icons.repeat,
            color: Colors.white.withOpacity(UIConstants.subtleOpacity),
            size: AppDimensions.iconMedium,
          ),
          onPressed: () {
          },
          tooltip: UITooltips.toggleRepeat, 
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
            color: Colors.white.withOpacity(UIConstants.subtleOpacity),
            size: AppDimensions.iconMedium,
          ),
          onPressed: () {
          },
          tooltip: 'Select playback device',
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.favorite_border,
                color: Colors.white.withOpacity(UIConstants.subtleOpacity),
                size: AppDimensions.iconMedium,
              ),
              onPressed: () {
              },
              tooltip: 'Add to favorites',
            ),
            SizedBox(width: AppDimensions.paddingSmall),
            IconButton(
              icon: Icon(
                Icons.playlist_add,
                color: Colors.white.withOpacity(UIConstants.subtleOpacity),
                size: AppDimensions.iconMedium,
              ),
              onPressed: () {
              },
              tooltip: UITooltips.addToPlaylist, 
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            Icons.share,
            color: Colors.white.withOpacity(UIConstants.subtleOpacity),
            size: AppDimensions.iconMedium,
          ),
          onPressed: () {
          },
          tooltip: 'Share track',
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
