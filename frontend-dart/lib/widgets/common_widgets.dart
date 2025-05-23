// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/playlist.dart';
import '../models/track.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: const TextStyle(color: AppTheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
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
              Text(subtitle!, style: const TextStyle(color: AppTheme.onSurfaceVariant), textAlign: TextAlign.center),
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

class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  
  const ErrorWidget({Key? key, required this.message, this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Connection Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
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
  final IconData? prefixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;

  const AppTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.prefixIcon,
    this.obscureText = false,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon != null 
            ? Icon(prefixIcon, color: AppTheme.onSurfaceVariant) 
            : null,
      ),
    );
  }
}

class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;

  const SearchBar({
    Key? key,
    required this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, color: AppTheme.onSurfaceVariant),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppTheme.onSurfaceVariant),
                onPressed: () {
                  controller.clear();
                  onChanged?.call('');
                },
              )
            : null,
      ),
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
    );
  }
}

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onShare;

  const PlaylistCard({
    Key? key,
    required this.playlist,
    this.onTap,
    this.onPlay,
    this.onShare,
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
              _buildCover(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(playlist.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('${playlist.tracks.length} songs • ${playlist.creator}', 
                         style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                    if (playlist.isPublic) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('PUBLIC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      ),
                    ],
                  ],
                ),
              ),
              if (onPlay != null || onShare != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onPlay != null)
                      IconButton(
                        icon: const Icon(Icons.play_arrow, color: AppTheme.primary),
                        onPressed: onPlay,
                      ),
                    if (onShare != null)
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.white),
                        onPressed: onShare,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
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
      child: Icon(Icons.music_note, color: Colors.white, size: 30),
    );
  }
}

class TrackItem extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final bool isSelected;
  final VoidCallback? onPlay;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onSelectionChanged;

  const TrackItem({
    Key? key,
    required this.track,
    this.isPlaying = false,
    this.isSelected = false,
    this.onPlay,
    this.onAdd,
    this.onRemove,
    this.onTap,
    this.onSelectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected ? Colors.blue.withOpacity(0.1) : AppTheme.surface,
      child: ListTile(
        leading: _buildLeading(),
        title: Text(track.name, style: const TextStyle(color: Colors.white)),
        subtitle: Text('${track.artist} - ${track.album}', style: const TextStyle(color: AppTheme.onSurfaceVariant)),
        trailing: _buildTrailing(),
        onTap: onTap,
      ),
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

  Widget _buildTrailing() {
    if (onSelectionChanged != null) {
      return Checkbox(value: isSelected, onChanged: onSelectionChanged);
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onPlay != null)
          IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, 
                      color: isPlaying ? AppTheme.primary : Colors.white),
            onPressed: onPlay,
          ),
        if (onAdd != null) IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: onAdd),
        if (onRemove != null) IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.white), onPressed: onRemove),
      ],
    );
  }
}

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

String? validatePassword(String? value) {
  if (value?.isEmpty ?? true) return 'Please enter a password';
  if (value!.length < 8) return 'Password must be at least 8 characters';
  return null;
}

void showSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppTheme.error : Colors.green,
    ),
  );
}

Future<bool?> showConfirmDialog(BuildContext context, String title, String message) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: Text(message, style: const TextStyle(color: Colors.white)),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirm')),
      ],
    ),
  );
}
