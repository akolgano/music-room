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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surface,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  _buildCover(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.name,
                          style: const TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created by ${playlist.creator}',
                          style: const TextStyle(
                            fontSize: 12, 
                            color: AppTheme.onSurfaceVariant
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.music_note, 
                              size: 14, 
                              color: AppTheme.onSurfaceVariant
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${playlist.tracks.length} songs',
                              style: const TextStyle(
                                fontSize: 12, 
                                color: AppTheme.onSurfaceVariant
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (playlist.isPublic) _buildPublicBadge(),
                          ],
                        ),
                        if (playlist.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            playlist.description,
                            style: const TextStyle(
                              fontSize: 11, 
                              color: AppTheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (onTap != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.library_music, size: 16),
                        label: const Text('View'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.onSurfaceVariant),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  if (onTap != null && onPlay != null) const SizedBox(width: 8),
                  if (onPlay != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onPlay,
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Play'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  if (onPlay != null && onShare != null) const SizedBox(width: 8),
                  if (onShare != null)
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onShare,
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Share'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
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
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          playlist.imageUrl!, 
          width: 60, 
          height: 60, 
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackCover()
        ),
      );
    }
    return _buildFallbackCover();
  }

  Widget _buildFallbackCover() {
    final colors = [Colors.purple, Colors.pink, Colors.blue, Colors.teal, Colors.orange, Colors.red];
    final color = colors[playlist.id.hashCode % colors.length];
    return Container(
      width: 60, 
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.6)]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.library_music, color: Colors.white, size: 24),
    );
  }

  Widget _buildPublicBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.public, size: 10, color: AppTheme.primary),
          SizedBox(width: 2),
          Text(
            'PUBLIC', 
            style: TextStyle(
              fontSize: 9, 
              fontWeight: FontWeight.bold, 
              color: AppTheme.primary
            )
          ),
        ],
      ),
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface,
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  _buildLeading(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.artist,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (track.album.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Album: ${track.album}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.onSurfaceVariant.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onSelectionChanged != null)
                    Checkbox(
                      value: isSelected, 
                      onChanged: onSelectionChanged,
                      activeColor: AppTheme.primary,
                    )
                ],
              ),
              if (onSelectionChanged == null && (onPlay != null || onAdd != null)) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (onPlay != null)
                      Expanded(
                        child: TextButton.icon(
                          onPressed: onPlay,
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 16,
                            color: isPlaying ? AppTheme.primary : Colors.white,
                          ),
                          label: Text(
                            isPlaying ? 'Pause' : 'Preview',
                            style: TextStyle(
                              color: isPlaying ? AppTheme.primary : Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                      ),
                    if (onPlay != null && onAdd != null) 
                      const SizedBox(width: 8),
                    if (onAdd != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onAdd,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading() {
    if (track.imageUrl?.isNotEmpty == true) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          track.imageUrl!, 
          width: 40, 
          height: 40, 
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackImage()
        ),
      );
    }
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    if (isSelected) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.check_circle, color: Colors.white),
      );
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.music_note, color: AppTheme.onSurfaceVariant, size: 20),
    );
  }
}
