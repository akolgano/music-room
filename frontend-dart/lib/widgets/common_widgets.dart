// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/app_core.dart';
import '../models/models.dart';
import '../services/music_player_service.dart';
import '../providers/dynamic_theme_provider.dart';

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
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color ?? AppTheme.primary,
        ),
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  final EdgeInsets? padding;
  
  const SettingsSection({
    Key? key, 
    required this.title, 
    required this.items,
    this.padding,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        Card(
          color: AppTheme.surface,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1) 
                    const Divider(height: 1, color: AppTheme.surfaceVariant, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
        SizedBox(height: padding?.bottom ?? 16),
      ],
    );
  }
}

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;
  final Widget? trailing;
  
  const SettingsItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
    this.trailing,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? Colors.white;
    final iconColor = color ?? AppTheme.primary;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: TextStyle(color: itemColor, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: itemColor.withOpacity(0.7), fontSize: 12)),
      trailing: trailing ?? Icon(Icons.chevron_right, color: itemColor.withOpacity(0.5)),
      onTap: onTap,
    );
  }
}

class StatusIndicator extends StatelessWidget {
  final bool isConnected;
  final String connectedText;
  final String disconnectedText;
  final bool animated;
  
  const StatusIndicator({
    Key? key,
    required this.isConnected,
    this.connectedText = 'Live',
    this.disconnectedText = 'Offline',
    this.animated = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isConnected ? Colors.green : Colors.grey).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: isConnected ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isConnected ? connectedText : disconnectedText,
            style: TextStyle(
              color: isConnected ? Colors.green : Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
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
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
  final Color? iconColor;
  
  const FeatureCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.iconColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: (iconColor ?? AppTheme.primary).withOpacity(0.1),
                child: Icon(icon, color: iconColor ?? AppTheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
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
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
          if (onAction != null && actionText != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionText!, style: TextStyle(color: color, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) => CommonWidgets.loadingWidget(message);
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
  Widget build(BuildContext context) => CommonWidgets.emptyState(
    icon: icon,
    title: title,
    subtitle: subtitle,
    buttonText: buttonText,
    onButtonPressed: onButtonPressed,
  );
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
            title: Text(playlist.name, style: CommonStyles.bodyStyle),
            subtitle: Text('${playlist.tracks.length} tracks', style: CommonStyles.subtitleStyle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onPlay != null) IconButton(
                  icon: Icon(Icons.play_arrow, color: themeProvider.primaryColor),
                  onPressed: onPlay,
                ),
                if (onShare != null) IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: onShare,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TrackCard extends StatelessWidget {
  final Track track;
  final bool isSelected;
  final VoidCallback? onTap, onAdd, onPlay, onAddToLibrary;
  final ValueChanged<bool?>? onSelectionChanged;
  final bool showImage;

  const TrackCard({
    Key? key,
    required this.track,
    this.isSelected = false,
    this.onTap, this.onAdd, this.onPlay, this.onAddToLibrary, this.onSelectionChanged,
    this.showImage = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<MusicPlayerService, DynamicThemeProvider>(
      builder: (context, playerService, themeProvider, _) {
        final isCurrentTrack = playerService.currentTrack?.id == track.id;
        final trackIsPlaying = isCurrentTrack && playerService.isPlaying;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected 
                ? themeProvider.primaryColor.withOpacity(0.1) 
                : themeProvider.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: isCurrentTrack ? Border.all(
              color: themeProvider.primaryColor,
              width: 2,
            ) : null,
            boxShadow: isCurrentTrack ? [
              BoxShadow(
                color: themeProvider.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
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
                    _buildLeading(trackIsPlaying, themeProvider),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTrackInfo(trackIsPlaying, themeProvider)),
                    _buildTrailing(trackIsPlaying, themeProvider),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeading(bool trackIsPlaying, DynamicThemeProvider themeProvider) {
    if (onSelectionChanged != null) {
      return Checkbox(
        value: isSelected,
        onChanged: onSelectionChanged,
        activeColor: themeProvider.primaryColor,
      );
    }
    return _buildAlbumArt(trackIsPlaying, themeProvider);
  }

  Widget _buildAlbumArt(bool trackIsPlaying, DynamicThemeProvider themeProvider) {
    Widget content;
    
    if (track.imageUrl?.isNotEmpty == true && showImage) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: track.imageUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: themeProvider.surfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
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
            width: 56,
            height: 56,
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

  Widget _defaultArt(DynamicThemeProvider themeProvider) => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: themeProvider.surfaceColor,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.music_note, color: Colors.white, size: 28),
  );

  Widget _buildTrackInfo(bool trackIsPlaying, DynamicThemeProvider themeProvider) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
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
      if (track.album.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(
          track.album,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ],
  );

  Widget _buildTrailing(bool trackIsPlaying, DynamicThemeProvider themeProvider) {
    List<Widget> actions = [];
    
    if (onPlay != null) {
      actions.add(Container(
        decoration: BoxDecoration(
          color: themeProvider.primaryColor.withOpacity(trackIsPlaying ? 1.0 : 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: IconButton(
          icon: Icon(
            trackIsPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 20,
          ),
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
}

class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<MusicPlayerService, DynamicThemeProvider>(
      builder: (context, playerService, themeProvider, _) {
        final track = playerService.currentTrack;
        if (track == null) return const SizedBox.shrink();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeProvider.surfaceColor,
                themeProvider.primaryColor.withOpacity(0.1),
              ],
            ),
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
                width: 80,
                height: 80,
                child: ClipRRect(
                  child: track.imageUrl?.isNotEmpty == true
                      ? CachedNetworkImage(
                          imageUrl: track.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: themeProvider.surfaceColor,
                            child: const Icon(Icons.music_note, color: Colors.white, size: 32),
                          ),
                        )
                      : Container(
                          color: themeProvider.surfaceColor,
                          child: const Icon(Icons.music_note, color: Colors.white, size: 32),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        track.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
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
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.primaryColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: playerService.togglePlay,
                  icon: Icon(
                    playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
