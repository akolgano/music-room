// lib/widgets/app_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:auto_size_text/auto_size_text.dart';
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
    style: TextStyle(color: Colors.white, fontSize: 16.sp),
    decoration: AppTheme.getInputDecoration(labelText: labelText, hintText: hintText, prefixIcon: prefixIcon),
  );

  static Widget primaryButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
  }) => _buildButton(
    text: text,
    onPressed: onPressed,
    icon: icon,
    isLoading: isLoading,
    fullWidth: fullWidth,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.black,
      minimumSize: Size(88.w, 50.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
    ),
  );

  static Widget secondaryButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool fullWidth = true,
  }) => _buildButton(
    text: text,
    onPressed: onPressed,
    icon: icon,
    fullWidth: fullWidth,
    isOutlined: true,
  );

  static Widget _buildButton({
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
    bool isOutlined = false,
    ButtonStyle? style,
  }) {
    final child = isLoading 
      ? SizedBox(width: 16.w, height: 16.h, child: const CircularProgressIndicator(strokeWidth: 2))
      : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, size: 16.sp),
            if (icon != null) SizedBox(width: 8.w),
            AutoSizeText(text, maxLines: 1),
          ],
        );

    final button = isOutlined 
      ? OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
          child: child,
        )
      : ElevatedButton(onPressed: isLoading ? null : onPressed, style: style, child: child);
    
    return fullWidth ? SizedBox(width: double.infinity, height: 50.h, child: button) : button;
  }

  static Widget loading([String? message]) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: const CircularProgressIndicator(color: AppTheme.primary),
        ),
        if (message != null) ...[
          SizedBox(height: 16.h),
          AutoSizeText(message, style: const TextStyle(color: Colors.white)),
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
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64.sp, color: Colors.grey),
          SizedBox(height: 16.h),
          AutoSizeText(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
          if (subtitle != null) ...[
            SizedBox(height: 8.h),
            AutoSizeText(subtitle, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          ],
          if (buttonText != null && onButtonPressed != null) ...[
            SizedBox(height: 24.h),
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
  }) => emptyState(
    icon: Icons.error_outline,
    title: message,
    buttonText: retryText ?? 'Retry',
    onButtonPressed: onRetry,
  );

  static Widget infoBanner({
    required String title,
    required String message,
    required IconData icon,
    Color color = AppTheme.primary,
    VoidCallback? onAction,
    String? actionText,
  }) => Container(
    padding: EdgeInsets.all(16.w),
    margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8.r),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 24.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoSizeText(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16.sp)),
              SizedBox(height: 4.h),
              AutoSizeText(message, style: TextStyle(color: color.withOpacity(0.8), fontSize: 14.sp)),
            ],
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionText, style: TextStyle(color: color))),
      ],
    ),
  );

  static Widget errorBanner({required String message, VoidCallback? onDismiss}) => 
    infoBanner(
      title: 'Error',
      message: message,
      icon: Icons.error_outline,
      color: Colors.red,
      actionText: onDismiss != null ? 'Dismiss' : null,
      onAction: onDismiss,
    );

  static Widget successBanner({required String message}) => 
    infoBanner(
      title: 'Success',
      message: message,
      icon: Icons.check_circle,
      color: Colors.green,
    );

  static Widget formCard({required String title, IconData? titleIcon, required Widget child}) => 
    AppTheme.buildFormCard(title: title, titleIcon: titleIcon, child: child);

  static Widget sectionTitle(String title) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
    child: AutoSizeText(title, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white)),
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

      return AnimationConfiguration.staggeredList(
        position: 0,
        duration: const Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 50.0,
          child: FadeInAnimation(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isSelected ? themeProvider.primaryColor.withOpacity(0.2) : 
                       isCurrentTrack ? themeProvider.primaryColor.withOpacity(0.1) : 
                       themeProvider.surfaceColor,
                borderRadius: BorderRadius.circular(12.r),
                border: isCurrentTrack ? Border.all(color: themeProvider.primaryColor, width: 2) : null,
              ),
              child: ListTile(
                leading: onSelectionChanged != null
                    ? Checkbox(value: isSelected, onChanged: onSelectionChanged, activeColor: themeProvider.primaryColor)
                    : _buildTrackImage(track.imageUrl, themeProvider.surfaceColor),
                title: AutoSizeText(track.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16.sp), maxLines: 1),
                subtitle: AutoSizeText(track.artist, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14.sp), maxLines: 1),
                trailing: _buildTrackActions(showAddButton, showPlayButton, onAdd, onPlay, onRemove, trackIsPlaying, themeProvider),
                onTap: onTap,
              ),
            ),
          ),
        ),
      );
    },
  );

  static Widget playlistCard({
    required Playlist playlist,
    required VoidCallback? onTap,
    VoidCallback? onPlay,
    bool showPlayButton = false,
  }) => Card(
    margin: EdgeInsets.only(bottom: 12.h),
    color: AppTheme.surface,
    child: ListTile(
      leading: _buildPlaylistImage(playlist.imageUrl),
      title: AutoSizeText(playlist.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16.sp), maxLines: 1),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText('${playlist.tracks.length} tracks', style: const TextStyle(color: Colors.grey)),
          AutoSizeText('By ${playlist.creator}', style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
        ],
      ),
      trailing: showPlayButton && onPlay != null
          ? IconButton(icon: Icon(Icons.play_circle_outline, color: AppTheme.primary, size: 24.sp), onPressed: onPlay)
          : Icon(Icons.chevron_right, color: Colors.grey, size: 20.sp),
      onTap: onTap,
    ),
  );

  static Widget _buildPlaylistImage(String? imageUrl) => Container(
    width: 56.w, height: 56.h,
    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8.r)),
    child: imageUrl?.isNotEmpty == true
        ? ClipRRect(borderRadius: BorderRadius.circular(8.r), child: CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover))
        : Icon(Icons.library_music, color: AppTheme.primary, size: 24.sp),
  );

  static Widget _buildTrackImage(String? imageUrl, Color backgroundColor) => Container(
    width: 56.w, height: 56.h,
    decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(8.r)),
    child: imageUrl?.isNotEmpty == true
        ? ClipRRect(borderRadius: BorderRadius.circular(8.r), child: CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover))
        : Icon(Icons.music_note, color: Colors.white, size: 28.sp),
  );

  static Widget _buildTrackActions(bool showAddButton, bool showPlayButton, VoidCallback? onAdd, VoidCallback? onPlay, VoidCallback? onRemove, bool trackIsPlaying, DynamicThemeProvider themeProvider) {
    List<Widget> actions = [];

    if (showPlayButton && onPlay != null) {
      actions.add(IconButton(
        icon: Icon(trackIsPlaying ? Icons.pause : Icons.play_arrow, color: themeProvider.primaryColor, size: 24.sp), 
        onPressed: onPlay,
      ));
    }

    if (showAddButton && onAdd != null) {
      actions.add(IconButton(
        icon: Icon(Icons.add_circle_outline, color: Colors.white, size: 20.sp), 
        onPressed: onAdd,
      ));
    }

    if (onRemove != null) {
      actions.add(IconButton(
        icon: Icon(Icons.remove_circle_outline, color: Colors.red, size: 20.sp), 
        onPressed: onRemove,
      ));
    }

    return actions.isNotEmpty ? Wrap(spacing: 4.w, children: actions) : const SizedBox.shrink();
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
    title: AutoSizeText(title, style: const TextStyle(color: Colors.white)),
    subtitle: subtitle != null ? AutoSizeText(subtitle, style: const TextStyle(color: Colors.grey)) : null,
    secondary: icon != null ? Icon(icon, color: AppTheme.primary) : null,
    activeColor: AppTheme.primary,
  );

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
        Container(width: 8.w, height: 8.h, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 4.w),
        AutoSizeText(text, style: TextStyle(color: color, fontSize: 12.sp)),
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
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32.sp),
            SizedBox(height: 8.h),
            AutoSizeText(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
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
    margin: EdgeInsets.only(bottom: 12.h),
    child: ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8.r)),
        child: Icon(icon, color: AppTheme.primary),
      ),
      title: AutoSizeText(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      subtitle: AutoSizeText(description, style: const TextStyle(color: Colors.grey)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey, size: 20.sp),
      onTap: onTap,
    ),
  );

  static Widget settingsSection({required String title, required List<Widget> items}) => Card(
    color: AppTheme.surface,
    margin: EdgeInsets.only(bottom: 16.h),
    child: Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          SizedBox(height: 8.h),
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
    title: AutoSizeText(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
    subtitle: AutoSizeText(subtitle, style: const TextStyle(color: Colors.grey)),
    trailing: Icon(Icons.chevron_right, color: Colors.grey, size: 20.sp),
    onTap: onTap,
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
          child: SizedBox(height: 600.h, child: emptyState),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      child: AnimationLimiter(
        child: ListView.builder(
          padding: padding ?? EdgeInsets.all(16.w),
          itemCount: items.length,
          itemBuilder: (context, index) => AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: itemBuilder(items[index], index)),
            ),
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
          height: 60.h,
          decoration: BoxDecoration(
            color: themeProvider.surfaceColor,
            boxShadow: [BoxShadow(color: themeProvider.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              Container(
                width: 60.w, height: 60.h,
                child: track.imageUrl?.isNotEmpty == true
                    ? CachedNetworkImage(imageUrl: track.imageUrl!, fit: BoxFit.cover)
                    : Container(color: themeProvider.surfaceColor, child: const Icon(Icons.music_note, color: Colors.white)),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AutoSizeText(track.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      AutoSizeText(track.artist, style: const TextStyle(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
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
