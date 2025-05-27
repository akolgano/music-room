// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';

String? validateRequired(String? value, String fieldName) {
  if (value?.isEmpty ?? true) return 'Please enter $fieldName';
  return null;
}

String? validateEmail(String? value) {
  if (value?.isEmpty ?? true) return 'Please enter an email';
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
    return 'Please enter a valid email';
  }
  return null;
}

void showSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppTheme.error : Colors.green,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class StateWidget extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final Widget child;
  final Widget? emptyState;

  const StateWidget({
    Key? key,
    this.isLoading = false,
    this.error,
    this.onRetry,
    required this.child,
    this.emptyState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      );
    }

    return child;
  }
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
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, color: Colors.white)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: const TextStyle(color: AppTheme.onSurfaceVariant), 
                   textAlign: TextAlign.center),
            ],
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onButtonPressed, child: Text(buttonText!)),
            ],
          ],
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.onSurfaceVariant) : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class ItemCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final List<Widget>? badges;
  final List<Widget>? actions;
  final VoidCallback? onTap;

  const ItemCard({
    Key? key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.badges,
    this.actions,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                    ],
                    if (badges != null) ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, children: badges!),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onShare;

  const PlaylistCard({Key? key, required this.playlist, this.onTap, this.onPlay, this.onShare}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ItemCard(
      leading: _buildCover(),
      title: playlist.name,
      subtitle: '${playlist.tracks.length} songs • ${playlist.creator}',
      badges: playlist.isPublic ? [_buildPublicBadge()] : null,
      actions: [
        if (onPlay != null) _buildPlayButton(onPlay!),
        if (onShare != null) IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: onShare),
      ],
      onTap: onTap,
    );
  }

  Widget _buildCover() {
    if (playlist.imageUrl?.isNotEmpty == true) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(playlist.imageUrl!, width: 64, height: 64, fit: BoxFit.cover,
               errorBuilder: (_, __, ___) => _buildFallbackCover()),
      );
    }
    return _buildFallbackCover();
  }

  Widget _buildFallbackCover() {
    final colors = [Colors.purple, Colors.pink, Colors.blue, Colors.teal, Colors.orange, Colors.red];
    final color = colors[playlist.id.hashCode % colors.length];
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.6)]),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.music_note, color: Colors.white, size: 30),
    );
  }

  Widget _buildPublicBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text('PUBLIC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary)),
    );
  }

  Widget _buildPlayButton(VoidCallback onPressed) {
    return IconButton(
      icon: Container(
        decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
        padding: const EdgeInsets.all(4.0),
        child: const Icon(Icons.play_arrow, color: Colors.black, size: 20),
      ),
      onPressed: onPressed,
    );
  }
}

class TrackCard extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onAdd;
  final ValueChanged<bool?>? onSelectionChanged;

  const TrackCard({
    Key? key,
    required this.track,
    this.isPlaying = false,
    this.isSelected = false,
    this.onTap,
    this.onPlay,
    this.onAdd,
    this.onSelectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ItemCard(
      leading: _buildLeading(),
      title: track.name,
      subtitle: '${track.artist} - ${track.album}',
      actions: [
        if (onSelectionChanged != null)
          Checkbox(value: isSelected, onChanged: onSelectionChanged)
        else ...[
          if (onPlay != null)
            IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                        color: isPlaying ? AppTheme.primary : Colors.white),
              onPressed: onPlay,
            ),
          if (onAdd != null)
            IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: onAdd),
        ],
      ],
      onTap: onTap,
    );
  }

  Widget _buildLeading() {
    if (track.imageUrl?.isNotEmpty == true) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(track.imageUrl!, width: 50, height: 50, fit: BoxFit.cover,
               errorBuilder: (_, __, ___) => _buildFallbackImage()),
      );
    }
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return isSelected
        ? const Icon(Icons.check_circle, color: Colors.blue)
        : CircleAvatar(backgroundColor: Colors.grey[300], child: const Icon(Icons.music_note));
  }
}
