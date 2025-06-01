// lib/screens/music/components/playlist_info_form.dart
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../widgets/common_widgets.dart';

class PlaylistInfoForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final bool isPublic;
  final bool isEditMode;
  final ValueChanged<bool> onVisibilityChanged;
  final VoidCallback onToggleVisibility;

  const PlaylistInfoForm({
    Key? key,
    required this.nameController,
    required this.descriptionController,
    required this.isPublic,
    required this.isEditMode,
    required this.onVisibilityChanged,
    required this.onToggleVisibility,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isEditMode ? Icons.edit : Icons.add, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(isEditMode ? 'Playlist Details' : 'Create New Playlist', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(controller: nameController, labelText: 'Playlist Name', prefixIcon: Icons.title, validator: (value) => (value?.isEmpty ?? true) ? 'Please enter a playlist name' : null),
            const SizedBox(height: 16),
            AppTextField(controller: descriptionController, labelText: 'Description (optional)', prefixIcon: Icons.description, maxLines: 3),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(isPublic ? 'Public Playlist' : 'Private Playlist', style: const TextStyle(color: Colors.white)),
              subtitle: Text(isPublic ? 'Anyone can view and add to this playlist' : 'Only you can view and edit this playlist', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              value: isPublic,
              onChanged: onVisibilityChanged,
              activeColor: AppTheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
