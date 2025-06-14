// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/app_core.dart';
import '../models/models.dart';
import '../services/music_player_service.dart';
import '../providers/dynamic_theme_provider.dart';

class CommonWidgets {
  static Widget loadingWidget([String? message]) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppTheme.primary),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white)),
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
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          ],
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onButtonPressed, child: Text(buttonText)),
          ],
        ],
      ),
    ),
  );

  static Widget errorState({
    required String message,
    VoidCallback? onRetry,
    String? retryText,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryText ?? 'Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
            ),
          ],
        ],
      ),
    ),
  );

  static Widget buildInfoBanner({
    required String title,
    required String message,
    required IconData icon,
    Color color = AppTheme.primary,
    VoidCallback? onAction,
    String? actionText,
  }) {
    return InfoBanner(
      title: title,
      message: message,
      icon: icon,
      color: color,
      onAction: onAction,
      actionText: actionText,
    );
  }

  static Widget buildTrackCard({
    required Track track,
    bool isSelected = false,
    VoidCallback? onTap,
    VoidCallback? onAdd,
    VoidCallback? onPlay,
    VoidCallback? onAddToLibrary,
    ValueChanged<bool?>? onSelectionChanged,
    bool showImage = true,
  }) {
    return Consumer2<MusicPlayerService, DynamicThemeProvider>(
      builder: (context, playerService, themeProvider, _) {
        final isCurrentTrack = playerService.currentTrack?.id == track.id;
        final trackIsPlaying = isCurrentTrack && playerService.isPlaying;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? themeProvider.primaryColor.withOpacity(0.1) : themeProvider.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: isCurrentTrack ? Border.all(color: themeProvider.primaryColor, width: 2) : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (onSelectionChanged != null)
                      Checkbox(value: isSelected, onChanged: onSelectionChanged, activeColor: themeProvider.primaryColor)
                    else
                      _buildAlbumArt(track, trackIsPlaying, themeProvider, showImage),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTrackInfo(track, trackIsPlaying, themeProvider)),
                    _buildTrackActions(onPlay, onAdd, onAddToLibrary, trackIsPlaying, themeProvider),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildAlbumArt(Track track, bool trackIsPlaying, DynamicThemeProvider themeProvider, bool showImage) {
    Widget content;
    if (track.imageUrl?.isNotEmpty == true && showImage) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: track.imageUrl!,
          width: 56, height: 56,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: themeProvider.surfaceColor, borderRadius: BorderRadius.circular(8)),
            child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          ),
          errorWidget: (context, url, error) => _defaultArt(themeProvider),
        ),
      );
    } else {
      content = _defaultArt(themeProvider);
    }

    if (trackIsPlaying) {
      content = Stack(
        children: [
          content,
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: themeProvider.primaryColor.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.equalizer, color: Colors.white, size: 28),
          ),
        ],
      );
    }
    return content;
  }

  static Widget _defaultArt(DynamicThemeProvider themeProvider) => Container(
    width: 56, height: 56,
    decoration: BoxDecoration(color: themeProvider.surfaceColor, borderRadius: BorderRadius.circular(8)),
    child: const Icon(Icons.music_note, color: Colors.white, size: 28),
  );

  static Widget _buildTrackInfo(Track track, bool trackIsPlaying, DynamicThemeProvider themeProvider) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        track.name,
        style: TextStyle(
          color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16,
          decoration: trackIsPlaying ? TextDecoration.underline : null,
          decorationColor: themeProvider.primaryColor,
        ),
        maxLines: 2, overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 4),
      Text(track.artist, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
      if (track.album.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(track.album, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    ],
  );

  static Widget _buildTrackActions(
    VoidCallback? onPlay, VoidCallback? onAdd, VoidCallback? onAddToLibrary,
    bool trackIsPlaying, DynamicThemeProvider themeProvider,
  ) {
    List<Widget> actions = [];
    
    if (onPlay != null) {
      actions.add(Container(
        decoration: BoxDecoration(color: themeProvider.primaryColor.withOpacity(trackIsPlaying ? 1.0 : 0.8), borderRadius: BorderRadius.circular(20)),
        child: IconButton(
          icon: Icon(trackIsPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 20),
          onPressed: onPlay,
          tooltip: trackIsPlaying ? 'Pause Preview' : 'Play Preview',
        ),
      ));
    }
    
    if (onAdd != null) {
      actions.add(IconButton(
        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
        onPressed: onAdd,
        tooltip: 'Add to Playlist',
      ));
    }

    if (onAddToLibrary != null) {
      actions.add(IconButton(
        icon: Icon(Icons.library_add, color: themeProvider.primaryColor, size: 24),
        onPressed: onAddToLibrary,
        tooltip: 'Add to Library',
      ));
    }

    return actions.length == 1 ? actions.first : 
           actions.isEmpty ? const SizedBox(width: 8) :
           Row(mainAxisSize: MainAxisSize.min, children: actions);
  }

  static Widget buildPlaylistCard({
    required Playlist playlist,
    VoidCallback? onTap,
    VoidCallback? onPlay,
    VoidCallback? onShare,
    bool showPlayButton = true,
  }) {
    return Consumer<DynamicThemeProvider>(
      builder: (context, themeProvider, _) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: themeProvider.surfaceColor,
          child: ListTile(
            onTap: onTap,
            leading: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: themeProvider.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.library_music, color: Colors.white),
            ),
            title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text('${playlist.tracks.length} tracks', style: const TextStyle(color: Colors.grey)),
            trailing: showPlayButton && onPlay != null 
              ? IconButton(
                  icon: Icon(Icons.play_arrow, color: themeProvider.primaryColor),
                  onPressed: onPlay,
                )
              : null,
          ),
        );
      },
    );
  }

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

class ErrorBanner extends StatelessWidget {
  final String message;
  final Color color;

  const ErrorBanner({
    Key? key,
    required this.message,
    this.color = AppTheme.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const SettingsSection({
    Key? key,
    required this.title,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...items,
          ],
        ),
      ),
    );
  }
}

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color color;

  const SettingsItem({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.color = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: subtitle != null 
        ? Text(subtitle!, style: const TextStyle(color: Colors.grey))
        : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class StatusIndicator extends StatelessWidget {
  final bool isConnected;
  final String connectedText;
  final String disconnectedText;

  const StatusIndicator({
    Key? key,
    required this.isConnected,
    this.connectedText = 'Connected',
    this.disconnectedText = 'Disconnected',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isConnected ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          isConnected ? connectedText : disconnectedText,
          style: TextStyle(
            color: isConnected ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<MusicPlayerService, DynamicThemeProvider>(
      builder: (context, playerService, themeProvider, _) {
        final track = playerService.currentTrack;
        if (track == null) return const SizedBox.shrink();

        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: themeProvider.surfaceColor,
            boxShadow: [
              BoxShadow(
                color: themeProvider.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                child: track.imageUrl?.isNotEmpty == true
                    ? Image.network(track.imageUrl!, fit: BoxFit.cover)
                    : Container(color: themeProvider.surfaceColor, child: const Icon(Icons.music_note, color: Colors.white)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(track.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(track.artist, style: const TextStyle(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: playerService.togglePlay,
                icon: Icon(playerService.isPlaying ? Icons.pause : Icons.play_arrow, color: themeProvider.primaryColor),
              ),
            ],
          ),
        );
      },
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
  final int minLines;      
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
    this.minLines = 1,
    this.maxLines = 1,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      minLines: maxLines,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: AppTheme.getInputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;
  final bool isOutlined;

  const AppButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
    this.isOutlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(icon ?? Icons.check, size: 16),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primary,
          side: const BorderSide(color: AppTheme.primary),
          minimumSize: fullWidth ? const Size(double.infinity, 50) : const Size(88, 50),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(icon ?? Icons.check, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        minimumSize: fullWidth ? const Size(double.infinity, 50) : const Size(88, 50),
      ),
    );
  }
}

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onShare;
  final bool showPlayButton;

  const PlaylistCard({
    Key? key,
    required this.playlist,
    this.onTap,
    this.onPlay,
    this.onShare,
    this.showPlayButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommonWidgets.buildPlaylistCard(
      playlist: playlist,
      onTap: onTap,
      onPlay: onPlay,
      onShare: onShare,
      showPlayButton: showPlayButton,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Color? color;
  
  const SectionTitle(this.title, {Key? key, this.color}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color ?? AppTheme.primary),
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickActionCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const FeatureCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.surface,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text(description, style: const TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onAction;
  final String? actionText;

  const InfoBanner({
    Key? key,
    required this.title,
    required this.message,
    required this.icon,
    this.color = AppTheme.primary,
    this.onAction,
    this.actionText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
          if (onAction != null && actionText != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionText!, style: TextStyle(color: color)),
            ),
        ],
      ),
    );
  }
}
