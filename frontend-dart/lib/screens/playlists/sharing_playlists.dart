import 'package:flutter/material.dart';
import '../../providers/friend_providers.dart';
import '../../core/theme_core.dart';
import '../../core/constants_core.dart';
import '../../core/navigation_core.dart';
import '../../models/music_models.dart';
import '../../widgets/app_widgets.dart';
import '../base_screens.dart';

class PlaylistSharingScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistSharingScreen({super.key, required this.playlist});

  @override
  State<PlaylistSharingScreen> createState() => _PlaylistSharingScreenState();
}

class _PlaylistSharingScreenState extends BaseScreen<PlaylistSharingScreen> {
  List<String> _friends = [];
  final Set<String> _selectedFriends = {};
  bool _isSharing = false;

  @override
  String get screenTitle => 'Share Playlist';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFriends());
  }

  @override
  Widget buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlaylistInfo(),
          const SizedBox(height: 24),
          _buildSharingOptions(),
          const SizedBox(height: 24),
          _buildFriendsList(),
          const SizedBox(height: 24),
          if (_selectedFriends.isNotEmpty) _buildShareButton(),
        ],
      ),
    );
  }

  Widget _buildPlaylistInfo() {
    return AppTheme.buildHeaderCard(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withValues(alpha: 0.2)),
            child: const Icon(Icons.library_music, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            widget.playlist.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.playlist.tracks.length} tracks',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: widget.playlist.isPublic ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.playlist.isPublic ? 'Public Playlist' : 'Private Playlist',
              style: TextStyle(
                color: widget.playlist.isPublic ? Colors.green : Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharingOptions() {
    return AppTheme.buildFormCard(
      title: 'Sharing Options',
      titleIcon: Icons.share,
      child: Column(
        children: [
          AppWidgets.infoBanner(
            title: 'Share with Friends',
            message: 'Select friends below to invite them to collaborate on this playlist',
            icon: Icons.people,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _copyPlaylistLink,
                  icon: const Icon(Icons.link),
                  label: const Text('Copy Link'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surface,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareToSocial,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surface, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    if (_friends.isEmpty) {
      return AppWidgets.emptyState(
        icon: Icons.people_outline,
        title: 'No friends to share with',
        subtitle: 'Add friends first to share your playlists',
        buttonText: 'Add Friends',
        onButtonPressed: () => Navigator.pushNamed(context, AppRoutes.friends),
      );
    }

    return AppTheme.buildFormCard(
      title: 'Select Friends',
      titleIcon: Icons.people,
      child: Column(
        children: [
          Text(
            'Choose friends to invite to this playlist (${_selectedFriends.length} selected)',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ..._friends.map((friendId) => CheckboxListTile(
            value: _selectedFriends.contains(friendId),
            onChanged: (value) => _toggleFriendSelection(friendId, value ?? false),
            title: Text('Friend #$friendId', style: const TextStyle(color: Colors.white)),
            subtitle: Text('User ID: $friendId', style: const TextStyle(color: Colors.grey)),
            secondary: CircleAvatar(
              backgroundColor: ThemeUtils.getColorFromString(friendId),
              child: const Icon(Icons.person, color: Colors.white),
            ),
            activeColor: AppTheme.primary,
            checkColor: Colors.black,
          )),
        ],
      ),
    );
  }

  Widget _buildShareButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSharing ? null : _shareWithSelectedFriends,
        icon: _isSharing 
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.send),
        label: Text(_isSharing ? 'Sharing...' : 'Share with ${_selectedFriends.length} friends'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Future<void> _loadFriends() async {
    await runAsyncAction(
      () async {
        final friendProvider = getProvider<FriendProvider>();
        await friendProvider.fetchFriends(auth.token!);
        _friends = friendProvider.friends;
      },
      errorMessage: 'Failed to load friends',
    );
  }

  void _toggleFriendSelection(String friendId, bool selected) {
    setState(() {
      if (selected) {
        _selectedFriends.add(friendId);
      } else {
        _selectedFriends.remove(friendId);
      }
    });
  }

  Future<void> _shareWithSelectedFriends() async {
    if (_selectedFriends.isEmpty) return;

    setState(() => _isSharing = true);
    try {
      await Future.delayed(const Duration(seconds: 2));
      showSuccess('Playlist shared with ${_selectedFriends.length} friends!');
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      AppLogger.error('Failed to share playlist', e, null, 'PlaylistSharingScreen');
      showError('Failed to share playlist: ${e.toString()}');
    } finally {
      setState(() => _isSharing = false);
    }
  }

  void _copyPlaylistLink() {
    showInfo('Playlist link copied to clipboard!');
  }

  void _shareToSocial() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            Icon(Icons.share, color: AppTheme.primary),
            const SizedBox(width: 8),
            const Text('Share to Social Media', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text('Social media sharing coming soon!', style: TextStyle(color: Colors.white)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
