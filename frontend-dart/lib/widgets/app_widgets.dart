// lib/widgets/app_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:responsive_framework/responsive_framework.dart';
import '../core/core.dart';
import '../models/models.dart';
import '../services/music_player_service.dart';
import '../providers/dynamic_theme_provider.dart';
import '../widgets/voting_widgets.dart';
import '../models/voting_models.dart';

class R {
  static double _screenWidth = 375;
  static double _screenHeight = 812;
  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _screenWidth = size.width;
    _screenHeight = size.height;
  }
  static double w(double width) => (_screenWidth / 375) * width;
  static double h(double height) => (_screenHeight / 812) * height;
  static double s(double size) {
    final scale = (_screenWidth / 375).clamp(0.8, 1.2); 
    return size * scale;
  }
  static double r(double radius) => (_screenWidth / 375) * radius;
  static EdgeInsets p(double padding) => EdgeInsets.all((_screenWidth / 375) * padding);
  static EdgeInsets sym({double h = 0, double v = 0}) => EdgeInsets.symmetric(
    horizontal: w(h), 
    vertical: R.h(v)
  );
}

class ResponsiveHelper {
  static double fontSize(BuildContext context, double size) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return size * 0.85; 
    else if (screenWidth > 600) return size * 1.1; 
    return size; 
  }

  static double spacing(BuildContext context, double size) {
    if (ResponsiveBreakpoints.of(context).isMobile) return size * 0.9;
    else if (ResponsiveBreakpoints.of(context).isTablet) return size;
    else return size * 1.1;
  }
  static EdgeInsets padding(BuildContext context, double size) {
    final responsive = spacing(context, size);
    return EdgeInsets.all(responsive);
  }
  static EdgeInsets symmetricPadding(BuildContext context, {double? horizontal, double? vertical}) {
    return EdgeInsets.symmetric(
      horizontal: horizontal != null ? spacing(context, horizontal) : 0,
      vertical: vertical != null ? spacing(context, vertical) : 0,
    );
  }
  static double iconSize(BuildContext context, double size) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return size * 0.9;
    else if (screenWidth > 600) return size * 1.1;
    return size;
  }
  static double borderRadius(BuildContext context, double radius) {
    if (ResponsiveBreakpoints.of(context).isMobile) return radius * 0.8;
    else if (ResponsiveBreakpoints.of(context).isTablet) return radius;
    else return radius * 1.2;
  }
}

class AppWidgets {
  static TextStyle _primaryStyle(BuildContext context) => TextStyle(
    color: Colors.white, fontSize: ResponsiveHelper.fontSize(context, 16), 
    fontWeight: FontWeight.w600
  );
  static TextStyle _secondaryStyle(BuildContext context) => TextStyle(
    color: Colors.white70, 
    fontSize: ResponsiveHelper.fontSize(context, 14)
  );
  static TextStyle _greyStyle(BuildContext context) => TextStyle(
    color: Colors.grey, 
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
    int minLines = 1,
    int maxLines = 1,
  }) => TextFormField(
    controller: controller,
    obscureText: obscureText,
    validator: validator,
    onChanged: onChanged,
    minLines: minLines,
    maxLines: maxLines,
    style: _primaryStyle(context),
    decoration: AppTheme.getInputDecoration(
      labelText: labelText, 
      hintText: hintText, 
      prefixIcon: prefixIcon
    ).copyWith(
      contentPadding: ResponsiveHelper.symmetricPadding(context, horizontal: 16, vertical: 12),
    ),
  );

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
                color: isSelected ? themeProvider.primaryColor.withOpacity(0.2) : 
                       isCurrentTrack ? themeProvider.primaryColor.withOpacity(0.1) : 
                       themeProvider.surfaceColor,
                borderRadius: BorderRadius.circular(ResponsiveHelper.borderRadius(context, 12)),
                border: isCurrentTrack ? Border.all(color: themeProvider.primaryColor, width: 2) : null,
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
                          activeColor: themeProvider.primaryColor
                        ),
                      )
                    else
                      _buildImage(context, track.imageUrl, 56, themeProvider.surfaceColor, Icons.music_note),
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
                                themeProvider, 
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

  static Widget _buildImage(BuildContext context, String? imageUrl, double size, Color backgroundColor, IconData defaultIcon) => Container(
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
            color: Colors.white, 
            size: ResponsiveHelper.iconSize(context, size * 0.5)
          ),
  );

  static Widget _buildTrackActions(
    BuildContext context,
    bool showAddButton, 
    bool showPlayButton, 
    VoidCallback? onAdd, 
    VoidCallback? onPlay, 
    VoidCallback? onRemove, 
    bool trackIsPlaying, 
    DynamicThemeProvider themeProvider, 
    bool isInPlaylist
  ) {
    final actions = <Widget>[];
    if (showPlayButton && onPlay != null) {
      actions.add(IconButton(
        icon: Icon(
          trackIsPlaying ? Icons.pause : Icons.play_arrow, 
          color: themeProvider.primaryColor, 
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
          color: Colors.white, 
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
          color: Colors.red, 
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

  // Rest of the AppWidgets methods remain unchanged...
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool isDangerous = false,
    String confirmText = 'Confirm', String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: isDangerous ? Colors.red : AppTheme.primary, foregroundColor: Colors.white),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<String?> showTextInputDialog(
    BuildContext context, {
    required String title,
    String? hintText,
    String? initialValue,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: AppTheme.surfaceVariant,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            validator: validator,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(controller.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Widget loading([String? message]) {
    return Builder(builder: (context) {
      R.init(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primary),
            if (message != null) ...[SizedBox(height: R.h(16)), Text(message, style: _secondaryStyle(context))],
          ],
        ),
      );
    });
  }

  static Widget emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return Builder(builder: (context) {
      R.init(context);
      return Center(
        child: Padding(
          padding: R.p(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: R.s(64), color: Colors.grey),
              SizedBox(height: R.h(16)),
              Text(title, style: _primaryStyle(context).copyWith(fontSize: R.s(18), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              if (subtitle != null) ...[SizedBox(height: R.h(8)), Text(subtitle, style: _secondaryStyle(context), textAlign: TextAlign.center)],
              if (buttonText != null && onButtonPressed != null) ...[
                SizedBox(height: R.h(24)),
                ElevatedButton(onPressed: onButtonPressed, child: Text(buttonText, style: TextStyle(fontSize: R.s(14)))),
              ],
            ],
          ),
        ),
      );
    });
  }

  static void showSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    R.init(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(fontSize: R.s(14))),
      backgroundColor: backgroundColor ?? AppTheme.primary,
      behavior: SnackBarBehavior.fixed,
      duration: const Duration(seconds: 2),
      action: SnackBarAction(
        label: 'Dismiss', textColor: Colors.white,
        onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      ),
    ));
  }

  static Widget primaryButton({
    required BuildContext context,
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
  }) {
    R.init(context);
    final content = isLoading 
      ? SizedBox(width: R.w(16), height: R.h(16), child: const CircularProgressIndicator(strokeWidth: 2))
      : Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: R.s(16)), SizedBox(width: R.w(8))],
            Flexible(
              child: Text(text, style: TextStyle(fontSize: R.s(14)), overflow: TextOverflow.visible,
                textAlign: TextAlign.center, maxLines: 1)
            ),
          ],
        );
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary, 
        foregroundColor: Colors.black,
        minimumSize: Size(R.w(88), R.h(50)), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.r(25))),
        padding: EdgeInsets.symmetric(horizontal: R.w(16), vertical: R.h(12)),
      ),
      child: content,
    );
    return fullWidth ? SizedBox(width: double.infinity, height: R.h(50), child: button) : button;
  }

  static Widget secondaryButton({required BuildContext context, 
    required String text, 
    required VoidCallback? onPressed, 
    IconData? icon, 
    bool fullWidth = true,
  }) {
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
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.r(8))),
        padding: EdgeInsets.symmetric(horizontal: R.w(12), vertical: R.h(12)),
      ),
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
      R.init(context);
      final bannerColor = color ?? Colors.blue;
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
      R.init(context);
      return Container(
        margin: R.sym(h: 16, v: 8),
        padding: R.p(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(R.r(12)),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: R.s(20)),
            SizedBox(width: R.w(8)),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: R.s(14),
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close, color: Colors.red, size: R.s(20)),
              ),
          ],
        ),
      );
    });
  }

  static Widget tabScaffold({ required List<Tab> tabs, required List<Widget> tabViews, TabController? controller}) {
    return Builder(builder: (context) {
      return DefaultTabController(
        length: tabs.length,
        child: Column(
          children: [
            Container(
              color: AppTheme.background,
              child: TabBar(
                controller: controller,
                tabs: tabs,
                indicatorColor: AppTheme.primary,
                labelColor: AppTheme.primary,
                unselectedLabelColor: Colors.white70,
              ),
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
    });
  }

  static Widget sectionTitle(String title) {
    return Builder(builder: (context) {
      R.init(context);
      return Padding(
        padding: R.sym(h: 16, v: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: R.s(20),
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
      R.init(context);
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: R.p(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(R.r(12)),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: R.p(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(R.r(12)),
                ),
                child: Icon(icon, color: color, size: R.s(32)),
              ),
              SizedBox(height: R.h(12)),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: R.s(14),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    });
  }

  static Widget playlistCard({
    required Playlist playlist,
    required VoidCallback onTap,
    VoidCallback? onPlay,
    bool showPlayButton = false,
  }) {
    return Builder(builder: (context) {
      R.init(context);
      return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: R.sym(h: 16, v: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(R.r(12)),
          ),
          child: Padding(
            padding: R.p(16),
            child: Row(
              children: [
                Container(
                  width: R.w(60),
                  height: R.h(60),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(R.r(8)),
                  ),
                  child: playlist.imageUrl?.isNotEmpty == true
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(R.r(8)),
                          child: Image.network(
                            playlist.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.library_music, color: AppTheme.primary, size: R.s(30)),
                          ),
                        )
                      : Icon(Icons.library_music, color: AppTheme.primary, size: R.s(30)),
                ),
                SizedBox(width: R.w(16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: R.s(16),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: R.h(4)),
                      Text(
                        '${playlist.tracks.length} tracks • ${playlist.creator}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: R.s(12),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (playlist.description.isNotEmpty) ...[
                        SizedBox(height: R.h(4)),
                        Text(
                          playlist.description,
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: R.s(11),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (showPlayButton && onPlay != null)
                  IconButton(
                    onPressed: onPlay,
                    icon: Icon(Icons.play_arrow, color: AppTheme.primary, size: R.s(28)),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  static Widget playlistTrackCard({
    Key? key,
    required PlaylistTrack playlistTrack,
    VoidCallback? onTap,
    VoidCallback? onPlay,
    VoidCallback? onRemove,
    bool showVotingControls = false,
    bool showPoints = false,
    String? playlistId,
    int? trackIndex,
  }) {
    return Builder(builder: (context) {
      R.init(context);
      final track = playlistTrack.track;
      
      return Container(
        key: key,
        margin: R.sym(h: 16, v: 4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(R.r(12)),
        ),
        child: ListTile(
          leading: Container(
            width: R.w(56),
            height: R.h(56),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(R.r(8)),
            ),
            child: track?.imageUrl?.isNotEmpty == true
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(R.r(8)),
                    child: Image.network(
                      track!.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.music_note, color: Colors.white, size: R.s(24)),
                    ),
                  )
                : Icon(Icons.music_note, color: Colors.white, size: R.s(24)),
          ),
          title: Text(
            track?.name ?? playlistTrack.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: R.s(14),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track?.artist ?? 'Unknown Artist',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: R.s(12),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (showPoints) ...[
                SizedBox(height: R.h(4)),
                Text(
                  '${playlistTrack.points} points',
                  style: TextStyle(
                    color: playlistTrack.points > 0 ? Colors.green : 
                           playlistTrack.points < 0 ? Colors.red : Colors.grey,
                    fontSize: R.s(11),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showVotingControls && playlistId != null && trackIndex != null)
                TrackVotingControls(
                  playlistId: playlistId,
                  trackId: track?.id ?? playlistTrack.trackId,
                  trackIndex: trackIndex,
                  isCompact: true,
                ),
              if (onPlay != null)
                IconButton(
                  onPressed: onPlay,
                  icon: Icon(Icons.play_arrow, color: AppTheme.primary, size: R.s(20)),
                ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(Icons.remove_circle_outline, color: Colors.red, size: R.s(20)),
                ),
            ],
          ),
          onTap: onTap,
        ),
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
      R.init(context);
      return SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: R.s(16),
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: R.s(14),
                ),
              )
            : null,
        secondary: icon != null ? Icon(icon, color: AppTheme.primary, size: R.s(24)) : null,
        activeColor: AppTheme.primary,
        contentPadding: R.sym(h: 16, v: 8),
      );
    });
  }

  static Widget settingsSection({
    required String title,
    required List<Widget> items,
  }) {
    return Builder(builder: (context) {
      R.init(context);
      return Container(
        margin: R.sym(h: 16, v: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(R.r(12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: R.p(16),
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: R.s(18),
                  fontWeight: FontWeight.bold,
                ),
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
      R.init(context);
      final itemColor = color ?? Colors.white;
      return ListTile(
        leading: Icon(icon, color: color ?? AppTheme.primary, size: R.s(24)),
        title: Text(
          title,
          style: TextStyle(
            color: itemColor,
            fontSize: R.s(16),
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: itemColor.withOpacity(0.7),
                  fontSize: R.s(14),
                ),
              )
            : null,
        trailing: Icon(Icons.chevron_right, color: itemColor.withOpacity(0.5), size: R.s(20)),
        onTap: onTap,
        contentPadding: R.sym(h: 16, v: 8),
      );
    });
  }

  static Widget errorState({
    required String message,
    VoidCallback? onRetry,
    String? retryText,
  }) {
    return Builder(builder: (context) {
      R.init(context);
      return Center(
        child: Padding(
          padding: R.p(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: R.s(64), color: Colors.red),
              SizedBox(height: R.h(16)),
              Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: R.s(18),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                SizedBox(height: R.h(24)),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(retryText ?? 'Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  static Widget refreshableList<T>({
    required List<T> items,
    required Widget Function(T, int) itemBuilder,
    required Future<void> Function() onRefresh,
    Widget? emptyState,
    EdgeInsets? padding,
  }) {
    return Builder(builder: (context) {
      if (items.isEmpty && emptyState != null) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: emptyState,
            ),
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
    });
  }

  static Future<int?> showSelectionDialog<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T) itemTitle,
    List<IconData>? icons,
  }) async {
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: icons != null && index < icons.length
                    ? Icon(icons[index], color: AppTheme.primary)
                    : null,
                title: Text(
                  itemTitle(item),
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, index),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  static Future<void> showInfoDialog({
    required BuildContext context,
    required String title,
    required String message,
    IconData? icon,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppTheme.primary),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(title, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('OK'),
          ),
        ],
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
        R.init(context);
        final track = playerService.currentTrack;
        if (track == null) return const SizedBox.shrink();

        return Container(
          height: R.h(60),
          decoration: BoxDecoration(
            color: themeProvider.surfaceColor,
            boxShadow: [BoxShadow(color: themeProvider.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              SizedBox(
                width: R.w(60), height: R.h(60),
                child: track.imageUrl?.isNotEmpty == true
                    ? CachedNetworkImage(imageUrl: track.imageUrl!, fit: BoxFit.cover)
                    : Container(color: themeProvider.surfaceColor, child: const Icon(Icons.music_note, color: Colors.white)),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: R.w(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        track.name, 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: R.s(14)), 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis
                      ),
                      Text(
                        track.artist, 
                        style: TextStyle(color: Colors.grey, fontSize: R.s(12)), maxLines: 1, overflow: TextOverflow.ellipsis
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: playerService.togglePlay, 
                icon: Icon(playerService.isPlaying ? Icons.pause : Icons.play_arrow, color: themeProvider.primaryColor),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
              IconButton(
                onPressed: () => playerService.stop(), 
                icon: Icon(Icons.close, color: Colors.grey, size: R.s(20)),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ],
          ),
        );
      },
    );
  }
}
