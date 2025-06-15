// lib/screens/music/playlist_sharing_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../models/models.dart';
import '../../core/consolidated_core.dart';
import '../../widgets/unified_components.dart';
import '../base_screen.dart';

class PlaylistSharingScreen extends StatefulWidget {
  final Playlist playlist;
  
  const PlaylistSharingScreen({Key? key, required this.playlist}) : super(key: key);

  @override
  State<PlaylistSharingScreen> createState() => _PlaylistSharingScreenState();
}

class _PlaylistSharingScreenState extends BaseScreen<PlaylistSharingScreen> {
  bool _isPublic = false;
  String? _shareLink;
  
  @override
  String get screenTitle => 'Share Playlist';
  
  @override
  void initState() {
    super.initState();
    _isPublic = widget.playlist.isPublic;
    if (_isPublic) {
      _generateShareLink();
    }
  }
  
  @override
  Widget buildContent() {
    return SingleChildScrollView(
      padding: AppSizes.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlaylistInfoCard(),
          const SizedBox(height: 24),
          if (_isPublic) ...[
            UnifiedComponents.sectionTitle('Share Options'),
            const SizedBox(height: 16),
            _buildShareCard(),
            const SizedBox(height: 24),
            _buildVisibilityCard(),
          ] else ...[
            buildEmptyState(
              icon: Icons.lock,
              title: 'This playlist is currently private',
              subtitle: 'Enable public sharing to generate a share link',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaylistInfoCard() {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: AppSizes.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.playlist.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text('Created by: ${widget.playlist.creator}', style: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('${widget.playlist.tracks.length} tracks', style: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Public Playlist', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                _isPublic ? 'Anyone with the link can view this playlist' : 'Only you can see this playlist',
                style: const TextStyle(color: AppTheme.onSurfaceVariant),
              ),
              value: _isPublic,
              onChanged: (value) => _togglePublicStatus(),
              activeColor: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareCard() {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: AppSizes.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Playlist Link:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _shareLink ?? 'Generating link...',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white),
                    onPressed: () => showSuccess('Link copied to clipboard'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Share via:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareButton(icon: Icons.message, label: 'Message', color: Colors.blue),
                _buildShareButton(icon: Icons.email, label: 'Email', color: Colors.red),
                _buildShareButton(icon: Icons.share, label: 'Social', color: Colors.purple),
                _buildShareButton(icon: Icons.more_horiz, label: 'More', color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityCard() {
    return UnifiedComponents.settingsSection(
      title: 'Who can see this playlist',
      items: [
        UnifiedComponents.settingsItem(
          icon: Icons.public,
          title: 'Public',
          subtitle: 'Anyone with the link',
          onTap: () {},
          color: _isPublic ? AppTheme.primary : Colors.white,
        ),
        UnifiedComponents.settingsItem(
          icon: Icons.group,
          title: 'Friends Only',
          subtitle: 'Only people you follow',
          onTap: () => showInfo('This feature is coming soon!'),
        ),
        UnifiedComponents.settingsItem(
          icon: Icons.lock,
          title: 'Private',
          subtitle: 'Only you',
          onTap: () => _togglePublicStatus(),
        ),
      ],
    );
  }

  Widget _buildShareButton({required IconData icon, required String label, required Color color}) {
    return InkWell(
      onTap: () => showInfo('Sharing via $label'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              radius: 20,
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePublicStatus() async {
    await runAsyncAction(
      () async {
        final musicProvider = Provider.of<MusicProvider>(context, listen: false);
        final success = await musicProvider.changePlaylistVisibility(
          widget.playlist.id,
          !_isPublic,
          auth.token!,
        );
        
        if (success) {
          setState(() {
            _isPublic = !_isPublic;
            if (_isPublic) {
              _generateShareLink();
            } else {
              _shareLink = null;
            }
          });
        }
      },
      successMessage: _isPublic ? 'Playlist is now public and can be shared' : 'Playlist is now private',
      errorMessage: 'Failed to update playlist visibility',
    );
  }
  
  Future<void> _generateShareLink() async {
    await Future.delayed(AppDurations.mediumDelay);
    setState(() {
      _shareLink = 'musicroom://playlists/${widget.playlist.id}';
    });
  }
}
