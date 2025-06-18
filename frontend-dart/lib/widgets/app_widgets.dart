// lib/widgets/app_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/consolidated_core.dart';
import '../models/models.dart';
import '../services/music_player_service.dart';
import '../providers/dynamic_theme_provider.dart';

class R {
  static double s(double size) => kIsWeb ? size : size.sp;
  static double w(double size) => kIsWeb ? size : size.w;
  static double h(double size) => kIsWeb ? size : size.h;
  static double r(double size) => kIsWeb ? size : size.r;
  static EdgeInsets p(double size) => kIsWeb ? EdgeInsets.all(size) : EdgeInsets.all(size.w);
  static EdgeInsets sym({double? h, double? v}) => kIsWeb ? EdgeInsets.symmetric(horizontal: h ?? 0, vertical: v ?? 0) : EdgeInsets.symmetric(horizontal: (h ?? 0).w, vertical: (v ?? 0).h);
}

class AppWidgets {
  static final _primaryStyle = TextStyle(color: Colors.white, fontSize: R.s(16), fontWeight: FontWeight.w600);
  static final _secondaryStyle = TextStyle(color: Colors.white70, fontSize: R.s(14));
  static final _greyStyle = TextStyle(color: Colors.grey, fontSize: R.s(12));

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
    style: _primaryStyle,
    decoration: AppTheme.getInputDecoration(labelText: labelText, hintText: hintText, prefixIcon: prefixIcon),
  );

  static Widget _buildButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
    bool isOutlined = false,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final content = isLoading 
      ? SizedBox(width: R.w(16), height: R.h(16), child: const CircularProgressIndicator(strokeWidth: 2))
      : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: R.s(16)), SizedBox(width: R.w(8))],
            Text(text, style: TextStyle(fontSize: R.s(14))),
          ],
        );

    final button = isOutlined 
      ? OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor ?? Colors.white,
            side: BorderSide(color: foregroundColor ?? Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.r(8))),
          ),
          child: content,
        )
      : ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppTheme.primary,
            foregroundColor: foregroundColor ?? Colors.black,
            minimumSize: Size(R.w(88), R.h(50)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.r(25))),
          ),
          child: content,
        );
    
    return fullWidth ? SizedBox(width: double.infinity, height: R.h(50), child: button) : button;
  }

  static Widget primaryButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
  }) => _buildButton(text: text, onPressed: onPressed, icon: icon, isLoading: isLoading, fullWidth: fullWidth);

  static Widget secondaryButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool fullWidth = true,
  }) => _buildButton(text: text, onPressed: onPressed, icon: icon, fullWidth: fullWidth, isOutlined: true);

  static Widget loading([String? message]) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppTheme.primary),
        if (message != null) ...[SizedBox(height: R.h(16)), Text(message, style: _secondaryStyle)],
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
      padding: R.p(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: R.s(64), color: Colors.grey),
          SizedBox(height: R.h(16)),
          Text(title, style: _primaryStyle.copyWith(fontSize: R.s(18), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          if (subtitle != null) ...[SizedBox(height: R.h(8)), Text(subtitle, style: _secondaryStyle, textAlign: TextAlign.center)],
          if (buttonText != null && onButtonPressed != null) ...[
            SizedBox(height: R.h(24)),
            ElevatedButton(onPressed: onButtonPressed, child: Text(buttonText, style: TextStyle(fontSize: R.s(14)))),
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
      padding: R.p(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: R.s(64), color: AppTheme.error),
          SizedBox(height: R.h(16)),
          Text('Error', style: _primaryStyle.copyWith(fontSize: R.s(18), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          SizedBox(height: R.h(8)),
          Text(message, style: _secondaryStyle, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            SizedBox(height: R.h(24)),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
              child: Text(retryText ?? 'Retry', style: TextStyle(fontSize: R.s(14))),
            ),
          ],
        ],
      ),
    ),
  );

  static Widget _banner({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    VoidCallback? onAction,
    String? actionText,
  }) => Container(
    padding: R.p(16),
    margin: R.sym(h: 16, v: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(R.r(8)),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: R.s(24)),
        SizedBox(width: R.w(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: R.s(16))),
              SizedBox(height: R.h(4)),
              Text(message, style: TextStyle(color: color.withOpacity(0.8), fontSize: R.s(14))),
            ],
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionText, style: TextStyle(color: color, fontSize: R.s(14)))),
      ],
    ),
  );

  static Widget infoBanner({
    required String title,
    required String message,
    required IconData icon,
    Color color = AppTheme.primary,
    VoidCallback? onAction,
    String? actionText,
  }) => _banner(title: title, message: message, icon: icon, color: color, onAction: onAction, actionText: actionText);

  static Widget errorBanner({required String message, VoidCallback? onDismiss}) => 
    _banner(title: 'Error', message: message, icon: Icons.error_outline, color: Colors.red, actionText: onDismiss != null ? 'Dismiss' : null, onAction: onDismiss);

  static Widget successBanner({required String message}) => 
    _banner(title: 'Success', message: message, icon: Icons.check_circle, color: Colors.green);

  static Widget formCard({required String title, IconData? titleIcon, required Widget child}) => 
    AppTheme.buildFormCard(title: title, titleIcon: titleIcon, child: child);

  static Widget sectionTitle(String title) => Padding(
    padding: R.sym(h: 16, v: 8),
    child: Text(title, style: _primaryStyle.copyWith(fontSize: R.s(20), fontWeight: FontWeight.bold)),
  );

  static Widget trackCard({
    Key? key,
    required Track track,
    bool isSelected = false,
    bool isInPlaylist = false,
    bool showAddButton = true,
    bool showPlayButton = true,
    bool showExplicitAddButton = false,
    String? playlistContext,
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

      return AnimationConfiguration.staggeredList(
        position: 0,
        duration: const Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 50.0,
          child: FadeInAnimation(
            child: Container(
              margin: R.sym(h: 16, v: 4),
              decoration: BoxDecoration(
                color: isSelected ? themeProvider.primaryColor.withOpacity(0.2) : 
                       isCurrentTrack ? themeProvider.primaryColor.withOpacity(0.1) : 
                       themeProvider.surfaceColor,
                borderRadius: BorderRadius.circular(R.r(12)),
                border: isCurrentTrack ? Border.all(color: themeProvider.primaryColor, width: 2) : null,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: onSelectionChanged != null
                        ? Checkbox(value: isSelected, onChanged: onSelectionChanged, activeColor: themeProvider.primaryColor)
                        : _buildImage(track.imageUrl, 56, themeProvider.surfaceColor, Icons.music_note),
                    title: Text(track.name, style: _primaryStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(track.artist, style: _secondaryStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: onSelectionChanged == null ? _buildTrackActions(showAddButton, showPlayButton, onAdd, onPlay, onRemove, trackIsPlaying, themeProvider, isInPlaylist) : null,
                    onTap: onTap,
                  ),
                  if (showExplicitAddButton) _buildExplicitButton(onAdd, isInPlaylist, playlistContext, themeProvider),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  static Widget _buildImage(String? imageUrl, double size, Color backgroundColor, IconData defaultIcon) => Container(
    width: R.w(size), height: R.h(size),
    decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(R.r(8))),
    child: imageUrl?.isNotEmpty == true
        ? ClipRRect(borderRadius: BorderRadius.circular(R.r(8)), child: CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover))
        : Icon(defaultIcon, color: Colors.white, size: R.s(size * 0.5)),
  );

  static Widget _buildTrackActions(bool showAddButton, bool showPlayButton, VoidCallback? onAdd, VoidCallback? onPlay, VoidCallback? onRemove, bool trackIsPlaying, DynamicThemeProvider themeProvider, bool isInPlaylist) {
    final actions = <Widget>[];
    
    if (showPlayButton && onPlay != null) {
      actions.add(IconButton(
        icon: Icon(trackIsPlaying ? Icons.pause : Icons.play_arrow, color: themeProvider.primaryColor, size: R.s(24)), 
        onPressed: onPlay,
      ));
    }
    
    if (showAddButton && onAdd != null && !isInPlaylist) {
      actions.add(IconButton(
        icon: Icon(Icons.add_circle_outline, color: Colors.white, size: R.s(20)), 
        onPressed: onAdd, tooltip: 'Add to Playlist',
      ));
    }
    
    if (isInPlaylist) actions.add(Icon(Icons.check_circle, color: Colors.green, size: R.s(20)));
    if (onRemove != null) actions.add(IconButton(icon: Icon(Icons.remove_circle_outline, color: Colors.red, size: R.s(20)), onPressed: onRemove));
    
    return actions.isNotEmpty ? Wrap(spacing: R.w(4), children: actions) : const SizedBox.shrink();
  }

  static Widget _buildExplicitButton(VoidCallback? onAdd, bool isInPlaylist, String? playlistContext, DynamicThemeProvider themeProvider) {
    if (isInPlaylist) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(R.w(16), 0, R.w(16), R.h(12)),
        child: Container(
          padding: R.sym(h: 16, v: 8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(R.r(20)),
            border: Border.all(color: Colors.green.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              SizedBox(width: R.w(8)),
              Text('Already in playlist', style: TextStyle(color: Colors.green, fontSize: R.s(14), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }
    
    if (onAdd != null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(R.w(16), 0, R.w(16), R.h(12)),
        child: ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: Text(playlistContext != null ? 'Add to $playlistContext' : 'Add to Playlist', style: TextStyle(fontSize: R.s(14), fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeProvider.primaryColor, foregroundColor: Colors.black, elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.r(20))),
            padding: R.sym(h: 20, v: 10),
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  static Widget playlistCard({
    required Playlist playlist,
    required VoidCallback? onTap,
    VoidCallback? onPlay,
    bool showPlayButton = false,
  }) => Card(
    margin: EdgeInsets.only(bottom: R.h(12)),
    color: AppTheme.surface,
    child: ListTile(
      leading: _buildImage(playlist.imageUrl, 56, AppTheme.primary.withOpacity(0.2), Icons.library_music),
      title: Text(playlist.name, style: _primaryStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${playlist.tracks.length} tracks', style: _secondaryStyle),
          Text('By ${playlist.creator}', style: _greyStyle),
        ],
      ),
      trailing: showPlayButton && onPlay != null
          ? IconButton(icon: Icon(Icons.play_circle_outline, color: AppTheme.primary, size: R.s(24)), onPressed: onPlay)
          : Icon(Icons.chevron_right, color: Colors.grey, size: R.s(20)),
      onTap: onTap,
    ),
  );

  static Widget switchTile({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String title,
    String? subtitle,
    IconData? icon,
  }) => SwitchListTile(
    value: value, onChanged: onChanged,
    title: Text(title, style: _primaryStyle),
    subtitle: subtitle != null ? Text(subtitle, style: _secondaryStyle) : null,
    secondary: icon != null ? Icon(icon, color: AppTheme.primary) : null,
    activeColor: AppTheme.primary,
  );

  static Widget statusIndicator({required bool isConnected, String? connectedText, String? disconnectedText}) {
    final color = isConnected ? Colors.green : Colors.red;
    final text = isConnected ? (connectedText ?? 'Connected') : (disconnectedText ?? 'Disconnected');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: R.w(8), height: R.h(8), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: R.w(4)),
        Text(text, style: TextStyle(color: color, fontSize: R.s(12))),
      ],
    );
  }

  static Widget quickActionCard({required String title, required IconData icon, required Color color, VoidCallback? onTap}) => Card(
    color: AppTheme.surface,
    child: InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(R.r(12)),
      child: Padding(
        padding: R.p(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: R.s(32)),
            SizedBox(height: R.h(8)),
            Text(title, style: _secondaryStyle.copyWith(fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );

  static Widget featureCard({required IconData icon, required String title, required String description, VoidCallback? onTap}) => Card(
    color: AppTheme.surface, margin: EdgeInsets.only(bottom: R.h(12)),
    child: ListTile(
      leading: Container(
        padding: R.p(8),
        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(R.r(8))),
        child: Icon(icon, color: AppTheme.primary),
      ),
      title: Text(title, style: _primaryStyle),
      subtitle: Text(description, style: _secondaryStyle),
      trailing: Icon(Icons.chevron_right, color: Colors.grey, size: R.s(20)),
      onTap: onTap,
    ),
  );

  static Widget settingsSection({required String title, required List<Widget> items}) => Card(
    color: AppTheme.surface, margin: EdgeInsets.only(bottom: R.h(16)),
    child: Padding(
      padding: R.p(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: R.s(16), fontWeight: FontWeight.bold, color: AppTheme.primary)),
          SizedBox(height: R.h(8)),
          ...items,
        ],
      ),
    ),
  );

  static Widget settingsItem({required IconData icon, required String title, required String subtitle, VoidCallback? onTap, Color color = Colors.white}) => ListTile(
    leading: Icon(icon, color: color),
    title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: R.s(16))),
    subtitle: Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: R.s(14))),
    trailing: Icon(Icons.chevron_right, color: Colors.grey, size: R.s(20)),
    onTap: onTap,
  );

  static void showSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(fontSize: R.s(14))),
      backgroundColor: backgroundColor ?? AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  static Widget tabScaffold({required List<Tab> tabs, required List<Widget> tabViews, TabController? controller}) => DefaultTabController(
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
          child: SizedBox(height: R.h(600), child: emptyState),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh, color: AppTheme.primary,
      child: AnimationLimiter(
        child: ListView.builder(
          padding: padding ?? R.p(16), itemCount: items.length,
          itemBuilder: (context, index) => AnimationConfiguration.staggeredList(
            position: index, duration: const Duration(milliseconds: 375),
            child: SlideAnimation(verticalOffset: 50.0, child: FadeInAnimation(child: itemBuilder(items[index], index))),
          ),
        ),
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
                    crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(track.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: R.s(14)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(track.artist, style: TextStyle(color: Colors.grey, fontSize: R.s(12)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
              IconButton(onPressed: playerService.togglePlay, icon: Icon(playerService.isPlaying ? Icons.pause : Icons.play_arrow, color: themeProvider.primaryColor)),
            ],
          ),
        );
      },
    );
  }
}
