// lib/screens/music/playlist_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/playlist_license_provider.dart';
import '../../models/models.dart';
import '../../models/collaboration_models.dart'; 
import '../../core/app_core.dart';
import '../../widgets/common_widgets.dart';
import '../../services/websocket_service.dart';
import '../../services/api_service.dart';
import '../../services/music_player_service.dart';
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
  bool _isScreenLoading = false;
  bool _inviteOnlyMode = false;
  Playlist? _playlist;
  List<PlaylistTrack> _playlistTracks = [];
  List<PlaylistCollaborator> _collaborators = [];
  List<String> _notifications = [];
  bool _autoRefresh = true;
  bool get _isEditMode => widget.playlistId != null && widget.playlistId!.isNotEmpty && widget.playlistId != 'null';

  @override
  String get screenTitle => _isEditMode ? 'Edit Playlist' : 'Create Playlist';

  @override
  List<Widget> get actions => _buildAppBarActions();

  @override
  Widget? get floatingActionButton => _isEditMode ? _buildFloatingActionButton() : null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaylist());
    _setupWebSocketListeners();
  }

  @override
  Widget buildContent() {
    if (_isScreenLoading) return buildLoadingState(message: 'Loading playlist...');

    return Column(
      children: [
        if (_notifications.isNotEmpty) _buildNotificationBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshPlaylist,
            color: AppTheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isEditMode) _buildCreateForm(),
                  if (_isEditMode) ...[
                    _buildPlaylistInfoCard(),
                    const SizedBox(height: 16),
                    _buildCollaboratorsSection(),
                    const SizedBox(height: 16),
                    _buildPlaylistForm(),
                    const SizedBox(height: 16),
                    _buildTracksSection(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      if (_isEditMode) ...[
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _sharePlaylist(),
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _showPlaylistSettings(),
        ),
      ],
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => _refreshPlaylist(),
      ),
    ];
  }

  Widget _buildNotificationBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _notifications.last,
              style: const TextStyle(color: Colors.blue, fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.blue, size: 20),
            onPressed: () => setState(() => _notifications.clear()),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistInfoCard() {
    if (_playlist == null) return const SizedBox.shrink();
    
    return AppTheme.buildHeaderCard(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withOpacity(0.2),
            ),
            child: const Icon(Icons.library_music, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            _playlist!.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '${_playlist!.tracks.length} tracks • Created by ${_playlist!.creator}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _playlist!.isPublic ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _playlist!.isPublic ? 'Public' : 'Private',
              style: TextStyle(
                color: _playlist!.isPublic ? Colors.green : Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaboratorsSection() {
    if (_collaborators.isEmpty) return const SizedBox.shrink();
    
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.people, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text('Collaborators', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 12),
            ..._collaborators.map((collaborator) => ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary,
                child: Text(collaborator.username[0].toUpperCase()),
              ),
              title: Text(collaborator.username, style: const TextStyle(color: Colors.white)),
              subtitle: Text(
                collaborator.permissions.map((p) => p.name).join(', '),
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: StatusIndicator(
                isConnected: collaborator.isOnline,
                connectedText: 'Online',
                disconnectedText: 'Offline',
              ),
            )),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.queue_music, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text('Tracks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                Text('${_playlistTracks.length} tracks', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            if (_playlistTracks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.music_note, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No tracks yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _playlistTracks.length,
                onReorder: _onReorderTracks,
                itemBuilder: (context, index) {
                  final playlistTrack = _playlistTracks[index];
                  final track = playlistTrack.track;
                  
                  if (track == null) {
                    return ListTile(
                      key: ValueKey(playlistTrack.trackId),
                      title: Text(playlistTrack.name, style: const TextStyle(color: Colors.white)),
                      subtitle: const Text('Track details unavailable', style: TextStyle(color: Colors.grey)),
                    );
                  }
                  
                  return AppCards.track(
                    key: ValueKey(track.id), 
                    track: track,
                    onTap: () => _playTrack(track),
                    onRemove: () => _removeTrack(track.id),
                    showAddButton: false,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<PlaylistLicenseProvider>(
      builder: (context, licenseProvider, _) {
        final canEdit = licenseProvider.canCurrentUserEdit;
        
        if (!canEdit) return const SizedBox.shrink();
        
        return FloatingActionButton.extended(
          onPressed: _navigateToTrackSearch,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add),
          label: const Text('Add Songs'),
        );
      },
    );
  }

  Widget _buildCreateForm() {
    return AppTheme.buildFormCard(
      title: 'Create New Playlist',
      titleIcon: Icons.add,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormComponents.textField(
            controller: _nameController,
            labelText: 'Playlist Name',
            prefixIcon: Icons.title,
            validator: Validators.playlistName,
          ),
          const SizedBox(height: 16),
          FormComponents.textField(
            controller: _descriptionController,
            labelText: 'Description (optional)',
            prefixIcon: Icons.description,
            maxLines: 3,
            validator: Validators.description,
          ),
          const SizedBox(height: 16),
          _buildVisibilitySwitch(),
          const SizedBox(height: 24),
          FormComponents.button(
            text: 'Create',
            icon: Icons.save,
            onPressed: _createPlaylist,
            isLoading: _isScreenLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistForm() {
    return AppTheme.buildFormCard(
      title: 'Playlist Details',
      titleIcon: Icons.edit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormComponents.textField(
            controller: _nameController,
            labelText: 'Playlist Name',
            prefixIcon: Icons.title,
            validator: Validators.playlistName,
          ),
          const SizedBox(height: 16),
          FormComponents.textField(
            controller: _descriptionController,
            labelText: 'Description (optional)',
            prefixIcon: Icons.description,
            maxLines: 3,
            validator: Validators.description,
          ),
          const SizedBox(height: 16),
          _buildVisibilitySwitch(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FormComponents.button(
                  text: 'Save Changes',
                  icon: Icons.save,
                  onPressed: _savePlaylistChanges,
                  isLoading: _isScreenLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilitySwitch() {
    return FormComponents.switchTile(
      value: _isPublic,
      onChanged: (value) => setState(() => _isPublic = value),
      title: 'Public Playlist',
      subtitle: _isPublic ? 'Anyone can view this playlist' : 'Only you can view this playlist',
      icon: _isPublic ? Icons.public : Icons.lock,
    );
  }

  void _setupWebSocketListeners() {
    if (_isEditMode) {
      _webSocketService.operationsStream.listen((PlaylistOperation operation) {
        if (mounted && operation.userId != auth.userId) {
          _handleRemoteOperation(operation);
        }
      });

      _webSocketService.collaboratorsStream.listen((List<PlaylistCollaborator> collaborators) {
        if (mounted && _autoRefresh) {
          setState(() => _collaborators = collaborators);
        }
      });

      _webSocketService.notificationsStream.listen((String notification) {
        if (mounted) {
          _showNotification(notification);
        }
      });
    }
  }

  void _handleRemoteOperation(PlaylistOperation operation) {
    if (!_autoRefresh) return;
    
    switch (operation.type) {
      case ConflictType.trackMove:
        _applyRemoteTrackMove(operation);
        break;
      case ConflictType.trackAdd:
        _loadPlaylistTracks();
        _showNotification('${operation.username} added a track');
        break;
      case ConflictType.trackRemove:
        final trackId = operation.data['track_id'] as String;
        setState(() {
          _playlistTracks.removeWhere((t) => t.trackId == trackId);
        });
        _showNotification('${operation.username} removed a track');
        break;
      default:
        break;
    }
  }

  void _applyRemoteTrackMove(PlaylistOperation operation) {
    final oldIndex = operation.data['old_index'] as int;
    final newIndex = operation.data['new_index'] as int;
    final trackId = operation.data['track_id'] as String;
    
    if (oldIndex < _playlistTracks.length && 
        _playlistTracks[oldIndex].trackId == trackId) {
      setState(() {
        final track = _playlistTracks.removeAt(oldIndex);
        final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
        _playlistTracks.insert(adjustedNewIndex.clamp(0, _playlistTracks.length), track);
      });
      _showNotification('${operation.username} moved a track');
    }
  }

  void _showNotification(String message) {
    setState(() {
      _notifications.add(message);
      if (_notifications.length > 3) {
        _notifications.removeAt(0);
      }
    });
  }

  Future<void> _loadPlaylist() async {
    if (!_isEditMode) return;
    
    setState(() => _isScreenLoading = true);
    
    try {
      final musicProvider = getProvider<MusicProvider>();
      _playlist = await musicProvider.getPlaylistDetails(widget.playlistId!, auth.token!);
      
      if (_playlist != null) {
        _nameController.text = _playlist!.name;
        _descriptionController.text = _playlist!.description;
        _isPublic = _playlist!.isPublic;
        
        await _loadPlaylistTracks();
        await _connectWebSocket();
      }
    } catch (e) {
      showError('Failed to load playlist: $e');
    } finally {
      setState(() => _isScreenLoading = false);
    }
  }

  Future<void> _loadPlaylistTracks() async {
    if (!_isEditMode) return;
    
    try {
      final musicProvider = getProvider<MusicProvider>();
      await musicProvider.fetchPlaylistTracks(widget.playlistId!, auth.token!);
      setState(() {
        _playlistTracks = musicProvider.playlistTracks;
      });
    } catch (e) {
      showError('Failed to load tracks: $e');
    }
  }

  Future<void> _connectWebSocket() async {
    if (!_isEditMode) return;
    
    try {
      await _webSocketService.connectToPlaylist(
        widget.playlistId!,
        auth.userId!,
        auth.token!,
      );
    } catch (e) {
      print('Failed to connect WebSocket: $e');
    }
  }

  Future<void> _refreshPlaylist() async {
    if (_isEditMode) {
      await _loadPlaylist();
    }
  }

  Future<void> _createPlaylist() async {
    setState(() => _isScreenLoading = true);
    
    try {
      final musicProvider = getProvider<MusicProvider>();
      final deviceProvider = getProvider<DeviceProvider>();
      
      final playlistId = await musicProvider.createPlaylist(
        _nameController.text,
        _descriptionController.text,
        _isPublic,
        auth.token!,
        deviceProvider.deviceUuid,
      );
      
      if (playlistId != null) {
        showSuccess('Playlist created successfully!');
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.playlistEditor,
          arguments: playlistId,
        );
      }
    } catch (e) {
      showError('Failed to create playlist: $e');
    } finally {
      setState(() => _isScreenLoading = false);
    }
  }

  Future<void> _savePlaylistChanges() async {
    if (!_isEditMode) return;
    
    setState(() => _isScreenLoading = true);
    
    try {
      final musicProvider = getProvider<MusicProvider>();
      
      await musicProvider.updatePlaylistDetails(
        playlistId: widget.playlistId!,
        name: _nameController.text,
        description: _descriptionController.text,
        isPublic: _isPublic,
        token: auth.token!,
      );
      
      showSuccess('Playlist updated successfully!');
      await _loadPlaylist();
    } catch (e) {
      showError('Failed to update playlist: $e');
    } finally {
      setState(() => _isScreenLoading = false);
    }
  }

  void _navigateToTrackSearch() {
    Navigator.pushNamed(context, AppRoutes.trackSearch, arguments: widget.playlistId);
  }

  void _onReorderTracks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    setState(() {
      final track = _playlistTracks.removeAt(oldIndex);
      _playlistTracks.insert(newIndex, track);
    });
    
    if (_isEditMode) {
      _webSocketService.sendTrackMove(
        _playlistTracks[newIndex].trackId,
        oldIndex,
        newIndex,
        auth.username ?? 'User',
      );
    }
    
    _updateTrackPositions();
  }

  Future<void> _updateTrackPositions() async {
    if (!_isEditMode) return;
    
    try {
      final musicProvider = getProvider<MusicProvider>();
      await musicProvider.moveTrackInPlaylist(
        playlistId: widget.playlistId!,
        rangeStart: 0,
        insertBefore: _playlistTracks.length,
        token: auth.token!,
      );
    } catch (e) {
      showError('Failed to update track positions: $e');
    }
  }

  Future<void> _removeTrack(String trackId) async {
    final confirmed = await showConfirmDialog(
      'Remove Track',
      'Are you sure you want to remove this track from the playlist?',
    );
    
    if (confirmed) {
      try {
        final musicProvider = getProvider<MusicProvider>();
        final deviceProvider = getProvider<DeviceProvider>();
        
        await musicProvider.removeTrackFromPlaylist(
          playlistId: widget.playlistId!,
          trackId: trackId,
          token: auth.token!,
          deviceUuid: deviceProvider.deviceUuid,
        );
        
        showSuccess('Track removed from playlist');
      } catch (e) {
        showError('Failed to remove track: $e');
      }
    }
  }

  Future<void> _playTrack(Track track) async {
    try {
      final playerService = getProvider<MusicPlayerService>();
      
      if (track.previewUrl != null && track.previewUrl!.isNotEmpty) {
        await playerService.playTrack(track, track.previewUrl!);
        showSuccess('Playing "${track.name}"');
      } else {
        showError('No preview available for this track');
      }
    } catch (e) {
      showError('Failed to play track: $e');
    }
  }

  void _sharePlaylist() {
    if (_playlist != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.playlistSharing,
        arguments: _playlist,
      );
    }
  }

  void _showPlaylistSettings() {
    DialogUtils.showInfoDialog(
      context: context,
      title: 'Playlist Settings',
      message: 'Advanced playlist settings coming soon!',
      icon: Icons.settings,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    if (_isEditMode) _webSocketService.disconnect();
    super.dispose();
  }
}
