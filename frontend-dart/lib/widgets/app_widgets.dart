// lib/widgets/app_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:responsive_framework/responsive_framework.dart';
import 'mini_player_widget.dart';
import '../core/core.dart';
import '../core/responsive_helper.dart'; 
import '../models/models.dart';
import '../services/music_player_service.dart';
import '../providers/dynamic_theme_provider.dart';
import '../widgets/voting_widgets.dart';
import '../models/voting_models.dart';

export 'mini_player_widget.dart';

class AppWidgets {
  static ColorScheme _getColorScheme(BuildContext context) => Theme.of(context).colorScheme;
  static Color _getPrimary(BuildContext context) => _getColorScheme(context).primary;
  static Color _getSurface(BuildContext context) => _getColorScheme(context).surface;
  static Color _getBackground(BuildContext context) => _getColorScheme(context).background;
  static Color _getOnSurface(BuildContext context) => _getColorScheme(context).onSurface;
  static Color _getError(BuildContext context) => _getColorScheme(context).error;

  static TextStyle _primaryStyle(BuildContext context) => TextStyle(
    color: _getOnSurface(context), 
    fontSize: ResponsiveHelper.fontSize(context, 16), fontWeight: FontWeight.w600
  );

  static TextStyle _secondaryStyle(BuildContext context) => TextStyle(
    color: _getOnSurface(context).withOpacity(0.7), 
    fontSize: ResponsiveHelper.fontSize(context, 14)
  );

  static TextStyle _greyStyle(BuildContext context) => TextStyle(
    color: _getOnSurface(context).withOpacity(0.5), 
    fontSize: ResponsiveHelper.fontSize(context, 12)
  );

  static Widget textField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    bool obscureText = false,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    int minLines = 1, int maxLines = 1
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      minLines: minLines,
      maxLines: maxLines,
      style: _primaryStyle(context),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: _getPrimary(context)) : null,
        filled: true,
        fillColor: _getSurface(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _getPrimary(context), width: 2),
        ),
        labelStyle: TextStyle(fontSize: 16, color: _getOnSurface(context).withOpacity(0.7)),
        hintStyle: TextStyle(fontSize: 14, color: _getOnSurface(context).withOpacity(0.5)),
        contentPadding: ResponsiveHelper.symmetricPadding(context, horizontal: 16, vertical: 12),
      ),
    );
  }

  static Widget trackCard({
    Key? key,
    required BuildContext context,
    required Track track,
    bool isSelected = false,
    bool isInPlaylist = false,
    bool showAddButton = true,
    bool showPlayButton = true,
    bool showVotingControls = false,
    String? playlistContext,
    String? playlistId,
    VoidCallback? onTap,
    VoidCallback? onAdd,
    VoidCallback? onPlay,
    VoidCallback? onRemove,
    VoidCallback? onAddToLibrary,
    ValueChanged<bool?>? onSelectionChanged,
  }) => Consumer2<MusicPlayerService, DynamicThemeProvider>(
    key: key,
    builder: (context, playerService, themeProvider, _) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final isCurrentTrack = playerService.currentTrack?.id == track.id;
      final trackIsPlaying = isCurrentTrack && playerService.isPlaying;

      String displayArtist = track.artist;
      if (displayArtist.isEmpty && track.deezerTrackId != null) {
        displayArtist = 'Loading artist info...';
      } else if (displayArtist.isEmpty) {
        displayArtist = 'Unknown Artist';
      }

      return AnimationConfiguration.staggeredList(
        position: 0,
        duration: const Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 50.0,
          child: FadeInAnimation(
            child: Container(
              margin: ResponsiveHelper.symmetricPadding(context, horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary.withOpacity(0.2) : 
                       isCurrentTrack ? colorScheme.primary.withOpacity(0.1) : 
                       colorScheme.surface,
                borderRadius: BorderRadius.circular(ResponsiveHelper.borderRadius(context, 12)),
                border: isCurrentTrack ? Border.all(color: colorScheme.primary, width: 2) : null,
              ),
              child: Padding(
                padding: ResponsiveHelper.padding(context, 12),
                child: Row(
                  children: [
                    if (onSelectionChanged != null)
                      SizedBox(
                        width: 56,
                        child: Checkbox(
                          value: isSelected, 
                          onChanged: onSelectionChanged, 
                          activeColor: colorScheme.primary
                        ),
                      )
                    else
                      _buildImage(context, track.imageUrl, 56, colorScheme.surface, Icons.music_note),
                    SizedBox(width: ResponsiveHelper.spacing(context, 12)),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  track.name, 
                                  style: _primaryStyle(context), 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis
                                ),
                                Text(
                                  displayArtist, 
                                  style: _secondaryStyle(context), 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis
                                ),
                              ],
                            ),
                          ),
                          if (showVotingControls && playlistId != null)
                            Flexible(
                              flex: 1,
                              child: Padding(
                                padding: EdgeInsets.only(right: ResponsiveHelper.spacing(context, 8)),
                                child: TrackVotingControls(
                                  playlistId: playlistId!,
                                  trackId: track.id,
                                  isCompact: true,
                                ),
                              ),
                            ),
                          if (onSelectionChanged == null)
                            Flexible(
                              flex: 1,
                              child: _buildTrackActions(
                                context, 
                                showAddButton, 
                                showPlayButton, 
                                onAdd, 
                                onPlay, 
                                onRemove, 
                                trackIsPlaying, 
                                isInPlaylist
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  static Widget _buildImage(BuildContext context, String? imageUrl, double size, Color backgroundColor, IconData defaultIcon) {
    return Container(
      width: ResponsiveHelper.spacing(context, size), 
      height: ResponsiveHelper.spacing(context, size),
      decoration: BoxDecoration(
        color: backgroundColor, 
        borderRadius: BorderRadius.circular(ResponsiveHelper.borderRadius(context, 8))
      ),
      child: imageUrl?.isNotEmpty == true
          ? ClipRRect(
              borderRadius: BorderRadius.circular(ResponsiveHelper.borderRadius(context, 8)), 
              child: CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover)
            )
          : Icon(
              defaultIcon, 
              color: _getOnSurface(context), 
              size: ResponsiveHelper.iconSize(context, size * 0.5)
            ),
    );
  }

  static Widget _buildTrackActions(
    BuildContext context,
    bool showAddButton, 
    bool showPlayButton, 
    VoidCallback? onAdd, 
    VoidCallback? onPlay, 
    VoidCallback? onRemove, 
    bool trackIsPlaying, 
    bool isInPlaylist
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final actions = <Widget>[];

    if (showPlayButton && onPlay != null) {
      actions.add(IconButton(
        icon: Icon(
          trackIsPlaying ? Icons.pause : Icons.play_arrow, 
          color: colorScheme.primary, 
          size: ResponsiveHelper.iconSize(context, 20) 
        ), 
        onPressed: onPlay,
        padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 4)), 
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32), 
      ));
    }

    if (showAddButton && onAdd != null && !isInPlaylist) {
      actions.add(IconButton(
        icon: Icon(
          Icons.add_circle_outline, 
          color: colorScheme.onSurface, 
          size: ResponsiveHelper.iconSize(context, 18) 
        ), 
        onPressed: onAdd, 
        tooltip: 'Add to Playlist',
        padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 4)), 
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32), 
      ));
    }

    if (isInPlaylist) {
      actions.add(Padding(
        padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 4)),
        child: Icon(
          Icons.check_circle, 
          color: Colors.green, 
          size: ResponsiveHelper.iconSize(context, 18) 
        ),
      ));
    }

    if (onRemove != null) {
      actions.add(IconButton(
        icon: Icon(
          Icons.remove_circle_outline, 
          color: colorScheme.error, 
          size: ResponsiveHelper.iconSize(context, 18) 
        ), 
        onPressed: onRemove,
        padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 4)), 
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32), 
      ));
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions.length > 2 
        ? actions.take(2).toList() 
        : actions,
    );
  }

  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool isDangerous = false,
    String confirmText = 'Confirm', 
    String cancelText = 'Cancel',
  }) async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text(title, style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(message, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDangerous ? theme.colorScheme.error : theme.colorScheme.primary, 
              foregroundColor: isDangerous ? Colors.white : theme.colorScheme.onPrimary
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Widget loading([String? message]) {
    return Builder(builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      R.init(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            if (message != null) ...[
              SizedBox(height: R.h(16)), 
              Text(message, style: _secondaryStyle(context))
            ],
          ],
        ),
      );
    });
  }

  static Widget primaryButton({
    required BuildContext context,
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
  }) {
    final theme = Theme.of(context);
    R.init(context);
    final content = isLoading 
      ? SizedBox(
          width: R.w(16), 
          height: R.h(16), 
          child: CircularProgressIndicator(
            strokeWidth: 2, 
            color: theme.colorScheme.onPrimary
          )
        )
      : Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: R.s(16)), SizedBox(width: R.w(8))],
            Flexible(
              child: Text(
                text, 
                style: TextStyle(fontSize: R.s(14)), 
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center, 
                maxLines: 1
              )
            ),
          ],
        );

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: theme.elevatedButtonTheme.style,
      child: content,
    );

    return fullWidth ? SizedBox(width: double.infinity, height: R.h(50), child: button) : button;
  }

  static Widget secondaryButton({
    required BuildContext context, 
    required String text, 
    required VoidCallback? onPressed, 
    IconData? icon, 
    bool fullWidth = true,
  }) {
    final theme = Theme.of(context);
    R.init(context);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: R.s(16)), SizedBox(width: R.w(6))],
        Flexible(
          child: Text(
            text, 
            style: TextStyle(fontSize: R.s(13)), 
            overflow: TextOverflow.visible,
            textAlign: TextAlign.center,
            maxLines: 1,
          )
        ),
      ],
    );

    final button = OutlinedButton(
      onPressed: onPressed,
      style: theme.outlinedButtonTheme.style,
      child: content,
    );

    return fullWidth ? SizedBox(width: double.infinity, height: R.h(50), child: button) : button;
  }

  static Widget infoBanner({
    required String title,
    required String message,
    required IconData icon,
    Color? color,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      final bannerColor = color ?? theme.colorScheme.primary;
      R.init(context);
      return Container(
        margin: R.sym(h: 16, v: 8),
        padding: R.p(16),
        decoration: BoxDecoration(
          color: bannerColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(R.r(12)),
          border: Border.all(color: bannerColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: bannerColor, size: R.s(20)),
                SizedBox(width: R.w(8)),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: bannerColor,
                      fontSize: R.s(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: R.h(8)),
            Text(
              message,
              style: TextStyle(
                color: bannerColor,
                fontSize: R.s(14),
              ),
            ),
            if (actionText != null && onAction != null) ...[
              SizedBox(height: R.h(12)),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionText,
                  style: TextStyle(
                    color: bannerColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  static Widget errorBanner({
    required String message,
    VoidCallback? onDismiss,
  }) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      final errorColor = theme.colorScheme.error;
      R.init(context);
      return Container(
        margin: R.sym(h: 16, v: 8),
        padding: R.p(16),
        decoration: BoxDecoration(
          color: errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(R.r(12)),
          border: Border.all(color: errorColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: errorColor, size: R.s(20)),
            SizedBox(width: R.w(8)),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: errorColor,
                  fontSize: R.s(14),
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close, color: errorColor, size: R.s(20)),
              ),
          ],
        ),
      );
    });
  }

  static void showSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    final theme = Theme.of(context);
    R.init(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(fontSize: R.s(14))),
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      behavior: SnackBarBehavior.fixed,
      duration: const Duration(seconds: 2),
      action: SnackBarAction(
        label: 'Dismiss', 
        textColor: backgroundColor != null ? Colors.white : theme.colorScheme.onPrimary,
        onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      ),
    ));
  }

  static Widget emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      R.init(context);
      return Center(
        child: Padding(
          padding: R.p(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: R.s(64), color: theme.colorScheme.onSurface.withOpacity(0.5)),
              SizedBox(height: R.h(16)),
              Text(
                title, 
                style: _primaryStyle(context).copyWith(
                  fontSize: R.s(18), 
                  fontWeight: FontWeight.bold
                ), 
                textAlign: TextAlign.center
              ),
              if (subtitle != null) ...[
                SizedBox(height: R.h(8)), 
                Text(subtitle, style: _secondaryStyle(context), textAlign: TextAlign.center)
              ],
              if (buttonText != null && onButtonPressed != null) ...[
                SizedBox(height: R.h(24)),
                ElevatedButton(
                  onPressed: onButtonPressed, 
                  child: Text(buttonText, style: TextStyle(fontSize: R.s(14)))
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  static Widget errorState({
    required String message,
    VoidCallback? onRetry,
    String? retryText,
  }) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      R.init(context);
      return Center(
        child: Padding(
          padding: R.p(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: R.s(64), color: theme.colorScheme.error),
              SizedBox(height: R.h(16)),
              Text(
                message,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: R.s(18),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                SizedBox(height: R.h(24)),
                ElevatedButton(onPressed: onRetry, child: Text(retryText ?? 'Retry')),
              ],
            ],
          ),
        ),
      );
    });
  }

  static Widget refreshableList<E>({
    required List<E> items,
    required Widget Function(E, int) itemBuilder,
    required Future<void> Function() onRefresh,
    Widget? emptyState,
    EdgeInsets? padding,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty && emptyState != null
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 400,
                child: emptyState,
              ),
            )
          : ListView.builder(
              padding: padding,
              itemCount: items.length,
              itemBuilder: (context, index) => itemBuilder(items[index], index),
            ),
    );
  }

  static Widget tabScaffold({
    required List<Tab> tabs,
    required List<Widget> tabViews,
    TabController? controller,
  }) {
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          TabBar(
            controller: controller,
            tabs: tabs,
          ),
          Expanded(
            child: TabBarView(
              controller: controller,
              children: tabViews,
            ),
          ),
        ],
      ),
    );
  }

  static Widget sectionTitle(String title) {
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          title,
          style: _primaryStyle(context).copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    });
  }

  static Widget quickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Builder(builder: (context) {
      return Card(
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
                  textAlign: TextAlign.center,
                  style: _primaryStyle(context).copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  static Widget playlistCard({
    required Playlist playlist,
    VoidCallback? onTap,
    VoidCallback? onPlay,
    bool showPlayButton = false,
  }) {
    return Builder(builder: (context) {
      return Card(
        child: ListTile(
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _getPrimary(context).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.library_music),
          ),
          title: Text(playlist.name, style: _primaryStyle(context)),
          subtitle: Text('${playlist.tracks.length} tracks', style: _secondaryStyle(context)),
          trailing: showPlayButton && onPlay != null
              ? IconButton(
                  icon: Icon(Icons.play_arrow, color: _getPrimary(context)),
                  onPressed: onPlay,
                )
              : null,
          onTap: onTap,
        ),
      );
    });
  }

  static Widget settingsSection({
    required String title,
    required List<Widget> items,
  }) {
    return Builder(builder: (context) {
      return Card(
        color: _getSurface(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: _primaryStyle(context).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...items,
          ],
        ),
      );
    });
  }

  static Widget settingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Builder(builder: (context) {
      final itemColor = color ?? _getOnSurface(context);
      return ListTile(
        leading: Icon(icon, color: itemColor),
        title: Text(title, style: TextStyle(color: itemColor)),
        subtitle: subtitle != null ? Text(subtitle, style: _secondaryStyle(context)) : null,
        onTap: onTap,
        trailing: Icon(Icons.chevron_right, color: itemColor.withOpacity(0.5)),
      );
    });
  }

  static Widget switchTile({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String title,
    String? subtitle,
    IconData? icon,
  }) {
    return Builder(builder: (context) {
      return ListTile(
        leading: icon != null ? Icon(icon, color: _getPrimary(context)) : null,
        title: Text(title, style: _primaryStyle(context)),
        subtitle: subtitle != null ? Text(subtitle, style: _secondaryStyle(context)) : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: _getPrimary(context),
        ),
      );
    });
  }

  static Future<String?> showTextInputDialog(
    BuildContext context, {
    required String title,
    String? initialValue,
    String? hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurface(context),
        title: Text(title, style: TextStyle(color: _getOnSurface(context))),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(hintText: hintText, filled: true, fillColor: _getBackground(context)),
            style: TextStyle(color: _getOnSurface(context)),
            maxLines: maxLines,
            validator: validator,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _getOnSurface(context).withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? true) Navigator.pop(context, controller.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  static Future<int?> showSelectionDialog<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T) itemTitle,
  }) async {
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurface(context),
        title: Text(title, style: TextStyle(color: _getOnSurface(context))),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(itemTitle(items[index]), style: TextStyle(color: _getOnSurface(context))),
              onTap: () => Navigator.pop(context, index),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _getOnSurface(context).withOpacity(0.7))),
          ),
        ],
      ),
    );
  }

  static void showInfoDialog({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurface(context),
        title: Row(
          children: [
            Icon(icon, color: _getPrimary(context)),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: _getOnSurface(context))),
          ],
        ),
        content: Text(message, style: TextStyle(color: _getOnSurface(context))),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }
}
