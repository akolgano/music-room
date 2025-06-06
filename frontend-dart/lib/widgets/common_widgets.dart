// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_core.dart';
import '../models/models.dart';
import '../services/music_player_service.dart';

class CommonStyles {
  static const titleStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white);
  static const subtitleStyle = TextStyle(color: Colors.grey);
  static const bodyStyle = TextStyle(color: Colors.white);
  
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppTheme.surface,
    borderRadius: BorderRadius.circular(12),
  );
  
  static BoxDecoration get primaryCardDecoration => BoxDecoration(
    color: AppTheme.primary.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
  );
}

class CommonWidgets {
  static Widget loadingWidget([String? message]) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppTheme.primary),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(message, style: CommonStyles.bodyStyle),
        ],
      ],
    ),
  );

  static Widget emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.white.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(title, style: CommonStyles.titleStyle),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: CommonStyles.subtitleStyle, textAlign: TextAlign.center),
          ],
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onButtonPressed, child: Text(buttonText)),
          ],
        ],
      ),
    ),
  );

  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommonWidgets.loadingWidget(message);
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommonWidgets.emptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
    );
  }
}

void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  CommonWidgets.showSnackBar(context, message, isError: isError);
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.validator,
    this.maxLines = 1,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      maxLines: maxLines,
      onChanged: onChanged,
      style: CommonStyles.bodyStyle,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey) : null,
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const AppButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading 
        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
        : Icon(icon ?? Icons.check, size: 16),
      label: Text(text),
      style: AppTheme.fullWidthButtonStyle,
    );
  }
}

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap, onPlay, onShare;

  const PlaylistCard({Key? key, required this.playlist, this.onTap, this.onPlay, this.onShare}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surface,
      child: ListTile(
        onTap: onTap,
        leading: _buildLeading(),
        title: Text(playlist.name, style: CommonStyles.bodyStyle),
        subtitle: Text('${playlist.tracks.length} tracks', style: CommonStyles.subtitleStyle),
        trailing: _buildTrailing(),
      ),
    );
  }

  Widget _buildLeading() => Container(
    width: 50, height: 50,
    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
    child: const Icon(Icons.library_music, color: Colors.black),
  );

  Widget _buildTrailing() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (onPlay != null) IconButton(icon: const Icon(Icons.play_arrow), onPressed: onPlay),
      if (onShare != null) IconButton(icon: const Icon(Icons.share), onPressed: onShare),
    ],
  );
}

class TrackCard extends StatelessWidget {
  final Track track;
  final bool isSelected;
  final VoidCallback? onTap, onAdd, onPlay;
  final ValueChanged<bool?>? onSelectionChanged;
  final bool showImage;

  const TrackCard({
    Key? key,
    required this.track,
    this.isSelected = false,
    this.onTap, this.onAdd, this.onPlay, this.onSelectionChanged,
    this.showImage = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicPlayerService>(
      builder: (context, playerService, _) {
        final isCurrentTrack = playerService.currentTrack?.id == track.id;
        final trackIsPlaying = isCurrentTrack && playerService.isPlaying;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _buildLeading(trackIsPlaying),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTrackInfo(trackIsPlaying)),
                  _buildTrailing(trackIsPlaying),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeading(bool trackIsPlaying) {
    if (onSelectionChanged != null) {
      return Checkbox(value: isSelected, onChanged: onSelectionChanged, activeColor: AppTheme.primary);
    }
    return _buildAlbumArt(trackIsPlaying);
  }

  Widget _buildAlbumArt(bool trackIsPlaying) {
    Widget content = track.imageUrl?.isNotEmpty == true && showImage
        ? Image.network(track.imageUrl!, width: 50, height: 50, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _defaultArt())
        : _defaultArt();

    if (trackIsPlaying) {
      content = Stack(children: [
        content,
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.equalizer, color: Colors.black, size: 24),
        ),
      ]);
    }

    return ClipRRect(borderRadius: BorderRadius.circular(8), child: content);
  }

  Widget _defaultArt() => Container(
    width: 50, height: 50,
    decoration: BoxDecoration(color: AppTheme.surfaceVariant, borderRadius: BorderRadius.circular(8)),
    child: const Icon(Icons.music_note, color: Colors.white, size: 24),
  );

  Widget _buildTrackInfo(bool trackIsPlaying) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(track.name, style: CommonStyles.bodyStyle.copyWith(
        fontWeight: FontWeight.w600,
        decoration: trackIsPlaying ? TextDecoration.underline : null
      ), maxLines: 2, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 4),
      Text(track.artist, style: CommonStyles.subtitleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
      if (track.album.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(track.album, style: CommonStyles.subtitleStyle.copyWith(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    ],
  );

  Widget _buildTrailing(bool trackIsPlaying) {
    List<Widget> actions = [];
    
    if (onPlay != null) {
      actions.add(IconButton(
        icon: Icon(trackIsPlaying ? Icons.pause : Icons.play_arrow, color: AppTheme.primary, size: 24),
        onPressed: onPlay,
      ));
    }
    
    if (onAdd != null) {
      actions.add(IconButton(
        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
        onPressed: onAdd,
      ));
    }

    return actions.length == 1 ? actions.first : 
           actions.isEmpty ? const SizedBox(width: 8) :
           Row(mainAxisSize: MainAxisSize.min, children: actions);
  }
}

class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicPlayerService>(
      builder: (context, playerService, _) {
        final track = playerService.currentTrack;
        if (track == null) return const SizedBox.shrink();

        return Container(
          height: 64,
          decoration: BoxDecoration(color: AppTheme.surface, boxShadow: AppTheme.lightShadow),
          child: Row(
            children: [
              _buildAlbumArt(track),
              Expanded(child: _buildTrackInfo(track)),
              IconButton(
                onPressed: playerService.togglePlay,
                icon: Icon(playerService.isPlaying ? Icons.pause : Icons.play_arrow, color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlbumArt(Track track) => Container(
    width: 64, height: 64,
    color: AppTheme.surfaceVariant,
    child: track.imageUrl?.isNotEmpty == true
        ? Image.network(track.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _defaultIcon())
        : _defaultIcon(),
  );

  Widget _defaultIcon() => const Icon(Icons.music_note, color: Colors.white);

  Widget _buildTrackInfo(Track track) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(track.name, style: CommonStyles.bodyStyle.copyWith(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(track.artist, style: CommonStyles.subtitleStyle.copyWith(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}
