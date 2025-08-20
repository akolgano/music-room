import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import '../../providers/music_providers.dart';
import '../../core/locator_core.dart';
import '../../services/api_services.dart';
import '../../services/websocket_services.dart';
import '../../models/music_models.dart';
import '../../models/api_models.dart';
import '../../core/theme_core.dart';
import '../../core/constants_core.dart';
import '../../core/navigation_core.dart';
import '../../widgets/app_widgets.dart';
import '../base_screens.dart';

class PlaylistEditorScreen extends StatefulWidget {
  final String? playlistId;

  const PlaylistEditorScreen({super.key, this.playlistId});

  @override
  State<PlaylistEditorScreen> createState() => _PlaylistEditorScreenState();
}

class _PlaylistEditorScreenState extends BaseScreen<PlaylistEditorScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = true;
  bool _isEvent = false;
  bool _isLoading = false;
  String _licenseType = 'open';
  
  Playlist? _playlist;
  List<Track> _playlistTracks = [];
  final List<CollaboratorInfo> _activeCollaborators = [];
  final List<RecentEdit> _recentEdits = [];
  
  StreamSubscription? _wsSubscription;
  bool _showCollaborationFeatures = false;

  bool get _isEditMode => widget.playlistId?.isNotEmpty == true && widget.playlistId != 'null';
  bool get _canEdit {
    if (_playlist == null) return true; 
    return _playlist!.canEdit(auth.username);
  } 
  
  bool get _isOwner {
    if (_playlist == null) return true;
    return _playlist!.creator == auth.username;
  } 

  @override
  String get screenTitle => _isEditMode ? 'Edit Playlist' : 'Create Playlist';

  @override
  List<Widget> get actions => [
    if (_isEditMode) ...[
      IconButton(
        icon: Icon(_showCollaborationFeatures ? Icons.edit : Icons.people),
        onPressed: () => setState(() => _showCollaborationFeatures = !_showCollaborationFeatures),
        tooltip: _showCollaborationFeatures ? 'Show Settings' : 'Show Collaboration',
      ),
      if (_showCollaborationFeatures && _activeCollaborators.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.group),
          onPressed: _showCollaborators,
          tooltip: 'Active Collaborators',
        ),
      TextButton(
        onPressed: () => navigateTo(AppRoutes.playlistDetail, arguments: widget.playlistId),
        child: const Text('View Details', style: TextStyle(color: AppTheme.primary)),
      ),
    ],
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaylistData());
    }
  }

  @override
  Widget buildContent() {
    if (_isLoading) {
      return buildLoadingState(message: _isEditMode ? 'Loading playlist...' : 'Creating playlist...');
    }

    if (_isEditMode && _showCollaborationFeatures) {
      return _buildCollaborativeEditor();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          if (_isEditMode && _playlist != null) _buildPlaylistInfo(),
          const SizedBox(height: 16),
          _buildForm(),
        ],
      ),
    );
  }

  Widget _buildPlaylistInfo() {
    if (_playlist == null) return const SizedBox.shrink();

    return AppWidgets.infoBanner(
      title: 'Editing: ${_playlist!.name}',
      message: 'Make changes to your playlist information below',
      icon: Icons.edit,
    );
  }

  Widget _buildForm() {
    return AppTheme.buildFormCard(
      title: _isEditMode ? 'Playlist Settings' : 'Create New Playlist',
      titleIcon: _isEditMode ? Icons.edit : Icons.add,
      child: Column(
        children: [
          AppWidgets.textField(
            context: context,
            controller: _nameController,
            labelText: 'Playlist Name',
            prefixIcon: Icons.title,
            validator: (value) => AppValidators.required(value, 'playlist name'),
            onFieldSubmitted: kIsWeb ? (_) => (_isEditMode ? _saveChanges() : _createPlaylist()) : null,
          ),
          const SizedBox(height: 16),
          AppWidgets.textField(
            context: context,
            controller: _descriptionController,
            labelText: 'Description (optional)',
            prefixIcon: Icons.description,
            maxLines: 3,
            validator: (value) => value != null && value.length > 500 ? 'Description must be less than 500 characters' : null,
          ),
          const SizedBox(height: 16),
          AppWidgets.switchTile(
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value),
            title: 'Public Playlist',
            subtitle: _isPublic 
              ? 'Anyone can view this playlist (no edit permissions)' 
              : 'Only you and invited users can view this playlist',
            icon: _isPublic ? Icons.public : Icons.lock,
          ),
          const SizedBox(height: 16),
          AppWidgets.switchTile(
            value: _isEvent,
            onChanged: (value) => setState(() => _isEvent = value),
            title: 'Event',
            subtitle: _isEvent 
              ? (_isPublic 
                  ? 'Public event - anyone can vote' 
                  : 'Private event - only invited users can vote')
              : 'Regular playlist - no voting available',
            icon: _isEvent ? Icons.event : Icons.playlist_play,
          ),
          const SizedBox(height: 16),
          if (!_isPublic && _isEvent && _isOwner) _buildEditPermissionSettings(),
          if (!_isPublic && _isEvent && _isOwner) const SizedBox(height: 24),
          if (_isPublic) const SizedBox(height: 8),
          AppWidgets.primaryButton(
            context: context,
            text: _isEditMode ? 'Save Changes' : 'Create Playlist',
            icon: _isEditMode ? Icons.save : Icons.add,
            onPressed: _isLoading ? null : (_isEditMode ? _saveChanges : _createPlaylist),
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildEditPermissionSettings() {
    return AppTheme.buildFormCard(
      title: 'Edit Permissions',
      titleIcon: Icons.edit,
      child: Column(
        children: [
          ListTile(
            title: const Text('Open Editing'),
            subtitle: const Text('Anyone with access can edit'),
            leading: Radio<String>(
              value: 'open',
              groupValue: _licenseType,
              onChanged: (value) => setState(() => _licenseType = value!),
            ),
            onTap: () => setState(() => _licenseType = 'open'),
          ),
          ListTile(
            title: const Text('Invite Only'),
            subtitle: const Text('Only invited collaborators can edit'),
            leading: Radio<String>(
              value: 'invite_only',
              groupValue: _licenseType,
              onChanged: (value) => setState(() => _licenseType = value!),
            ),
            onTap: () => setState(() => _licenseType = 'invite_only'),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaborativeEditor() {
    return Column(
      children: [
        _buildEditorHeader(),
        if (_activeCollaborators.isNotEmpty) _buildActiveCollaborators(),
        Expanded(child: _buildTracksList()),
        if (_canEdit) _buildEditorActions(),
      ],
    );
  }

  Widget _buildEditorHeader() {
    if (_playlist == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _playlist!.isPublic ? Icons.public : Icons.lock,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _playlist!.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!_canEdit)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'View Only',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (_playlist!.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _playlist!.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.music_note, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${_playlistTracks.length} tracks',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              Icon(Icons.people, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${_activeCollaborators.length + 1} collaborators',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCollaborators() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, color: Colors.green, size: 12),
          const SizedBox(width: 8),
          const Text(
            'Active now:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _activeCollaborators.length,
              itemBuilder: (context, index) {
                final collaborator = _activeCollaborators[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Chip(
                    avatar: CircleAvatar(
                      backgroundColor: collaborator.color,
                      child: Text(
                        collaborator.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    label: Text(collaborator.name),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTracksList() {
    if (_playlistTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.queue_music,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tracks yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _canEdit 
                ? 'Add the first track to get started!'
                : 'This playlist is empty',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(4),
      itemCount: _playlistTracks.length,
      itemBuilder: (context, index) {
        final track = _playlistTracks[index];
        return _buildTrackCard(track, index, key: ValueKey(track.id));
      },
    );
  }

  Widget _buildTrackCard(Track track, int index, {required Key key}) {
    final recentEdit = _recentEdits.where((edit) => edit.trackId == track.id).firstOrNull;
    final showEditIndicator = recentEdit != null && 
        DateTime.now().difference(recentEdit.timestamp).inSeconds < 5;

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 6),
      elevation: showEditIndicator ? 4 : 1,
      color: showEditIndicator 
        ? Colors.blue.withValues(alpha: 0.1) 
        : null,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: track.imageUrl != null 
            ? Image.network(
                track.imageUrl!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultAlbumArt(),
              )
            : _buildDefaultAlbumArt(),
        ),
        title: Text(
          track.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(track.artist),
            if (showEditIndicator)
              Text(
                'Recently ${recentEdit.action} by ${recentEdit.userName}',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: _canEdit 
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (index > 0)
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up),
                    onPressed: () => _moveTrack(index, index - 1),
                    tooltip: 'Move up',
                  ),
                if (index < _playlistTracks.length - 1)
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: () => _moveTrack(index, index + 1),
                    tooltip: 'Move down',
                  ),
                PopupMenuButton<String>(
                  onSelected: (action) => _handleTrackAction(action, track, index),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'play',
                      child: ListTile(
                        leading: Icon(Icons.play_arrow),
                        title: Text('Play'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: ListTile(
                        leading: Icon(Icons.remove, color: Colors.red),
                        title: Text('Remove', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _playTrack(track),
            ),
      ),
    );
  }

  Widget _buildDefaultAlbumArt() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.music_note,
        color: AppTheme.primary,
        size: 25,
      ),
    );
  }

  Widget _buildEditorActions() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppWidgets.primaryButton(
              context: context,
              text: 'Add Track',
              icon: Icons.add,
              onPressed: _addTrackToPlaylist,
              isLoading: false,
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _clearPlaylist,
            icon: const Icon(Icons.clear_all, color: Colors.red),
            label: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPlaylistData() async {
    if (!_isEditMode) return;

    await runAsyncAction(
      () async {
        final musicProvider = getProvider<MusicProvider>();
        _playlist = await musicProvider.getPlaylistDetails(widget.playlistId!, auth.token!);
        
        if (_playlist != null) {
          setState(() {
            _nameController.text = _playlist!.name;
            _descriptionController.text = _playlist!.description;
            _isPublic = _playlist!.isPublic;
            _isEvent = _playlist!.isEvent;
            _licenseType = _playlist!.licenseType;
          });

          await musicProvider.fetchPlaylistTracks(widget.playlistId!, auth.token!);
          _playlistTracks = _playlist!.tracks;
          
          if (_showCollaborationFeatures) {
            await _initializeWebSocket();
          }
          
          setState(() {});
        }
      },
      errorMessage: 'Failed to load playlist',
    );
  }

  Future<void> _createPlaylist() async {
    if (_nameController.text.trim().isEmpty) {
      showError('Please enter a playlist name');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final musicProvider = getProvider<MusicProvider>();
      final playlistId = await musicProvider.createPlaylist(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
        _isPublic,
        auth.token!,
        _licenseType,
        _isEvent,
      );

      if (playlistId?.isEmpty ?? true) {
        throw Exception('Invalid playlist ID received');
      }

      showSuccess('Playlist created successfully!');
      navigateTo(AppRoutes.playlistDetail, arguments: playlistId);
    } catch (e) {
      AppLogger.error('Failed to create playlist', e, null, 'PlaylistEditorScreen');
      showError('Failed to create playlist: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_isEditMode) return;
    if (_nameController.text.trim().isEmpty) {
      showError('Please enter a playlist name');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final apiService = getIt<ApiService>();
      
      final hasNameOrDescriptionChanged = _playlist != null && 
          (_playlist!.name != _nameController.text.trim() || 
           _playlist!.description != _descriptionController.text.trim());
      final hasVisibilityChanged = _playlist != null && _playlist!.isPublic != _isPublic;
      final hasLicenseTypeChanged = _playlist != null && _playlist!.licenseType != _licenseType;
      
      if (hasVisibilityChanged) {
        final visibilityRequest = VisibilityRequest(public: _isPublic);
        await apiService.changePlaylistVisibility(widget.playlistId!, auth.token!, visibilityRequest);
      }
      
      if (hasNameOrDescriptionChanged) {
        final musicProvider = getProvider<MusicProvider>();
        await musicProvider.updatePlaylistDetails(
          widget.playlistId!,
          auth.token!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
        );
      }
      
      if (hasLicenseTypeChanged) {
        final licenseRequest = PlaylistLicenseRequest(licenseType: _licenseType);
        await apiService.updatePlaylistLicense(widget.playlistId!, auth.token!, licenseRequest);
      }
      
      final musicProvider = getProvider<MusicProvider>();
      
      musicProvider.updatePlaylistInCache(
        widget.playlistId!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        isPublic: _isPublic,
        isEvent: _isEvent,
        licenseType: _licenseType,
      );
      
      await musicProvider.fetchAllPlaylists(auth.token!);
      
      showSuccess('Playlist updated successfully!');
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.playlistDetail, arguments: widget.playlistId);
      }
    } catch (e) {
      AppLogger.error('Failed to update playlist', e, null, 'PlaylistEditorScreen');
      showError('Failed to update playlist: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _initializeWebSocket() async {
    try {
      getIt<WebSocketService>();
    } catch (e) {
      AppLogger.error('WebSocket connection failed: ${e.toString()}', null, null, 'PlaylistEditorScreen');
    }
  }



  Future<void> _addTrackToPlaylist() async {
    final selectedTrack = await Navigator.pushNamed(
      context, 
      AppRoutes.trackSearch,
      arguments: {'selectMode': true},
    ) as Track?;

    if (selectedTrack != null) {
      try {
        final musicProvider = getProvider<MusicProvider>();
        await musicProvider.addTrackToPlaylist(
          widget.playlistId!, 
          selectedTrack.id, 
          auth.token!,
        );

        setState(() {
          _playlistTracks.add(selectedTrack);
          _recentEdits.add(RecentEdit(
            trackId: selectedTrack.id,
            action: 'added',
            userName: 'You',
            timestamp: DateTime.now(),
          ));
        });

        showSuccess('Track added to playlist!');
      } catch (e) {
        AppLogger.error('Failed to add track', e, null, 'PlaylistEditorScreen');
        showError('Failed to add track: ${e.toString()}');
      }
    }
  }

  Future<void> _moveTrack(int fromIndex, int toIndex) async {
    if (fromIndex == toIndex || fromIndex < 0 || toIndex < 0 || 
        fromIndex >= _playlistTracks.length || toIndex >= _playlistTracks.length) {
      return;
    }

    final track = _playlistTracks.removeAt(fromIndex);
    _playlistTracks.insert(toIndex, track);

    setState(() {});

    try {
      final musicProvider = getProvider<MusicProvider>();
      await musicProvider.moveTrackInPlaylist(
        playlistId: widget.playlistId!, 
        rangeStart: fromIndex, 
        insertBefore: toIndex,
        token: auth.token!,
      );
    } catch (e) {
      AppLogger.error('Failed to save track order', e, null, 'PlaylistEditorScreen');
      showError('Failed to save track order: ${e.toString()}');
      
      final restoredTrack = _playlistTracks.removeAt(toIndex);
      _playlistTracks.insert(fromIndex, restoredTrack);
      setState(() {});
    }
  }

  void _handleTrackAction(String action, Track track, int index) {
    switch (action) {
      case 'play':
        _playTrack(track);
        break;
      case 'remove':
        _removeTrack(track, index);
        break;
    }
  }

  void _playTrack(Track track) {
    showInfo('Playing: ${track.name}');
  }

  Future<void> _removeTrack(Track track, int index) async {
    try {
      final musicProvider = getProvider<MusicProvider>();
      await musicProvider.removeTrackFromPlaylist(
        playlistId: widget.playlistId!,
        trackId: track.id,
        token: auth.token!,
      );

      setState(() {
        _playlistTracks.removeAt(index);
        _recentEdits.add(RecentEdit(
          trackId: track.id,
          action: 'removed',
          userName: 'You',
          timestamp: DateTime.now(),
        ));
      });

      showSuccess('Track removed from playlist!');
    } catch (e) {
      AppLogger.error('Failed to remove track', e, null, 'PlaylistEditorScreen');
      showError('Failed to remove track: ${e.toString()}');
    }
  }

  Future<void> _clearPlaylist() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Playlist'),
        content: const Text('Are you sure you want to remove all tracks from this playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        getProvider<MusicProvider>();
        setState(() {
          _playlistTracks.clear();
        });

        showSuccess('Playlist cleared!');
      } catch (e) {
        AppLogger.error('Failed to clear playlist', e, null, 'PlaylistEditorScreen');
        showError('Failed to clear playlist: ${e.toString()}');
      }
    }
  }

  void _showCollaborators() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Collaborators'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _activeCollaborators.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.primary,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(auth.username ?? 'You'),
                  subtitle: const Text('Host'),
                  trailing: const Icon(Icons.star, color: Colors.orange),
                );
              }
              
              final collaborator = _activeCollaborators[index - 1];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: collaborator.color,
                  child: Text(
                    collaborator.initials,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(collaborator.name),
                subtitle: const Text('Collaborator'),
                trailing: const Icon(Icons.circle, color: Colors.green, size: 12),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _wsSubscription?.cancel();
    super.dispose();
  }
}

class CollaboratorInfo {
  final String userId;
  final String name;
  final Color color;
  final DateTime joinedAt;
  
  String get initials => name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase();

  const CollaboratorInfo({
    required this.userId,
    required this.name,
    required this.color,
    required this.joinedAt,
  });

  factory CollaboratorInfo.fromJson(Map<String, dynamic> json) => CollaboratorInfo(
    userId: json['user_id'] as String,
    name: json['name'] as String,
    color: Color(json['color'] as int? ?? 0xFF2196F3),
    joinedAt: DateTime.parse(json['joined_at'] as String),
  );
}

class RecentEdit {
  final String trackId;
  final String action;
  final String userName;
  final DateTime timestamp;

  const RecentEdit({
    required this.trackId,
    required this.action,
    required this.userName,
    required this.timestamp,
  });
}

extension ListExtensions<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
