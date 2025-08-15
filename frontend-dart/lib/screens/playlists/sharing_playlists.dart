import 'package:flutter/material.dart';
import '../../providers/friend_providers.dart';
import '../../models/api_models.dart';
import '../../core/theme_core.dart';
import '../../core/constants_core.dart';
import '../../models/music_models.dart';
import '../../widgets/app_widgets.dart';
import '../../services/music_services.dart';
import '../../providers/music_providers.dart';
import '../base_screens.dart';

class PlaylistSharingScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistSharingScreen({super.key, required this.playlist});

  @override
  State<PlaylistSharingScreen> createState() => _PlaylistSharingScreenState();
}

class _PlaylistSharingScreenState extends BaseScreen<PlaylistSharingScreen> {
  List<Friend> _friends = [];
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
          _buildFriendsList(),
          const SizedBox(height: 24),
          if (_selectedFriends.isNotEmpty) _buildShareButton(),
        ],
      ),
    );
  }

  Widget _buildPlaylistInfo() {
    return Center(
      child: AppTheme.buildHeaderCard(
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
            textAlign: TextAlign.center,
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
      ),
    );
  }


  Widget _buildFriendsList() {
    final alreadySharedCount = widget.playlist.sharedWith.length;
    
    if (_friends.isEmpty) {
      final emptyMessage = alreadySharedCount > 0 
        ? 'All $alreadySharedCount friends already have access to this playlist'
        : 'No friends to share with';
      final emptySubtitle = alreadySharedCount > 0
        ? 'This playlist is already shared with all your friends'
        : 'Add friends first to share your playlists';
      
      return AppWidgets.emptyState(
        icon: Icons.people_outline,
        title: emptyMessage,
        subtitle: emptySubtitle,
        buttonText: alreadySharedCount > 0 ? null : 'Add Friends',
        onButtonPressed: alreadySharedCount > 0 ? null : () => Navigator.pushNamed(context, AppRoutes.friends),
      );
    }

    final titleText = alreadySharedCount > 0 
      ? 'Select More Friends ($alreadySharedCount already shared)'
      : 'Select Friends';

    return AppTheme.buildFormCard(
      title: titleText,
      titleIcon: Icons.people,
      child: Column(
        children: [
          AppWidgets.infoBanner(
            title: 'Invite Friends',
            message: 'Select friends below to invite them to collaborate on this playlist',
            icon: Icons.people,
          ),
          const SizedBox(height: 16),
          Text(
            'Choose friends to invite to this playlist (${_selectedFriends.length} selected)',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ..._friends.map((friend) => CheckboxListTile(
            value: _selectedFriends.contains(friend.id),
            onChanged: (value) => _toggleFriendSelection(friend.id, value ?? false),
            title: Text(friend.username, style: const TextStyle(color: Colors.white)),
            subtitle: Text('ID: ${friend.id}', style: const TextStyle(color: Colors.grey)),
            secondary: CircleAvatar(
              backgroundColor: ThemeUtils.getColorFromString(friend.id),
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
        final sharedWithIds = widget.playlist.sharedWith.map((user) => user.id).toSet();
        setState(() {
          _friends = friendProvider.friends.where((friend) => !sharedWithIds.contains(friend.id)).toList();
        });
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
      await runAsyncAction(
        () async {
          final musicService = getProvider<MusicService>();
          final token = auth.token!;
          
          for (final friendId in _selectedFriends) {
            await musicService.inviteUserToPlaylist(widget.playlist.id, friendId, token);
          }
          
          final newSharedUsers = _selectedFriends.map((friendId) {
            final friend = _friends.firstWhere((f) => f.id == friendId);
            return User(id: friend.id, username: friend.username);
          }).toList();
          
          final updatedPlaylist = Playlist(
            id: widget.playlist.id,
            name: widget.playlist.name,
            description: widget.playlist.description,
            isPublic: widget.playlist.isPublic,
            creator: widget.playlist.creator,
            tracks: widget.playlist.tracks,
            imageUrl: widget.playlist.imageUrl,
            licenseType: widget.playlist.licenseType,
            sharedWith: [...widget.playlist.sharedWith, ...newSharedUsers],
          );
          
          final musicProvider = getProvider<MusicProvider>();
          final playlistIndex = musicProvider.playlists.indexWhere((p) => p.id == widget.playlist.id);
          if (playlistIndex != -1) {
            musicProvider.playlists[playlistIndex] = updatedPlaylist;
          }
          
          if (mounted) {
            showSuccess('Playlist shared with ${_selectedFriends.length} friends!');
            Navigator.pop(context, updatedPlaylist);
          }
        },
        errorMessage: 'Failed to share playlist',
      );
    } finally {
      setState(() => _isSharing = false);
    }
  }

}
