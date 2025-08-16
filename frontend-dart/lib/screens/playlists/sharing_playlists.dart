import 'package:flutter/material.dart';
import '../../providers/friend_providers.dart';
import '../../models/api_models.dart';
import '../../core/theme_core.dart';
import '../../core/constants_core.dart';
import '../../models/music_models.dart';
import '../../widgets/app_widgets.dart';
import '../../services/music_services.dart';
import '../../providers/music_providers.dart';
import '../../core/locator_core.dart';
import '../../core/navigation_core.dart';
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
    final currentUserId = auth.currentUser?.id;
    final actualSharedUsers = widget.playlist.sharedWith.where((user) => user.id != currentUserId).toList();
    final alreadySharedCount = actualSharedUsers.length;
    
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
    AppLogger.debug('Building share button - isSharing: $_isSharing, selectedFriends: $_selectedFriends', 'PlaylistSharingScreen');
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSharing ? null : () {
          AppLogger.debug('Share button pressed!', 'PlaylistSharingScreen');
          _shareWithSelectedFriends();
        },
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
        
        final currentUserId = auth.currentUser?.id;
        
        final actualSharedUsers = widget.playlist.sharedWith.where((user) => user.id != currentUserId).toList();
        final sharedWithIds = actualSharedUsers.map((user) => user.id).toSet();
        AppLogger.debug('Current user ID: $currentUserId', 'PlaylistSharingScreen');
        AppLogger.debug('Raw shared with IDs: ${widget.playlist.sharedWith.map((u) => u.id).toSet()}', 'PlaylistSharingScreen');
        AppLogger.debug('Filtered shared with IDs (excluding self): $sharedWithIds', 'PlaylistSharingScreen');
        AppLogger.debug('All friends before filtering: ${friendProvider.friends.map((f) => 'ID: ${f.id}, Username: ${f.username}').toList()}', 'PlaylistSharingScreen');
        
        final filteredFriends = friendProvider.friends.where((friend) {
          final isNotShared = !sharedWithIds.contains(friend.id);
          AppLogger.debug('Friend ${friend.username} (${friend.id}) - isNotShared: $isNotShared', 'PlaylistSharingScreen');
          return isNotShared;
        }).toList();
        
        setState(() {
          _friends = filteredFriends;
        });
        
        AppLogger.debug('Final filtered friends: ${_friends.map((f) => 'ID: ${f.id}, Username: ${f.username}').toList()}', 'PlaylistSharingScreen');
      },
      errorMessage: 'Failed to load friends',
    );
  }

  void _toggleFriendSelection(String friendId, bool selected) {
    AppLogger.debug('Toggling friend selection - friendId: $friendId, selected: $selected', 'PlaylistSharingScreen');
    setState(() {
      if (selected) {
        _selectedFriends.add(friendId);
        AppLogger.debug('Added friend to selection. Selected friends: $_selectedFriends', 'PlaylistSharingScreen');
      } else {
        _selectedFriends.remove(friendId);
        AppLogger.debug('Removed friend from selection. Selected friends: $_selectedFriends', 'PlaylistSharingScreen');
      }
    });
  }

  Future<void> _shareWithSelectedFriends() async {
    AppLogger.debug('_shareWithSelectedFriends called - selectedFriends: $_selectedFriends', 'PlaylistSharingScreen');
    
    if (_selectedFriends.isEmpty) {
      AppLogger.debug('No friends selected, returning early', 'PlaylistSharingScreen');
      return;
    }

    AppLogger.debug('Setting isSharing to true', 'PlaylistSharingScreen');
    setState(() => _isSharing = true);
    
    AppLogger.debug('About to call runAsyncAction', 'PlaylistSharingScreen');
    try {
      AppLogger.debug('Inside sharing logic - starting direct execution', 'PlaylistSharingScreen');
      AppLogger.debug('Getting MusicService from service locator...', 'PlaylistSharingScreen');
      final musicService = getIt<MusicService>();
      AppLogger.debug('MusicService obtained: $musicService', 'PlaylistSharingScreen');
      AppLogger.debug('Getting auth token...', 'PlaylistSharingScreen');
      final token = auth.token!;
      AppLogger.debug('Auth token obtained (length: ${token.length})', 'PlaylistSharingScreen');
      
      AppLogger.debug('Starting to share playlist ${widget.playlist.id} with friends: $_selectedFriends', 'PlaylistSharingScreen');
      
      for (final friendId in _selectedFriends) {
        AppLogger.debug('Inviting user $friendId to playlist ${widget.playlist.id}', 'PlaylistSharingScreen');
        try {
          await musicService.inviteUserToPlaylist(widget.playlist.id, friendId, token);
          AppLogger.debug('Successfully invited user $friendId', 'PlaylistSharingScreen');
        } catch (e) {
          AppLogger.error('Failed to invite user $friendId: $e', null, null, 'PlaylistSharingScreen');
          rethrow;
        }
      }
      
      final newSharedUsers = _selectedFriends.map((friendId) {
        final friend = _friends.firstWhere((f) => f.id == friendId);
        return User(id: friend.id, username: friend.username);
      }).toList();
      
      final updatedSharedWith = [...widget.playlist.sharedWith, ...newSharedUsers];
      
      final musicProvider = getProvider<MusicProvider>();
      musicProvider.updatePlaylistInCache(
        widget.playlist.id,
        sharedWith: updatedSharedWith,
      );
      
      final updatedPlaylist = Playlist(
        id: widget.playlist.id,
        name: widget.playlist.name,
        description: widget.playlist.description,
        isPublic: widget.playlist.isPublic,
        creator: widget.playlist.creator,
        tracks: widget.playlist.tracks,
        imageUrl: widget.playlist.imageUrl,
        licenseType: widget.playlist.licenseType,
        sharedWith: updatedSharedWith,
      );
      
      if (mounted) {
        showSuccess('Playlist shared with ${_selectedFriends.length} friends!');
        Navigator.pop(context, updatedPlaylist);
      }
      AppLogger.debug('Sharing completed successfully', 'PlaylistSharingScreen');
    } catch (e, stackTrace) {
      AppLogger.error('Exception in _shareWithSelectedFriends: $e', e, stackTrace, 'PlaylistSharingScreen');
      if (mounted) {
        showError('Failed to share playlist: $e');
      }
    } finally {
      AppLogger.debug('Setting isSharing to false', 'PlaylistSharingScreen');
      setState(() => _isSharing = false);
    }
  }

}
