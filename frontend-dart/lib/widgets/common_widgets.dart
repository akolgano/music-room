// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_core.dart';
import '../services/music_player_service.dart';
import '../providers/dynamic_theme_provider.dart';
import '../models/models.dart';
import 'unified_components.dart';

class CommonWidgets {
  static Widget loading([String? message]) => UnifiedComponents.loading(message);
  
  static Widget emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) => UnifiedComponents.emptyState(
    icon: icon,
    title: title,
    subtitle: subtitle,
    buttonText: buttonText,
    onButtonPressed: onButtonPressed,
  );

  static Widget error({required String message, VoidCallback? onRetry, String? retryText}) =>
      UnifiedComponents.error(message: message, onRetry: onRetry, retryText: retryText);

  static Widget buildInfoBanner({
    required String title,
    required String message,
    required IconData icon,
    Color color = AppTheme.primary,
    VoidCallback? onAction,
    String? actionText,
  }) => UnifiedComponents.infoBanner(
    title: title,
    message: message,
    icon: icon,
    color: color,
    onAction: onAction,
    actionText: actionText,
  );

  static void showSnackBar(BuildContext context, String message, {Color? backgroundColor}) =>
      UnifiedComponents.showSnackBar(context, message, backgroundColor: backgroundColor);

  static Widget loadingWidget([String? message]) => loading(message);
}

class FormComponents {
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
  }) => UnifiedComponents.textField(
    controller: controller,
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    obscureText: obscureText,
    validator: validator,
    onChanged: onChanged,
    minLines: minLines,
    maxLines: maxLines,
  );

  static Widget button({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isOutlined = false,
    bool fullWidth = true,
    Color? backgroundColor,
    Color? foregroundColor,
  }) => isOutlined 
    ? UnifiedComponents.secondaryButton(
        text: text,
        onPressed: onPressed,
        icon: icon,
        fullWidth: fullWidth,
      )
    : UnifiedComponents.primaryButton(
        text: text,
        onPressed: onPressed,
        icon: icon,
        isLoading: isLoading,
        fullWidth: fullWidth,
      );

  static Widget switchTile({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String title,
    String? subtitle,
    IconData? icon,
  }) => UnifiedComponents.switchTile(
    value: value,
    onChanged: onChanged,
    title: title,
    subtitle: subtitle,
    icon: icon,
  );
}

class AppCards {
  static Widget info({
    required String title,
    required String message,
    required IconData icon,
    Color color = AppTheme.primary,
    VoidCallback? onAction,
    String? actionText,
  }) => UnifiedComponents.infoBanner(
    title: title,
    message: message,
    icon: icon,
    color: color,
    onAction: onAction,
    actionText: actionText,
  );

  static Widget playlist({
    required Playlist playlist,
    required VoidCallback? onTap,
    VoidCallback? onPlay,
    bool showPlayButton = false,
  }) => UnifiedComponents.playlistCard(
    playlist: playlist,
    onTap: onTap,
    onPlay: onPlay,
    showPlayButton: showPlayButton,
  );

  static Widget track({
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
  }) => UnifiedComponents.trackCard(
    key: key,
    track: track,
    isSelected: isSelected,
    isInPlaylist: isInPlaylist,
    showAddButton: showAddButton,
    showPlayButton: showPlayButton,
    onTap: onTap,
    onAdd: onAdd,
    onPlay: onPlay,
    onRemove: onRemove,
    onAddToLibrary: onAddToLibrary,
    onSelectionChanged: onSelectionChanged,
  );
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

class StatusIndicator extends StatelessWidget {
  final bool isConnected;
  final String? connectedText;
  final String? disconnectedText;

  const StatusIndicator({
    Key? key,
    required this.isConnected,
    this.connectedText,
    this.disconnectedText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => UnifiedComponents.statusIndicator(
    isConnected: isConnected,
    connectedText: connectedText,
    disconnectedText: disconnectedText,
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
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
  }
}
