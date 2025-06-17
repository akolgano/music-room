// lib/widgets/app_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/consolidated_core.dart';
import '../models/models.dart';
import '../services/music_player_service.dart';
import '../providers/dynamic_theme_provider.dart';

class AppWidgets {
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
    decoration: AppTheme.getInputDecoration(labelText: labelText, hintText: hintText, prefixIcon: prefixIcon),
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

    final button = ElevatedButton(onPressed: isLoading ? null : onPressed, child: child);
    return fullWidth ? SizedBox(width: double.infinity, height: 50, child: button) : button;
  }

  static Widget secondaryButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool fullWidth = true,
  }) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) Icon(icon, size: 16),
        if (icon != null) const SizedBox(width: 8),
        Text(text),
      ],
    );

    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: child,
    );
    
    return fullWidth ? SizedBox(width: double.infinity, height: 50, child: button) : button;
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
  );

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
          const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: Text(retryText ?? 'Retry')),
          ],
        ],
      ),
    ),
  );

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

  static Widget errorBanner({
    required String message,
    VoidCallback? onDismiss,
  }) => Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.red.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: const TextStyle(color: Colors.red, fontSize: 14)),
        ),
        if (onDismiss != null)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
            onPressed: onDismiss,
          ),
      ],
    ),
  );

  static Widget successBanner({required String message}) => Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.green.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.green.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: const TextStyle(color: Colors.green, fontSize: 14)),
        ),
      ],
    ),
  );

  static Widget formCard({
    required String title,
    IconData? titleIcon,
    required Widget child,
  }) => Card(
    color: AppTheme.surface,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          child,
        ],
      ),
    ),
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

  static Widget settingsSection({
    required String title,
    required List<Widget> items,
  }) => Card(
    color: AppTheme.surface,
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...items,
        ],
      ),
    ),
  );

  static Widget settingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color color = Colors.white,
  }) => ListTile(
    leading: Icon(icon, color: color),
    title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
    subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    onTap: onTap,
  );

  static Widget playlistCard({
    required Playlist playlist,
    required VoidCallback? onTap,
    VoidCallback? onPlay,
    bool showPlayButton = false,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    color: AppTheme.surface,
    child: ListTile(
      leading: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
        child: playlist.imageUrl?.isNotEmpty == true
            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(playlist.imageUrl!, fit: BoxFit.cover))
            : const Icon(Icons.library_music, color: AppTheme.primary),
      ),
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
          color: isSelected ? themeProvider.primaryColor.withOpacity(0.2) : 
                 isCurrentTrack ? themeProvider.primaryColor.withOpacity(0.1) : 
                 themeProvider.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: isCurrentTrack ? Border.all(color: themeProvider.primaryColor, width: 2) : null,
        ),
        child: ListTile(
          leading: onSelectionChanged != null
              ? Checkbox(value: isSelected, onChanged: onSelectionChanged, activeColor: themeProvider.primaryColor)
              : Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: themeProvider.surfaceColor, borderRadius: BorderRadius.circular(8)),
                  child: track.imageUrl?.isNotEmpty == true
                      ? ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: track.imageUrl!, fit: BoxFit.cover))
                      : const Icon(Icons.music_note, color: Colors.white, size: 28),
                ),
          title: Text(track.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
          subtitle: Text(track.artist, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
          trailing: _buildTrackActions(showAddButton, showPlayButton, onAdd, onPlay, onRemove, trackIsPlaying, themeProvider),
          onTap: onTap,
        ),
      );
    },
  );

  static Widget _buildTrackActions(bool showAddButton, bool showPlayButton, VoidCallback? onAdd, VoidCallback? onPlay, VoidCallback? onRemove, bool trackIsPlaying, DynamicThemeProvider themeProvider) {
    List<Widget> actions = [];

    if (showPlayButton && onPlay != null) {
      actions.add(IconButton(
        icon: Icon(trackIsPlaying ? Icons.pause : Icons.play_arrow, color: themeProvider.primaryColor, size: 24), 
        onPressed: onPlay,
      ));
    }

    if (showAddButton && onAdd != null) {
      actions.add(IconButton(
        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20), 
        onPressed: onAdd,
      ));
    }

    if (onRemove != null) {
      actions.add(IconButton(
        icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20), 
        onPressed: onRemove,
      ));
    }

    return actions.isNotEmpty ? Wrap(spacing: 4, children: actions) : const SizedBox.shrink();
  }

  static Widget statusIndicator({
    required bool isConnected,
    String? connectedText,
    String? disconnectedText,
  }) {
    final color = isConnected ? Colors.green : Colors.red;
    final text = isConnected ? (connectedText ?? 'Connected') : (disconnectedText ?? 'Disconnected');
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  static Widget quickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
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
            Icon(icon, color: color, size: 32),
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
    VoidCallback? onTap,
  }) => Card(
    color: AppTheme.surface,
    margin: const EdgeInsets.only(bottom: 12),
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

  static void showSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor ?? AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  static Widget tabScaffold({
    required List<Tab> tabs,
    required List<Widget> tabViews,
    TabController? controller,
  }) => DefaultTabController(
    length: tabs.length,
    child: Column(
      children: [
        TabBar(controller: controller, labelColor: AppTheme.primary, unselectedLabelColor: Colors.grey, tabs: tabs),
        Expanded(child: TabBarView(controller: controller, children: tabViews)),
      ],
    ),
  );

  static Widget refreshableList<T>({
    required List<T> items,
    required Widget Function(T, int) itemBuilder,
    required Future<void> Function() onRefresh,
    Widget? emptyState,
    EdgeInsets? padding,
  }) {
    if (items.isEmpty && emptyState != null) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: 600, child: emptyState),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: padding ?? const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) => itemBuilder(items[index], index),
      ),
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
