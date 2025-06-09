// lib/screens/music/playlist_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/friend_provider.dart';
import '../../models/models.dart';
import '../../core/app_core.dart';
import '../../widgets/common_widgets.dart';
import '../../services/websocket_service.dart';
import '../../services/api_service.dart';
import '../../utils/dialog_utils.dart';
import '../base_screen.dart';

class PlaylistEditorScreen extends StatefulWidget {
  final String? playlistId;

  const PlaylistEditorScreen({Key? key, this.playlistId}) : super(key: key);

  @override
  State<PlaylistEditorScreen> createState() => _PlaylistEditorScreenState();
}

class _PlaylistEditorScreenState extends BaseScreen<PlaylistEditorScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final WebSocketService _webSocketService = WebSocketService();
  final ApiService _apiService = ApiService();
  
  bool _isPublic = false;
  Playlist? _playlist;
  List<PlaylistTrack> _playlistTracks = [];
  List<int> _friends = [];

  @override
  String get screenTitle => _isEditMode ? AppStrings.editPlaylist : AppStrings.createPlaylist;

  @override
  List<Widget> get actions => _buildAppBarActions();

  @override
  Widget? get floatingActionButton => _isEditMode ? _buildFloatingActionButton() : null;

  bool get _isEditMode => widget.playlistId != null && 
                         widget.playlistId!.isNotEmpty && 
                         widget.playlistId != 'null';

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaylist());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFriends());
    _setupWebSocketListener();
  }

  @override
  Widget buildContent() {
    if (isLoading) {
      return buildLoadingState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isEditMode) _buildCreatePlaylistHeader(),
          _buildPlaylistForm(),
          const SizedBox(height: 32),
          if (_isEditMode) _buildTracksSection(),
        ],
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (!_isEditMode) {
      return [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AppButton(
            text: 'Create',
            icon: Icons.save,
            onPressed: _createPlaylist,
            isLoading: isLoading,
          ),
        ),
      ];
    }

    return [
      IconButton(
        icon: const Icon(Icons.person_add),
        onPressed: _inviteUser,
        tooltip: 'Invite Friend',
      ),
      TextButton.icon(
        icon: Icon(_isPublic ? Icons.public : Icons.lock, size: 16),
        label: Text(_isPublic ? 'Public' : 'Private', style: const TextStyle(fontSize: 12)),
        onPressed: _toggleVisibility,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
    ];
  }

  Widget _buildCreatePlaylistHeader() {
    return InfoBanner(
      title: 'Getting Started',
      message: 'Create your custom playlist by giving it a name and description. You can add songs later!',
      icon: Icons.lightbulb,
    );
  }

  Widget _buildPlaylistForm() {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_isEditMode ? Icons.edit : Icons.add, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(_isEditMode ? 'Playlist Details' : 'Create New Playlist', 
                     style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                if (_isEditMode && _webSocketService.isConnected)
                  StatusIndicator(isConnected: _webSocketService.isConnected),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _nameController,
              labelText: 'Playlist Name',
              prefixIcon: Icons.title,
              validator: Validators.playlistName,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              labelText: 'Description (optional)',
              prefixIcon: Icons.description,
              maxLines: 3,
              validator: Validators.description,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(_isPublic ? 'Public Playlist' : 'Private Playlist', 
                          style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                _isPublic ? 'Anyone can view this playlist' : 'Only you can view this playlist',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
              activeColor: AppTheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTracksSection() {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.queue_music, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Tracks (${_playlistTracks.length})', 
                     style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                if (_webSocketService.isConnected)
                  StatusIndicator(isConnected: _webSocketService.isConnected),
              ],
            ),
            const SizedBox(height: 16),
            if (_playlistTracks.isEmpty)
              _buildEmptyTracksState()
            else
              _buildReorderableTracksList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTracksState() {
    return EmptyState(
      icon: Icons.music_note,
      title: 'No tracks added yet',
      subtitle: 'Add some songs to get started!',
      buttonText: 'Add Songs',
      onButtonPressed: _navigateToTrackSearch,
    );
  }

  Widget _buildReorderableTracksList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _playlistTracks.length,
      onReorder: _reorderTracks,
      itemBuilder: (context, index) {
        final track = _playlistTracks[index];
        return Card(
          key: ValueKey(track.trackId),
          margin: const EdgeInsets.only(bottom: 8),
          color: AppTheme.surfaceVariant,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${index + 1}', 
                         style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            title: Text(track.name, style: const TextStyle(color: Colors.white), 
                        maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('Position: ${track.position}', 
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.drag_handle, color: Colors.grey.withOpacity(0.7)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => _removeTrack(track),
                  tooltip: 'Remove track',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _navigateToTrackSearch,
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.add),
      label: const Text('Add Songs'),
    );
  }

  void _setupWebSocketListener() {
    if (_isEditMode) {
      _webSocketService.playlistTracksStream.listen((tracks) {
        if (mounted) {
          setState(() {
            _playlistTracks = tracks;
          });
        }
      });
    }
  }

  Future<void> _loadFriends() async {
    await runAsync(() async {
      final friendProvider = Provider.of<FriendProvider>(context, listen: false);
      await friendProvider.fetchFriends(auth.token!);
      _friends = friendProvider.friends;
    });
  }

  Future<void> _loadPlaylist() async {
    if (!_isEditMode) return;

    await runAsyncAction(
      () async {
        final musicProvider = Provider.of<MusicProvider>(context, listen: false);
        
        _playlist = await musicProvider.getPlaylistDetails(widget.playlistId!, auth.token!);
        
        if (_playlist != null) {
          _nameController.text = _playlist!.name;
          _descriptionController.text = _playlist!.description;
          _isPublic = _playlist!.isPublic;
          
          await musicProvider.fetchPlaylistTracks(widget.playlistId!, auth.token!);
          _playlistTracks = List.from(musicProvider.playlistTracks);
          
          await _webSocketService.connectToPlaylist(widget.playlistId!);
          setState(() {});
        }
      },
      errorMessage: 'Failed to load playlist',
    );
  }

  Future<void> _createPlaylist() async {
    if (_nameController.text.isEmpty) {
      showError('Please give your playlist a name');
      return;
    }

    await runAsyncAction(
      () async {
        final musicProvider = Provider.of<MusicProvider>(context, listen: false);
        final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

        final playlistId = await musicProvider.createPlaylist(
          _nameController.text,
          _descriptionController.text,
          _isPublic,
          auth.token!,
          deviceProvider.deviceUuid,
        );
 
        if (playlistId != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PlaylistEditorScreen(playlistId: playlistId),
            ),
          );
        }
      },
      successMessage: 'Playlist created successfully!',
      errorMessage: 'Failed to create playlist',
    );
  }

  Future<void> _reorderTracks(int oldIndex, int newIndex) async {
    if (!_isEditMode) return;
    
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    await runAsyncAction(
      () async {
        await _apiService.moveTrackInPlaylist(
          playlistId: widget.playlistId!,
          rangeStart: oldIndex,
          insertBefore: newIndex,
          token: auth.token!,
        );
      },
      successMessage: 'Track moved successfully',
      errorMessage: 'Failed to move track',
    );
  }

  Future<void> _removeTrack(PlaylistTrack track) async {
    final confirm = await DialogUtils.showDeleteConfirmDialog(context, track.name);

    if (confirm == true && _isEditMode) {
      await runAsyncAction(
        () async {
          final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

          await _apiService.removeTrackFromPlaylist(
            playlistId: widget.playlistId!,
            trackId: track.trackId,
            token: auth.token!,
            deviceUuid: deviceProvider.deviceUuid,
          );
        },
        successMessage: AppStrings.trackRemoved,
        errorMessage: 'Unable to remove track',
      );
    }
  }

  Future<void> _inviteUser() async {
    if (!_isEditMode || _friends.isEmpty) {
      showError('No friends to invite');
      return;
    }

    final selectedIndex = await DialogUtils.showSelectionDialog<int>(
      context: context,
      title: 'Invite Friend',
      items: _friends,
      itemTitle: (friendId) => 'Friend #$friendId',
      itemLeading: (friendId) => CircleAvatar(
        backgroundColor: AppTheme.primary,
        child: Text(friendId.toString()[0]),
      ),
    );

    if (selectedIndex != null) {
      await runAsyncAction(
        () async {
          await _apiService.inviteUserToPlaylist(
            playlistId: widget.playlistId!,
            userId: _friends[selectedIndex],
            token: auth.token!,
          );
        },
        successMessage: 'User invited to playlist!',
        errorMessage: 'Failed to invite user',
      );
    }
  }

  Future<void> _toggleVisibility() async {
    if (!_isEditMode) return;

    await runAsyncAction(
      () async {
        final musicProvider = Provider.of<MusicProvider>(context, listen: false);
        bool newVisibility = !_isPublic;
        await musicProvider.changePlaylistVisibility(widget.playlistId!, newVisibility, auth.token!);
        setState(() => _isPublic = newVisibility);
      },
      successMessage: 'Playlist is now ${!_isPublic ? 'public' : 'private'}',
      errorMessage: 'Unable to change visibility',
    );
  }

  void _navigateToTrackSearch() {
    navigateTo('/track_search', arguments: widget.playlistId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    if (_isEditMode) {
      _webSocketService.disconnect();
    }
    super.dispose();
  }
}
