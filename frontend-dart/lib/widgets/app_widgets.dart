import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/music_models.dart';
import '../services/player_services.dart';
import '../providers/theme_providers.dart';
import 'dialog_widgets.dart';
import 'votes_widgets.dart';
import '../models/voting_models.dart';
import 'scrollbar_widgets.dart';
import 'form_widgets.dart';
import 'state_widgets.dart';
export 'player_widgets.dart';

class TrackActionsWidget extends StatelessWidget {
  final bool showAddButton;
  final bool showPlayButton;
  final VoidCallback? onAdd;
  final VoidCallback? onPlay;
  final VoidCallback? onRemove;
  final bool trackIsPlaying;
  final bool isInPlaylist;

  const TrackActionsWidget({
    super.key,
    required this.showAddButton,
    required this.showPlayButton,
    this.onAdd,
    this.onPlay,
    this.onRemove,
    required this.trackIsPlaying,
    required this.isInPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actions = <Widget>[];
    
    if (showPlayButton && onPlay != null) {
      actions.add(AppWidgets._buildStyledIconButton(
        trackIsPlaying ? Icons.pause : Icons.play_arrow, 
        colorScheme.primary, 
        20.0, 
        onPlay!
      ));
    }
    
    if (showAddButton && onAdd != null && !isInPlaylist) {
      actions.add(AppWidgets._buildStyledIconButton(
        Icons.add_circle_outline, 
        colorScheme.onSurface, 
        18.0, 
        onAdd!, 
        tooltip: 'Add to Playlist'
      ));
    }
    
    if (isInPlaylist) {
      actions.add(Padding(
        padding: EdgeInsets.all(AppWidgets._responsiveWidth(4.0)),
        child: Icon(
          Icons.check_circle, 
          color: Colors.green, 
          size: AppWidgets._responsiveValue(18.0) 
        ),
      ));
    }
    
    if (onRemove != null) {
      actions.add(AppWidgets._buildStyledIconButton(
        Icons.remove_circle_outline, 
        colorScheme.error, 
        18.0, 
        onRemove!
      ));
    }
    
    if (actions.isEmpty) return const SizedBox.shrink();
    final displayedActions = actions.take(2).toList();
    return Row(mainAxisSize: MainAxisSize.min, children: displayedActions);
  }
}

class EmptyStateContentWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final bool isConstrained;
  final double iconSize;
  final double titleSize;
  final double spacing;

  const EmptyStateContentWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    required this.isConstrained,
    required this.iconSize,
    required this.titleSize,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          SizedBox(height: spacing),
          Text(
            title, 
            style: AppWidgets._primaryStyle(context).copyWith(fontSize: titleSize, fontWeight: FontWeight.bold), 
            textAlign: TextAlign.center,
            maxLines: isConstrained ? 2 : null,
            overflow: isConstrained ? TextOverflow.ellipsis : null,
          ),
          if (subtitle != null) ...[
            SizedBox(height: spacing / 2), 
            Text(
              subtitle!, 
              style: AppWidgets._secondaryStyle(context).copyWith(
                fontSize: isConstrained ? AppWidgets._responsiveValue(10.0) : null,
              ), 
              textAlign: TextAlign.center,
              maxLines: isConstrained ? 1 : null,
              overflow: isConstrained ? TextOverflow.ellipsis : null,
            )
          ],
          if (buttonText != null && onButtonPressed != null) ...[
            SizedBox(height: isConstrained ? spacing / 2 : spacing),
            isConstrained 
              ? TextButton(
                  onPressed: onButtonPressed,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppWidgets._responsiveWidth(8.0),
                      vertical: AppWidgets._responsiveHeight(2.0),
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    buttonText!,
                    style: TextStyle(
                      fontSize: AppWidgets._responsiveValue(10.0),
                      color: theme.colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : ElevatedButton(
                  onPressed: onButtonPressed, 
                  child: Text(
                    buttonText!, 
                    style: TextStyle(fontSize: AppWidgets._responsiveValue(14.0)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                ),
          ],
        ],
      ),
    );
  }
}

class TrackCardWidget extends StatelessWidget {
  final Track track;
  final bool isSelected;
  final bool isInPlaylist;
  final bool showAddButton;
  final bool showPlayButton;
  final bool showVotingControls;
  final String? playlistContext;
  final String? playlistId;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final VoidCallback? onPlay;
  final VoidCallback? onRemove;
  final VoidCallback? onAddToLibrary;
  final ValueChanged<bool?>? onSelectionChanged;

  const TrackCardWidget({
    super.key,
    required this.track,
    this.isSelected = false,
    this.isInPlaylist = false,
    this.showAddButton = true,
    this.showPlayButton = true,
    this.showVotingControls = false,
    this.playlistContext,
    this.playlistId,
    this.onTap,
    this.onAdd,
    this.onPlay,
    this.onRemove,
    this.onAddToLibrary,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<MusicPlayerService, DynamicThemeProvider>(
      builder: (context, playerService, themeProvider, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isCurrentTrack = playerService.currentTrack?.id == track.id;

        String displayArtist = track.artist;
        if (displayArtist.isEmpty && track.deezerTrackId != null) {
          displayArtist = 'Unknown Artist';
        }

        return Container(
          margin: EdgeInsets.symmetric(
            vertical: AppWidgets._responsiveHeight(2.0),
            horizontal: AppWidgets._responsiveWidth(4.0),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: AppWidgets._getTrackCardColor(colorScheme, isSelected, isCurrentTrack),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8.0),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(AppWidgets._responsiveWidth(8.0)),
              child: Row(
                children: [
                  if (onSelectionChanged != null)
                    Container(
                      margin: EdgeInsets.only(right: AppWidgets._responsiveWidth(8.0)),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: onSelectionChanged,
                      ),
                    ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6.0),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: AppWidgets._buildImage(context, track.imageUrl, 56, colorScheme.surface, Icons.music_note),
                    ),
                  ),
                  SizedBox(width: AppWidgets._responsiveWidth(12.0)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: AppWidgets._responsiveValue(14.0),
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (displayArtist.isNotEmpty)
                          Text(
                            displayArtist,
                            style: TextStyle(
                              fontSize: AppWidgets._responsiveValue(12.0),
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showVotingControls && playlistId != null)
                        Container(
                          margin: EdgeInsets.only(bottom: AppWidgets._responsiveHeight(4.0)),
                          child: TrackVotingControls(
                            playlistId: playlistId!,
                            trackId: track.id,
                            trackIndex: 0,
                            stats: VoteStats(
                              totalVotes: 0,
                              upvotes: 0,
                              downvotes: 0,
                              userHasVoted: false,
                              voteScore: 0.0,
                            ),
                          ),
                        ),
                      if (onSelectionChanged == null)
                        TrackActionsWidget(
                          trackIsPlaying: isCurrentTrack,
                          showAddButton: showAddButton,
                          showPlayButton: showPlayButton,
                          onAdd: onAdd,
                          onPlay: onPlay,
                          onRemove: onRemove,
                          isInPlaylist: isInPlaylist,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AppWidgets {
  static ColorScheme _colorScheme(BuildContext context) => Theme.of(context).colorScheme;

  static Widget _buildWithTheme(Widget Function(BuildContext context, ThemeData theme, ColorScheme colorScheme) builder) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return builder(context, theme, colorScheme);
      },
    );
  }

  static IconButton _buildStyledIconButton(
    IconData icon,
    Color color,
    double size,
    VoidCallback onPressed, {
    String? tooltip,
  }) => IconButton(
    icon: Icon(icon, color: color, size: _responsiveValue(size)),
    onPressed: onPressed,
    tooltip: tooltip,
    padding: EdgeInsets.all(_responsiveWidth(4.0)),
    constraints: const BoxConstraints(minWidth: 32, minHeight: 32, maxWidth: 40),
  );
  
  static TextStyle _primaryStyle(BuildContext context) => TextStyle(
    color: _colorScheme(context).onSurface, fontSize: _responsiveValue(16.0), fontWeight: FontWeight.w600
  );
  
  static TextStyle _secondaryStyle(BuildContext context) => TextStyle(
    color: _colorScheme(context).onSurface.withValues(alpha: 0.7), fontSize: _responsiveValue(14.0)
  );


  static double _responsiveSize(double webSize, double mobileSize) => kIsWeb ? webSize : mobileSize.sp.toDouble();
  static double _responsiveWidth(double size) => _responsive(size, type: 'w');
  static double _responsiveHeight(double size) => _responsive(size, type: 'h');
  static double _responsiveValue(double value) => _responsive(value);
  
  static double _responsive(double value, {String type = 'sp'}) {
    if (kIsWeb) return value;
    switch (type) {
      case 'w': return value.w.toDouble();
      case 'h': return value.h.toDouble();
      case 'sp': default: return value.sp.toDouble();
    }
  }

  static Color _getTrackCardColor(ColorScheme colorScheme, bool isSelected, bool isCurrentTrack) {
    if (isSelected) return colorScheme.primary.withValues(alpha: 0.2);
    if (isCurrentTrack) return colorScheme.primary.withValues(alpha: 0.1);
    return colorScheme.surface;
  }

  static Widget textField({required BuildContext context, 
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    bool obscureText = false,
    String? Function(String?)? validator, 
    ValueChanged<String>? onChanged, 
    ValueChanged<String>? onFieldSubmitted,
    int minLines = 1, 
    int maxLines = 1
  }) => FormWidgets.textField(
    context: context,
    controller: controller,
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    obscureText: obscureText,
    validator: validator,
    onChanged: onChanged,
    onFieldSubmitted: onFieldSubmitted,
    minLines: minLines,
    maxLines: maxLines,
  );

  static Widget _buildImage(
    BuildContext context,
    String? imageUrl,
    double size,
    Color backgroundColor,
    IconData defaultIcon,
  ) {
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
              color: _colorScheme(context).onSurface, 
              size: kIsWeb ? size * 0.5 : (size * 0.5).sp.toDouble()
            ),
    );
  }


  static Widget loading([String? message]) => StateWidgets.loading(message);

  static Widget primaryButton({
    required BuildContext context,
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
  }) => FormWidgets.primaryButton(
    context: context,
    text: text,
    onPressed: onPressed,
    icon: icon,
    isLoading: isLoading,
    fullWidth: fullWidth,
  );

  static Widget secondaryButton({
    required BuildContext context, 
    required String text, 
    required VoidCallback? onPressed, 
    IconData? icon, 
    bool fullWidth = true,
  }) => FormWidgets.secondaryButton(
    context: context,
    text: text,
    onPressed: onPressed,
    icon: icon,
    fullWidth: fullWidth,
  );

  static Widget infoBanner({
    required String title,
    required String message,
    required IconData icon,
    Color? color,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return _buildWithTheme((context, theme, colorScheme) {
      final bannerColor = color ?? colorScheme.primary;
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: _responsiveWidth(16.0), 
          vertical: _responsiveHeight(6.0)
        ),
        padding: EdgeInsets.all(_responsiveWidth(16.0)),
        decoration: BoxDecoration(
          color: bannerColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(_responsiveWidth(12.0)),
          border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: bannerColor, size: _responsiveValue(20.0)),
                SizedBox(width: _responsiveWidth(8.0)),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: bannerColor,
                      fontSize: _responsiveValue(16.0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: _responsiveHeight(6.0)),
            Text(
              message,
              style: TextStyle(
                color: bannerColor,
                fontSize: _responsiveValue(14.0),
              ),
            ),
            if (actionText != null && onAction != null) ...[
              SizedBox(height: _responsiveHeight(8.0)),
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
    return _buildWithTheme((context, theme, colorScheme) {
      final errorColor = colorScheme.error;
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: _responsiveWidth(16.0), 
          vertical: _responsiveHeight(6.0)
        ),
        padding: EdgeInsets.all(_responsiveWidth(16.0)),
        decoration: BoxDecoration(
          color: errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(_responsiveWidth(12.0)),
          border: Border.all(color: errorColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: errorColor, size: _responsiveValue(20.0)),
            SizedBox(width: _responsiveWidth(8.0)),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: errorColor,
                  fontSize: _responsiveValue(14.0),
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close, color: errorColor, size: _responsiveValue(20.0)),
              ),
          ],
        ),
      );
    });
  }

  static void showSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(fontSize: _responsiveValue(14.0))),
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
      return LayoutBuilder(
        builder: (context, constraints) {
          final hasFiniteHeight = constraints.maxHeight.isFinite;
          final isConstrained = hasFiniteHeight && constraints.maxHeight < 200;
          final iconSize = _responsiveSize(isConstrained ? 24.0 : 64.0, isConstrained ? 24 : 64);
          final titleSize = _responsiveSize(isConstrained ? 12.0 : 18.0, isConstrained ? 12 : 18);
          final spacing = _responsiveHeight(isConstrained ? 4.0 : 12.0);
          final padding = _responsiveWidth(isConstrained ? 8.0 : 32.0);
          
          Widget content = Padding(
            padding: EdgeInsets.all(padding),
            child: EmptyStateContentWidget(
              icon: icon,
              title: title,
              subtitle: subtitle,
              buttonText: buttonText,
              onButtonPressed: onButtonPressed,
              isConstrained: isConstrained,
              iconSize: iconSize,
              titleSize: titleSize,
              spacing: spacing,
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
            return SizedBox(height: 150, child: Center(child: content));
          }
        },
      );
    });
  }

  static Widget errorState({required String message, VoidCallback? onRetry, String? retryText}) {
    return _buildWithTheme((context, theme, colorScheme) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(_responsiveWidth(32.0)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: _responsiveValue(64.0), color: colorScheme.error),
              SizedBox(height: _responsiveHeight(12.0)),
              Text(
                message,
                style: TextStyle(color: colorScheme.onSurface, fontSize: _responsiveValue(18.0),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                SizedBox(height: _responsiveHeight(16.0)),
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
                return CustomSingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight.isFinite
                          ? constraints.maxHeight
                          : MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: emptyState,
                  ),
                );
              },
            )
          : CustomSingleChildScrollView(
              padding: padding,
              child: Column(
                children: items.asMap().entries.map((entry) => 
                  itemBuilder(entry.value, entry.key)
                ).toList(),
              ),
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
            padding: const EdgeInsets.all(8),
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
    VoidCallback? onCreatorTap,
    bool showPlayButton = false,
  }) {
    return Builder(builder: (context) {
      return Card(
        child: ListTile(
          leading: Container(
            width: 56,
            height: 48,
            decoration: BoxDecoration(
              color: _colorScheme(context).primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.library_music),
          ),
          title: Text(playlist.name, style: _primaryStyle(context)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${playlist.tracks.length} tracks', style: _secondaryStyle(context)),
              GestureDetector(
                onTap: onCreatorTap,
                child: Text(
                  'by ${playlist.creator}',
                  style: _secondaryStyle(context).copyWith(
                    color: _colorScheme(context).primary,
                    decoration: TextDecoration.underline,
                    decorationColor: _colorScheme(context).primary,
                  ),
                ),
              ),
            ],
          ),
          trailing: showPlayButton && onPlay != null
              ? IconButton(
                  icon: Icon(Icons.play_arrow, color: _colorScheme(context).primary),
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
        color: _colorScheme(context).surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
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

  static Widget settingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Builder(builder: (context) {
      final itemColor = color ?? _colorScheme(context).onSurface;
      return ListTile(
        leading: Icon(icon, color: itemColor),
        title: Text(title, style: TextStyle(color: itemColor)),
        subtitle: subtitle != null ? Text(subtitle, style: _secondaryStyle(context)) : null,
        onTap: onTap,
        trailing: Icon(Icons.chevron_right, color: itemColor.withValues(alpha: 0.5)),
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
        leading: icon != null ? Icon(icon, color: _colorScheme(context).primary) : null,
        title: Text(title, style: _primaryStyle(context)),
        subtitle: subtitle != null ? Text(subtitle, style: _secondaryStyle(context)) : null,
        trailing: Switch(value: value, onChanged: onChanged, activeColor: _colorScheme(context).primary),
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
  }) => DialogWidgets.showTextInputDialog(
    context,
    title: title,
    initialValue: initialValue,
    hintText: hintText,
    maxLines: maxLines,
    validator: validator,
  );

  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool isDangerous = false,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) => DialogWidgets.showConfirmDialog(
    context,
    title: title,
    message: message,
    isDangerous: isDangerous,
    confirmText: confirmText,
    cancelText: cancelText,
  );

  static Future<int?> showSelectionDialog<T>({
    required BuildContext context, 
    required String title,
    required List<T> items,
    required String Function(T) itemTitle,
  }) => DialogWidgets.showSelectionDialog<T>(context: context, title: title, items: items, itemTitle: itemTitle);

  static Widget buildErrorScreen(String message) {
    return Builder(
      builder: (context) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
