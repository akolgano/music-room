import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/music_models.dart';
import '../core/constants_core.dart';
import 'state_widgets.dart';

class AppWidgets {
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
    color: Theme.of(context).colorScheme.onSurface, fontSize: _responsiveValue(16.0), fontWeight: FontWeight.w600
  );
  
  static TextStyle _secondaryStyle(BuildContext context) => TextStyle(
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: _responsiveValue(14.0)
  );

  static Color _getTrackCardColor(ColorScheme colorScheme, bool isSelected, bool isCurrentTrack) {
    if (isSelected) return colorScheme.primary.withValues(alpha: 0.2);
    if (isCurrentTrack) return colorScheme.primary.withValues(alpha: 0.1);
    return colorScheme.surface;
  }

  static Widget _buildImage(
    String? imageUrl, 
    double size, {
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: kIsWeb ? size : size.w.toDouble(),
        height: kIsWeb ? size : size.h.toDouble(),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(kIsWeb ? 8.0 : 8.r.toDouble())
        ),
        child: errorWidget ?? Icon(
          Icons.music_note,
          color: Colors.grey.shade600,
          size: kIsWeb ? size * 0.5 : (size * 0.5).sp.toDouble()
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(kIsWeb ? 8.0 : 8.r.toDouble()),
      child: CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover),
    );
  }

  static Widget loading([String? message]) => StateWidgets.loading(message);

  static Widget emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) => StateWidgets.emptyState(
    icon: icon,
    title: title,
    subtitle: subtitle,
    buttonText: buttonText,
    onButtonPressed: onButtonPressed,
  );

  static void showSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(
          horizontal: _responsiveWidth(16.0),
          vertical: _responsiveHeight(16.0),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }

  static Widget errorState({required String message, VoidCallback? onRetry, String? retryText}) {
    return emptyState(
      icon: Icons.error_outline,
      title: message,
      buttonText: onRetry != null ? (retryText ?? 'Retry') : null,
      onButtonPressed: onRetry,
    );
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
                      minHeight: constraints.maxHeight.isFinite
                          ? constraints.maxHeight
                          : MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: emptyState,
                  ),
                );
              },
            )
          : SingleChildScrollView(
              padding: padding,
              child: Column(
                children: items.asMap().entries.map((entry) => 
                  itemBuilder(entry.value, entry.key)
                ).toList(),
              ),
            ),
    );
  }

  static Future<String?> showTextInputDialog(
    BuildContext context, {
    required String title,
    String? hintText,
    String? initialValue,
    String? Function(String?)? validator,
    int? maxLines = 1,
  }) async {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hintText),
          autofocus: true,
          maxLines: maxLines,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool isDangerous = false,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDangerous ? TextButton.styleFrom(foregroundColor: Colors.red) : null,
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  static Widget textField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    dynamic suffixIcon,
    dynamic prefixIcon,
    bool enabled = true,
    int? maxLines = 1,
    Function(String)? onChanged,
    Function(String)? onFieldSubmitted,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    Widget? suffixWidget;
    Widget? prefixWidget;
    
    if (suffixIcon != null) {
      suffixWidget = suffixIcon is Widget ? suffixIcon : Icon(suffixIcon as IconData);
    }
    
    if (prefixIcon != null) {
      prefixWidget = prefixIcon is Widget ? prefixIcon : Icon(prefixIcon as IconData);
    }
    
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      maxLines: maxLines,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        suffixIcon: suffixWidget,
        prefixIcon: prefixWidget,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _responsiveWidth(16.0),
          vertical: _responsiveHeight(12.0),
        ),
      ),
    );
  }

  static Widget primaryButton({
    required BuildContext context,
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = true,
  }) {
    final content = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16),
                SizedBox(width: _responsiveWidth(8)),
              ],
              Text(text),
            ],
          );

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: content,
    );

    return fullWidth
        ? SizedBox(
            width: double.infinity,
            child: button,
          )
        : button;
  }

  static Widget secondaryButton({
    required BuildContext context,
    required String text,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool fullWidth = false,
  }) {
    final content = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16),
                SizedBox(width: _responsiveWidth(8)),
              ],
              Text(text),
            ],
          );

    final button = OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      child: content,
    );

    return fullWidth
        ? SizedBox(
            width: double.infinity,
            child: button,
          )
        : button;
  }

  static Widget infoBanner({
    String? title,
    required String message,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    Color? color,
  }) {
    final bgColor = backgroundColor ?? color ?? Colors.blue.shade50;
    final txtColor = textColor ?? Colors.blue.shade700;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_responsiveWidth(16)),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.info_outline,
            color: txtColor,
            size: 20,
          ),
          SizedBox(width: _responsiveWidth(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title,
                    style: TextStyle(
                      color: txtColor,
                      fontSize: _responsiveValue(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: _responsiveHeight(4)),
                ],
                Text(
                  message,
                  style: TextStyle(
                    color: txtColor,
                    fontSize: _responsiveValue(14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget errorBanner({
    required String message,
    IconData? icon,
    VoidCallback? onDismiss,
  }) {
    final banner = infoBanner(
      message: message,
      icon: icon ?? Icons.error_outline,
      backgroundColor: Colors.red.shade50,
      textColor: Colors.red.shade700,
    );
    
    if (onDismiss != null) {
      return Stack(
        children: [
          banner,
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: onDismiss,
              color: Colors.red.shade700,
            ),
          ),
        ],
      );
    }
    
    return banner;
  }

  static Widget sectionTitle(String title, {String? subtitle}) {
    return Builder(
      builder: (context) => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _responsiveWidth(16),
          vertical: _responsiveHeight(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: _responsiveHeight(4)),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget switchTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
    String? subtitle,
    bool enabled = true,
    IconData? icon,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: enabled ? onChanged : null,
      contentPadding: EdgeInsets.symmetric(horizontal: _responsiveWidth(16)),
      secondary: icon != null ? Icon(icon) : null,
    );
  }

  static Widget playlistCard({
    required Playlist playlist,
    required VoidCallback onTap,
    VoidCallback? onMorePressed,
    VoidCallback? onPlay,
    VoidCallback? onDelete,
    bool showPlayButton = false,
    bool showDeleteButton = false,
    String? currentUsername,
  }) {
    return Builder(
      builder: (context) => Card(
        margin: EdgeInsets.symmetric(
          horizontal: _responsiveWidth(16),
          vertical: _responsiveHeight(8),
        ),
        child: ListTile(
          leading: _buildImage(playlist.imageUrl, 56),
          title: Text(
            playlist.name,
            style: _primaryStyle(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: playlist.description?.isNotEmpty == true
              ? Text(
                  playlist.description!,
                  style: _secondaryStyle(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showPlayButton && onPlay != null)
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: onPlay,
                ),
              if (showDeleteButton && onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: onDelete,
                ),
              if (onMorePressed != null)
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: onMorePressed,
                ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  static Widget settingsItem({
    required String title,
    String? subtitle,
    IconData? leadingIcon,
    IconData? icon,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
    Color? subtitleColor,
    Color? color,
  }) {
    return Builder(
      builder: (context) => ListTile(
        leading: (leadingIcon ?? icon) != null ? Icon(leadingIcon ?? icon, color: color) : null,
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: titleColor,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: subtitleColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: _responsiveWidth(16)),
      ),
    );
  }

  static Widget settingsSection({
    required String title,
    List<Widget>? children,
    List<Widget>? items, // Legacy parameter support
    String? subtitle,
  }) {
    final List<Widget> widgets = children ?? items ?? [];
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionTitle(title, subtitle: subtitle),
          Card(
            margin: EdgeInsets.symmetric(horizontal: _responsiveWidth(16)),
            child: Column(children: widgets),
          ),
          SizedBox(height: _responsiveHeight(16)),
        ],
      ),
    );
  }

  static Widget tabScaffold({
    required List<Tab> tabs,
    required List<Widget> tabViews,
    TabController? controller,
  }) {
    return Builder(
      builder: (context) => DefaultTabController(
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
      ),
    );
  }
}