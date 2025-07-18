import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/models.dart';
import '../services/music_player_service.dart';
import '../providers/dynamic_theme_provider.dart';
import '../widgets/voting_widgets.dart';
export 'mini_player_widget.dart';

class AppWidgets {
  static ColorScheme _getColorScheme(BuildContext context) => Theme.of(context).colorScheme;
  static Color _getPrimary(BuildContext context) => _getColorScheme(context).primary;
  static Color _getSurface(BuildContext context) => _getColorScheme(context).surface;
  static Color _getBackground(BuildContext context) => _getColorScheme(context).surface;
  static Color _getOnSurface(BuildContext context) => _getColorScheme(context).onSurface;
  static Color _getError(BuildContext context) => _getColorScheme(context).error;
  
  static TextStyle _primaryStyle(BuildContext context) => TextStyle(
    color: _getOnSurface(context), fontSize: kIsWeb ? 16.0 : 16.sp.toDouble(), fontWeight: FontWeight.w600
  );
  
  static TextStyle _secondaryStyle(BuildContext context) => TextStyle(
    color: _getOnSurface(context).withValues(alpha: 0.7), fontSize: kIsWeb ? 14.0 : 14.sp.toDouble()
  );

  static Widget textField({required BuildContext context, 
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    bool obscureText = false,
    String? Function(String?)? validator, 
    ValueChanged<String>? onChanged, 
    int minLines = 1, 
    int maxLines = 1
  }) {
    return TextFormField(controller: controller, obscureText: obscureText, validator: validator, onChanged: onChanged, minLines: minLines, 
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
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1)
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), 
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1)
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _getPrimary(context), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _getError(context), width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _getError(context), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
        ),
        labelStyle: TextStyle(fontSize: 16, color: _getOnSurface(context).withValues(alpha: 0.7)),
        hintStyle: TextStyle(fontSize: 14, color: _getOnSurface(context).withValues(alpha: 0.5)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: kIsWeb ? 16.0 : 16.w.toDouble(), 
          vertical: kIsWeb ? 12.0 : 12.h.toDouble()
        ),
      ),
    );
  }

  static Widget trackCard({Key? key,
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
              margin: EdgeInsets.symmetric(
                horizontal: kIsWeb ? 16.0 : 16.w.toDouble(), 
                vertical: kIsWeb ? 4.0 : 4.h.toDouble()
              ),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary.withValues(alpha: 0.2) : 
                       isCurrentTrack ? colorScheme.primary.withValues(alpha: 0.1) : 
                       colorScheme.surface,
                borderRadius: BorderRadius.circular(kIsWeb ? 12.0 : 12.r.toDouble()),
                border: isCurrentTrack ? Border.all(color: colorScheme.primary, width: 2) : null,
              ),
              child: Padding(
                padding: EdgeInsets.all(kIsWeb ? 12.0 : 12.w.toDouble()),
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
                    SizedBox(width: kIsWeb ? 12.0 : 12.w.toDouble()),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
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
                            Container(
                              constraints: const BoxConstraints(maxWidth: 80),
                              child: TrackVotingControls(
                                playlistId: playlistId,
                                trackId: track.id,
                                isCompact: true,
                              ),
                            ),
                          if (onSelectionChanged == null)
                            Container(
                              constraints: const BoxConstraints(maxWidth: 100),
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
      width: kIsWeb ? size : size.w.toDouble(), 
      height: kIsWeb ? size : size.h.toDouble(),
      decoration: BoxDecoration(
        color: backgroundColor, 
        borderRadius: BorderRadius.circular(kIsWeb ? 8.0 : 8.r.toDouble())
      ),
      child: imageUrl?.isNotEmpty == true
          ? ClipRRect(
              borderRadius: BorderRadius.circular(kIsWeb ? 8.0 : 8.r.toDouble()), 
              child: CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover)
            )
          : Icon(
              defaultIcon, 
              color: _getOnSurface(context), 
              size: kIsWeb ? size * 0.5 : (size * 0.5).sp.toDouble()
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
          size: kIsWeb ? 20.0 : 20.sp.toDouble() 
        ), 
        onPressed: onPlay,
        padding: EdgeInsets.all(kIsWeb ? 4.0 : 4.w.toDouble()), 
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32, maxWidth: 40), 
      ));
    }
    
    if (showAddButton && onAdd != null && !isInPlaylist) {
      actions.add(IconButton(
        icon: Icon(
          Icons.add_circle_outline, 
          color: colorScheme.onSurface, 
          size: kIsWeb ? 18.0 : 18.sp.toDouble() 
        ), 
        onPressed: onAdd, 
        tooltip: 'Add to Playlist',
        padding: EdgeInsets.all(kIsWeb ? 4.0 : 4.w.toDouble()), 
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32, maxWidth: 40), 
      ));
    }
    
    if (isInPlaylist) {
      actions.add(Padding(
        padding: EdgeInsets.all(kIsWeb ? 4.0 : 4.w.toDouble()),
        child: Icon(
          Icons.check_circle, 
          color: Colors.green, 
          size: kIsWeb ? 18.0 : 18.sp.toDouble() 
        ),
      ));
    }
    
    if (onRemove != null) {
      actions.add(IconButton(
        icon: Icon(
          Icons.remove_circle_outline, 
          color: colorScheme.error, 
          size: kIsWeb ? 18.0 : 18.sp.toDouble() 
        ), 
        onPressed: onRemove,
        padding: EdgeInsets.all(kIsWeb ? 4.0 : 4.w.toDouble()), 
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32, maxWidth: 40), 
      ));
    }
    
    if (actions.isEmpty) return const SizedBox.shrink();
    final displayedActions = actions.take(2).toList();
    return Row(mainAxisSize: MainAxisSize.min, children: displayedActions);
  }

  static Widget loading([String? message]) {
    return Builder(builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            if (message != null) ...[
              SizedBox(height: kIsWeb ? 16.0 : 16.h.toDouble()), 
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
    final content = isLoading 
      ? SizedBox(
          width: kIsWeb ? 16.0 : 16.w.toDouble(), 
          height: kIsWeb ? 16.0 : 16.h.toDouble(), 
          child: CircularProgressIndicator(
            strokeWidth: 2, 
            color: theme.colorScheme.onPrimary
          )
        )
      : Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: kIsWeb ? 16.0 : 16.sp.toDouble()), 
              SizedBox(width: kIsWeb ? 8.0 : 8.w.toDouble())
            ],
            Flexible(
              child: Text(
                text, 
                style: TextStyle(fontSize: kIsWeb ? 14.0 : 14.sp.toDouble()), 
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
    
    return fullWidth ? SizedBox(
      width: double.infinity, 
      height: kIsWeb ? 50.0 : 50.h.toDouble(), 
      child: button
    ) : button;
  }

  static Widget secondaryButton({
    required BuildContext context, 
    required String text, 
    required VoidCallback? onPressed, 
    IconData? icon, 
    bool fullWidth = true,
  }) {
    final theme = Theme.of(context);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: kIsWeb ? 16.0 : 16.sp.toDouble()), 
          SizedBox(width: kIsWeb ? 6.0 : 6.w.toDouble())
        ],
        Flexible(
          child: Text(
            text, 
            style: TextStyle(fontSize: kIsWeb ? 13.0 : 13.sp.toDouble()), 
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
    
    return fullWidth ? SizedBox(
      width: double.infinity, 
      height: kIsWeb ? 50.0 : 50.h.toDouble(), 
      child: button
    ) : button;
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
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: kIsWeb ? 16.0 : 16.w.toDouble(), 
          vertical: kIsWeb ? 8.0 : 8.h.toDouble()
        ),
        padding: EdgeInsets.all(kIsWeb ? 16.0 : 16.w.toDouble()),
        decoration: BoxDecoration(
          color: bannerColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(kIsWeb ? 12.0 : 12.r.toDouble()),
          border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: bannerColor, size: kIsWeb ? 20.0 : 20.sp.toDouble()),
                SizedBox(width: kIsWeb ? 8.0 : 8.w.toDouble()),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: bannerColor,
                      fontSize: kIsWeb ? 16.0 : 16.sp.toDouble(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: kIsWeb ? 8.0 : 8.h.toDouble()),
            Text(
              message,
              style: TextStyle(
                color: bannerColor,
                fontSize: kIsWeb ? 14.0 : 14.sp.toDouble(),
              ),
            ),
            if (actionText != null && onAction != null) ...[
              SizedBox(height: kIsWeb ? 12.0 : 12.h.toDouble()),
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
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: kIsWeb ? 16.0 : 16.w.toDouble(), 
          vertical: kIsWeb ? 8.0 : 8.h.toDouble()
        ),
        padding: EdgeInsets.all(kIsWeb ? 16.0 : 16.w.toDouble()),
        decoration: BoxDecoration(
          color: errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(kIsWeb ? 12.0 : 12.r.toDouble()),
          border: Border.all(color: errorColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: errorColor, size: kIsWeb ? 20.0 : 20.sp.toDouble()),
            SizedBox(width: kIsWeb ? 8.0 : 8.w.toDouble()),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: errorColor,
                  fontSize: kIsWeb ? 14.0 : 14.sp.toDouble(),
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close, color: errorColor, size: kIsWeb ? 20.0 : 20.sp.toDouble()),
              ),
          ],
        ),
      );
    });
  }

  static void showSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(fontSize: kIsWeb ? 14.0 : 14.sp.toDouble())),
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
      return LayoutBuilder(
        builder: (context, constraints) {
          final hasFiniteHeight = constraints.maxHeight.isFinite;
          final isConstrained = hasFiniteHeight && constraints.maxHeight < 200;
          final iconSize = isConstrained ? (kIsWeb ? 24.0 : 24.sp.toDouble()) : (kIsWeb ? 64.0 : 64.sp.toDouble());
          final titleSize = isConstrained ? (kIsWeb ? 12.0 : 12.sp.toDouble()) : (kIsWeb ? 18.0 : 18.sp.toDouble());
          final spacing = isConstrained ? (kIsWeb ? 6.0 : 6.h.toDouble()) : (kIsWeb ? 16.0 : 16.h.toDouble());
          final padding = isConstrained ? (kIsWeb ? 8.0 : 8.w.toDouble()) : (kIsWeb ? 32.0 : 32.w.toDouble());
          
          Widget content = Padding(
            padding: EdgeInsets.all(padding),
            child: isConstrained 
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: iconSize, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                      SizedBox(height: spacing),
                      Text(
                        title, 
                        style: _primaryStyle(context).copyWith(fontSize: titleSize, fontWeight: FontWeight.bold), 
                        textAlign: TextAlign.center,
                        maxLines: isConstrained ? 2 : null,
                        overflow: isConstrained ? TextOverflow.ellipsis : null,
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: spacing / 2), 
                        Text(
                          subtitle, 
                          style: _secondaryStyle(context).copyWith(
                            fontSize: isConstrained ? (kIsWeb ? 10.0 : 10.sp.toDouble()) : null,
                          ), 
                          textAlign: TextAlign.center,
                          maxLines: isConstrained ? 1 : null,
                          overflow: isConstrained ? TextOverflow.ellipsis : null,
                        )
                      ],
                      if (buttonText != null && onButtonPressed != null && !isConstrained) ...[
                        SizedBox(height: spacing),
                        ElevatedButton(
                          onPressed: onButtonPressed, 
                          child: Text(
                            buttonText, 
                            style: TextStyle(fontSize: kIsWeb ? 14.0 : 14.sp.toDouble()),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        ),
                      ],
                      if (buttonText != null && onButtonPressed != null && isConstrained) ...[
                        SizedBox(height: spacing / 2),
                        TextButton(
                          onPressed: onButtonPressed,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: kIsWeb ? 8.0 : 8.w.toDouble(),
                              vertical: kIsWeb ? 4.0 : 4.h.toDouble(),
                            ),
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            buttonText,
                            style: TextStyle(
                              fontSize: kIsWeb ? 10.0 : 10.sp.toDouble(),
                              color: theme.colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: iconSize, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    SizedBox(height: spacing),
                    Text(
                      title, 
                      style: _primaryStyle(context).copyWith(fontSize: titleSize, fontWeight: FontWeight.bold), 
                      textAlign: TextAlign.center,
                      maxLines: isConstrained ? 2 : null,
                      overflow: isConstrained ? TextOverflow.ellipsis : null,
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: spacing / 2), 
                      Text(
                        subtitle, 
                        style: _secondaryStyle(context).copyWith(
                          fontSize: isConstrained ? (kIsWeb ? 10.0 : 10.sp.toDouble()) : null,
                        ), 
                        textAlign: TextAlign.center,
                        maxLines: isConstrained ? 1 : null,
                        overflow: isConstrained ? TextOverflow.ellipsis : null,
                      )
                    ],
                    if (buttonText != null && onButtonPressed != null && !isConstrained) ...[
                      SizedBox(height: spacing),
                      ElevatedButton(
                        onPressed: onButtonPressed, 
                        child: Text(
                          buttonText, 
                          style: TextStyle(fontSize: kIsWeb ? 14.0 : 14.sp.toDouble()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      ),
                    ],
                    if (buttonText != null && onButtonPressed != null && isConstrained) ...[
                      SizedBox(height: spacing / 2),
                      TextButton(
                        onPressed: onButtonPressed,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: kIsWeb ? 8.0 : 8.w.toDouble(),
                            vertical: kIsWeb ? 4.0 : 4.h.toDouble(),
                          ),
                          minimumSize: Size.zero,
                        ),
                        child: Text(
                          buttonText,
                          style: TextStyle(
                            fontSize: kIsWeb ? 10.0 : 10.sp.toDouble(),
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
          );
          
          if (!hasFiniteHeight) {
            return Center(child: content);
          } else if (constraints.maxHeight > 0) {
            return SizedBox(
              height: constraints.maxHeight,
              child: isConstrained
                  ? SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(child: content),
                        ),
                      ),
                    )
                  : Center(child: content),
            );
          } else {
            return SizedBox(height: 200, child: Center(child: content));
          }
        },
      );
    });
  }

  static Widget errorState({required String message, VoidCallback? onRetry, String? retryText}) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      return Center(
        child: Padding(
          padding: EdgeInsets.all(kIsWeb ? 32.0 : 32.w.toDouble()),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: kIsWeb ? 64.0 : 64.sp.toDouble(), color: theme.colorScheme.error),
              SizedBox(height: kIsWeb ? 16.0 : 16.h.toDouble()),
              Text(
                message,
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: kIsWeb ? 18.0 : 18.sp.toDouble(),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                SizedBox(height: kIsWeb ? 24.0 : 24.h.toDouble()),
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
          ? LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight.isFinite ? constraints.maxHeight : MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: emptyState,
                  ),
                );
              },
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
          TabBar(controller: controller, tabs: tabs),
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
              color: _getPrimary(context).withValues(alpha: 0.2),
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
                title, style: _primaryStyle(context).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...items,
          ],
        ),
      );
    });
  }

  static Widget settingsItem({required IconData icon, required String title, String? subtitle, required VoidCallback onTap,
    Color? color,
  }) {
    return Builder(builder: (context) {
      final itemColor = color ?? _getOnSurface(context);
      return ListTile(
        leading: Icon(icon, color: itemColor),
        title: Text(title, style: TextStyle(color: itemColor)),
        subtitle: subtitle != null ? Text(subtitle, style: _secondaryStyle(context)) : null,
        onTap: onTap,
        trailing: Icon(Icons.chevron_right, color: itemColor.withValues(alpha: 0.5)),
      );
    });
  }

  static Widget switchTile({required bool value, required ValueChanged<bool> onChanged, required String title, String? subtitle,
    IconData? icon,
  }) {
    return Builder(builder: (context) {
      return ListTile(
        leading: icon != null ? Icon(icon, color: _getPrimary(context)) : null,
        title: Text(title, style: _primaryStyle(context)),
        subtitle: subtitle != null ? Text(subtitle, style: _secondaryStyle(context)) : null,
        trailing: Switch(value: value, onChanged: onChanged, activeColor: _getPrimary(context)),
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
            maxLines: maxLines, validator: validator,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _getOnSurface(context).withValues(alpha: 0.7))),
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
    
    // Dispose controller after the dialog is fully closed to prevent 
    // "TextEditingController was used after being disposed" error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
    
    return result;
  }

  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool isDangerous = false,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _getSurface(context),
        title: Text(title, style: TextStyle(color: _getOnSurface(context))),
        content: Text(message, style: TextStyle(color: _getOnSurface(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText, style: TextStyle(color: _getOnSurface(context).withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDangerous ? Colors.red : _getPrimary(context),
              foregroundColor: isDangerous ? Colors.white : Colors.black,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
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
            child: Text('Cancel', style: TextStyle(color: _getOnSurface(context).withValues(alpha: 0.7))),
          ),
        ],
      ),
    );
  }
}
