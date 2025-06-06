// lib/widgets/app_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_core.dart';
import '../models/models.dart';
import '../services/music_player_service.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: const TextStyle(color: Colors.white)),
          ],
        ],
      ),
    );
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            ],
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onButtonPressed, child: Text(buttonText!)),
            ],
          ],
        ),
      ),
    );
  }
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
      style: const TextStyle(color: Colors.white),
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
  final bool isSecondary;
  final IconData? icon;

  const AppButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isSecondary) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading 
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon ?? Icons.check),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white),
          minimumSize: const Size(double.infinity, 50),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading 
        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
        : Icon(icon ?? Icons.check, size: 16),
      label: Text(text),
      style: AppTheme.fullWidthButtonStyle,
    );
  }
}

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onShare;

  const PlaylistCard({Key? key, required this.playlist, this.onTap, this.onPlay, this.onShare}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surface,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primary, 
            borderRadius: BorderRadius.circular(8)
          ),
          child: const Icon(Icons.library_music, color: Colors.black),
        ),
        title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
        subtitle: Text('${playlist.tracks.length} tracks', style: const TextStyle(color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onPlay != null) IconButton(icon: const Icon(Icons.play_arrow), onPressed: onPlay),
            if (onShare != null) IconButton(icon: const Icon(Icons.share), onPressed: onShare),
          ],
        ),
      ),
    );
  }
}

class TrackCard extends StatelessWidget {
  final Track track;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final VoidCallback? onPlay;
  final ValueChanged<bool?>? onSelectionChanged;
  final bool showImage;

  const TrackCard({
    Key? key,
    required this.track,
    this.isSelected = false,
    this.onTap,
    this.onAdd,
    this.onPlay,
    this.onSelectionChanged,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            decoration: trackIsPlaying ? TextDecoration.underline : null
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          track.artist,
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (track.album.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            track.album,
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
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
      return Checkbox(
        value: isSelected,
        onChanged: onSelectionChanged,
        activeColor: AppTheme.primary,
      );
    }

    if (showImage && track.imageUrl != null && track.imageUrl!.isNotEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Image.network(
                track.imageUrl!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultAlbumArt(),
              ),
              if (trackIsPlaying)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.equalizer, color: Colors.black, size: 24),
                ),
            ],
          ),
        ),
      );
    }

    return _buildDefaultAlbumArt();
  }

  Widget _buildDefaultAlbumArt() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note, color: Colors.white, size: 24),
    );
  }

  Widget _buildTrailing(bool trackIsPlaying) {
    List<Widget> actions = [];

    if (onPlay != null) {
      actions.add(IconButton(
        icon: Icon(
          trackIsPlaying ? Icons.pause : Icons.play_arrow,
          color: AppTheme.primary,
          size: 24,
        ),
        onPressed: onPlay,
        tooltip: trackIsPlaying ? 'Pause' : 'Play Preview',
      ));
    }

    if (onAdd != null) {
      actions.add(IconButton(
        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
        onPressed: onAdd,
        tooltip: 'Add to Playlist',
      ));
    }

    if (actions.isEmpty) return const SizedBox(width: 8);
    if (actions.length == 1) return actions.first;

    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }
}

class SnackBarUtils {
  static void showSuccess(BuildContext context, String message) =>
      _showSnackBar(context, message, backgroundColor: Colors.green);
  
  static void showError(BuildContext context, String message) =>
      _showSnackBar(context, message, backgroundColor: AppTheme.error);
  
  static void showInfo(BuildContext context, String message) =>
      _showSnackBar(context, message, backgroundColor: Colors.blue);

  static void _showSnackBar(BuildContext context, String message, {required Color backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppTheme.error : Colors.green,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class DialogUtils {
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = AppStrings.confirm,
    String cancelText = AppStrings.cancel,
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: isDangerous
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  static Future<String?> showTextInputDialog(
    BuildContext context, {
    required String title,
    String? initialValue,
    String? hintText,
    bool obscureText = false,
  }) {
    final controller = TextEditingController(text: initialValue);
    
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.white),
          obscureText: obscureText,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }
}

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
      builder: (context, playerService, _) {
        final track = playerService.currentTrack;
        if (track == null) return const SizedBox.shrink();

        if (mini) {
          return Container(
            height: AppDimens.miniPlayerHeight,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: AppTheme.lightShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: AppDimens.miniPlayerHeight,
                  height: AppDimens.miniPlayerHeight,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                  ),
                  child: track.imageUrl != null && track.imageUrl!.isNotEmpty
                      ? Image.network(
                          track.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.music_note, color: Colors.white),
                        )
                      : const Icon(Icons.music_note, color: Colors.white),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          track.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.artist,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
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
                  onPressed: playerService.togglePlay,
                  icon: Icon(
                    playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
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
                      ),
                      child: track.imageUrl != null && track.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                track.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                    const Icon(Icons.music_note, color: Colors.white),
                              ),
                            )
                          : const Icon(Icons.music_note, color: Colors.white),
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
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track.artist,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
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
                const SizedBox(height: 16),
              ],

              Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      thumbColor: AppTheme.primary,
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: Colors.grey,
                    ),
                    child: Slider(
                      value: playerService.position.inMilliseconds.toDouble().clamp(
                        0.0,
                        playerService.duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                      ),
                      max: playerService.duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                      onChanged: (value) {
                        playerService.seekTo(Duration(milliseconds: value.round()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(playerService.position),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _formatDuration(playerService.duration),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {}, 
                    icon: const Icon(Icons.skip_previous, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: playerService.togglePlay,
                      icon: Icon(
                        playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {}, 
                    icon: const Icon(Icons.skip_next, color: Colors.white, size: 32),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
