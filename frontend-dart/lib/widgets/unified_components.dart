// lib/widgets/unified_components.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/app_core.dart';
import '../models/models.dart';
import '../services/music_player_service.dart';
import '../providers/dynamic_theme_provider.dart';

class UnifiedComponents {
  static Widget loading([String? message]) => Center(
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
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
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

  static Widget error({required String message, VoidCallback? onRetry, String? retryText}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: Text(retryText ?? 'Retry')),
          ],
        ],
      ),
    ),
  );

  static Widget errorBanner({
    required String message, 
    String? title,
    VoidCallback? onDismiss,
    Color color = Colors.red,
  }) => Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) 
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(message, style: TextStyle(color: color, fontSize: 14)),
            ],
          ),
        ),
        if (onDismiss != null)
          IconButton(
            icon: Icon(Icons.close, color: color, size: 20),
            onPressed: onDismiss,
          ),
      ],
    ),
  );

  static Widget standardCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? color,
  }) => Container(
    padding: padding ?? const EdgeInsets.all(16),
    margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: color ?? AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );

  static Widget headerCard({required Widget child}) => Container(
    padding: const EdgeInsets.all(24),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primary.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  static Widget formCard({
    required Widget child,
    String? title,
    IconData? titleIcon,
  }) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    color: AppTheme.surface,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(titleIcon, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    ),
  );

  static Widget textField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    bool obscureText = false,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    int minLines = 1,
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    obscureText: obscureText,
    validator: validator,
    onChanged: onChanged,
    minLines: minLines,
    maxLines: maxLines,
    style: const TextStyle(color: Colors.white),
    decoration: AppTheme.getInputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
    ),
  );

  static Widget primaryButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
  }) {
    final child = isLoading 
      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
      : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, size: 16),
            if (icon != null) const SizedBox(width: 8),
            Text(text),
          ],
        );

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
      ),
      child: child,
    );

    return fullWidth ? SizedBox(width: double.infinity, height: 50, child: button) : button;
  }

  static Widget secondaryButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool fullWidth = true,
  }) {
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primary,
        side: const BorderSide(color: AppTheme.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 16),
          if (icon != null) const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, height: 50, child: button) : button;
  }

  static Widget infoBanner({
    required String title,
    required String message,
    required IconData icon,
    Color color = AppTheme.primary,
    VoidCallback? onAction,
    String? actionText,
  }) => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
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
              Text(message, style: TextStyle(color: color.withOpacity(0.8), fontSize: 14)),
            ],
          ),
        ),
        if (onAction != null && actionText != null)
          TextButton(onPressed: onAction, child: Text(actionText, style: TextStyle(color: color))),
      ],
    ),
  );

  static Widget successBanner({required String message}) => infoBanner(
    title: 'Success',
    message: message,
    icon: Icons.check_circle,
    color: Colors.green,
  );

  static Widget playlistCard({
    required Playlist playlist,
    required VoidCallback? onTap,
    VoidCallback? onPlay,
    VoidCallback? onShare,
    bool showPlayButton = false,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    color: AppTheme.surface,
    child: ListTile(
      leading: _buildPlaylistImage(playlist),
      title: Text(playlist.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${playlist.tracks.length} tracks', style: const TextStyle(color: Colors.grey)),
          Text('By ${playlist.creator}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
      trailing: showPlayButton && onPlay != null
          ? IconButton(icon: const Icon(Icons.play_circle_outline, color: AppTheme.primary), onPressed: onPlay)
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    ),
  );

  static Widget _buildPlaylistImage(Playlist playlist) => Container(
    width: 56, height: 56,
    decoration: BoxDecoration(
      color: AppTheme.primary.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: playlist.imageUrl?.isNotEmpty == true
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(playlist.imageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.library_music, color: AppTheme.primary)),
          )
        : const Icon(Icons.library_music, color: AppTheme.primary),
  );

  static Widget trackCard({
    Key? key, 
    required Track track,
    bool isSelected = false,
    bool isInPlaylist = false,
    bool showAddButton = true,
    bool showPlayButton = true,
    VoidCallback? onTap,
    VoidCallback? onAdd,
    VoidCallback? onPlay,
    VoidCallback? onRemove,
    VoidCallback? onAddToLibrary,
    ValueChanged<bool?>? onSelectionChanged,
  }) => Consumer2<MusicPlayerService, DynamicThemeProvider>(
    key: key, 
    builder: (context, playerService, themeProvider, _) {
      final isCurrentTrack = playerService.currentTrack?.id == track.id;
      final trackIsPlaying = isCurrentTrack && playerService.isPlaying;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: _getTrackCardColor(isSelected, isCurrentTrack, isInPlaylist, themeProvider),
          borderRadius: BorderRadius.circular(12),
          border: _getTrackCardBorder(isCurrentTrack, isInPlaylist, themeProvider),
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
                    _buildTrackImage(track, trackIsPlaying, themeProvider),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTrackInfo(track, trackIsPlaying, themeProvider, isInPlaylist)),
                  _buildTrackActions(showAddButton, showPlayButton, onAdd, onPlay, onRemove, onAddToLibrary, isInPlaylist, trackIsPlaying, themeProvider),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  static Widget _buildTrackImage(Track track, bool trackIsPlaying, DynamicThemeProvider themeProvider) {
    Widget content = Container(
      width: 56, height: 56,
      decoration: BoxDecoration(color: themeProvider.surfaceColor, borderRadius: BorderRadius.circular(8)),
      child: track.imageUrl?.isNotEmpty == true
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: track.imageUrl!, width: 56, height: 56, fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white, size: 28),
              ),
            )
          : const Icon(Icons.music_note, color: Colors.white, size: 28),
    );

    if (trackIsPlaying) {
      content = Stack(
        children: [
          content,
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.equalizer, color: Colors.white, size: 28),
          ),
        ],
      );
    }
    return content;
  }

  static Widget _buildTrackInfo(Track track, bool trackIsPlaying, DynamicThemeProvider themeProvider, bool isInPlaylist) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              track.name,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                decoration: trackIsPlaying ? TextDecoration.underline : null,
                decorationColor: themeProvider.primaryColor,
              ),
              maxLines: 2, 
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isInPlaylist) ...[
            const SizedBox(width: 2),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 10),
            ),
          ],
        ],
      ),
      const SizedBox(height: 4),
      Text(track.artist, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
      if (track.album.isNotEmpty) Text(track.album, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
    ],
  );

  static Widget _buildTrackActions(bool showAddButton, bool showPlayButton, VoidCallback? onAdd, VoidCallback? onPlay, VoidCallback? onRemove, VoidCallback? onAddToLibrary, bool isInPlaylist, bool trackIsPlaying, DynamicThemeProvider themeProvider) {
    List<Widget> actions = [];

    if (showPlayButton && onPlay != null) {
      actions.add(
        Container(
          decoration: BoxDecoration(color: themeProvider.primaryColor.withOpacity(trackIsPlaying ? 1.0 : 0.8), borderRadius: BorderRadius.circular(20)),
          child: IconButton(
            icon: Icon(trackIsPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 18), 
            onPressed: onPlay,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32), 
          ),
        ),
      );
    }

    if (showAddButton && onAdd != null && !isInPlaylist) {
      actions.add(IconButton(
        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20), 
        onPressed: onAdd,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32), 
      ));
    }

    if (onAddToLibrary != null) {
      actions.add(IconButton(
        icon: const Icon(Icons.library_add, color: Colors.blue, size: 20), 
        onPressed: onAddToLibrary,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32), 
      ));
    }

    if (onRemove != null) {
      actions.add(IconButton(
        icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20), 
        onPressed: onRemove,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32), 
      ));
    }

    if (actions.length <= 1) {
      return actions.isNotEmpty ? actions.first : const SizedBox.shrink();
    } else {
      return Wrap(
        spacing: 4, 
        children: actions,
      );
    }
  }

  static Color _getTrackCardColor(bool isSelected, bool isCurrentTrack, bool isInPlaylist, DynamicThemeProvider themeProvider) {
    if (isSelected) return themeProvider.primaryColor.withOpacity(0.2);
    if (isCurrentTrack) return themeProvider.primaryColor.withOpacity(0.1);
    if (isInPlaylist) return Colors.green.withOpacity(0.05);
    return themeProvider.surfaceColor;
  }

  static Border? _getTrackCardBorder(bool isCurrentTrack, bool isInPlaylist, DynamicThemeProvider themeProvider) {
    if (isCurrentTrack) return Border.all(color: themeProvider.primaryColor, width: 2);
    if (isInPlaylist) return Border.all(color: Colors.green.withOpacity(0.3), width: 1);
    return null;
  }

  static void showSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Widget statusIndicator({
    required bool isConnected,
    String? connectedText,
    String? disconnectedText,
  }) => Row(
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
        isConnected ? (connectedText ?? 'Connected') : (disconnectedText ?? 'Disconnected'),
        style: TextStyle(
          color: isConnected ? Colors.green : Colors.red,
          fontSize: 12,
        ),
      ),
    ],
  );

  static Widget sectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );

  static Widget quickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) => Card(
    color: AppTheme.surface,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
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

  static Widget featureCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    color: AppTheme.surface,
    child: ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: Text(description, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    ),
  );

  static Widget settingsSection({
    required String title,
    required List<Widget> items,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      sectionTitle(title),
      Card(
        color: AppTheme.surface,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(children: items),
      ),
    ],
  );

  static Widget settingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final itemColor = color ?? Colors.white;
    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(title, style: TextStyle(color: itemColor, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  static Widget switchTile({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String title,
    String? subtitle,
    IconData? icon,
  }) => SwitchListTile(
    value: value,
    onChanged: onChanged,
    title: Text(title, style: const TextStyle(color: Colors.white)),
    subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey)) : null,
    secondary: icon != null ? Icon(icon, color: AppTheme.primary) : null,
    activeColor: AppTheme.primary,
    contentPadding: EdgeInsets.zero,
  );
}
