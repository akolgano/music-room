// lib/screens/music/playlist_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/playlist_license_provider.dart';
import '../../models/models.dart';
import '../../core/app_core.dart';
import '../../widgets/common_widgets.dart';
import '../../services/websocket_service.dart';
import '../../services/api_service.dart';

class PlaylistEditorScreen extends StatefulWidget {
  final String? playlistId;

  const PlaylistEditorScreen({Key? key, this.playlistId}) : super(key: key);

  @override
  State<PlaylistEditorScreen> createState() => _PlaylistEditorScreenState();
}

class _PlaylistEditorScreenState extends State<PlaylistEditorScreen> {
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

  bool get _isEditMode => widget.playlistId != null && 
                         widget.playlistId!.isNotEmpty && 
                         widget.playlistId != 'null';

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaylist());
    }
    _setupWebSocketListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(_isEditMode ? 'Edit Playlist' : 'Create Playlist'),
        actions: _buildAppBarActions(),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isScreenLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 16),
            Text('Loading playlist...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_notifications.isNotEmpty) _buildNotificationBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isEditMode) _buildCreateForm(),
                if (_isEditMode) ...[
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
      ],
    );
  }

  Widget _buildNotificationBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppTheme.primary.withOpacity(0.1),
      child: Column(
        children: _notifications.take(3).map((notification) => 
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(notification, style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => setState(() => _notifications.remove(notification)),
              ),
            ],
          ),
        ).toList(),
      ),
    );
  }

  Widget _buildCollaboratorsSection() {
    return AppTheme.buildFormCard(
      title: 'Active Collaborators (${_collaborators.length})',
      titleIcon: Icons.people,
      child: Column(
        children: [
          if (_collaborators.isEmpty)
            const Text('No active collaborators', style: TextStyle(color: Colors.grey))
          else
            Column(
              children: _collaborators.map((collaborator) => 
                _buildCollaboratorTile(collaborator)
              ).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCollaboratorTile(PlaylistCollaborator collaborator) {
    final canEdit = collaborator.hasPermission(PlaylistPermission.edit);
    final isCurrentUser = collaborator.userId == Provider.of<AuthProvider>(context, listen: false).userId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppTheme.primary.withOpacity(0.1) : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentUser ? Border.all(color: AppTheme.primary) : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.primaries[collaborator.userId.hashCode % Colors.primaries.length],
            radius: 16,
            child: Text(collaborator.username[0].toUpperCase(), style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(collaborator.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    Icon(canEdit ? Icons.edit : Icons.visibility, color: canEdit ? Colors.green : Colors.grey, size: 14),
                    const SizedBox(width: 4),
                    Text(canEdit ? 'Can edit' : 'View only', style: TextStyle(color: canEdit ? Colors.green : Colors.grey, fontSize: 12)),
                    if (collaborator.isOnline) ...[
                      const SizedBox(width: 8),
                      const Text('• Online', style: TextStyle(color: Colors.green, fontSize: 12)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateForm() {
    return AppTheme.buildFormCard(
      title: 'Create New Playlist',
      titleIcon: Icons.add,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          _buildVisibilitySwitch(),
          const SizedBox(height: 24),
          AppButton(
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
          _buildVisibilitySwitch(),
        ],
      ),
    );
  }

  Widget _buildVisibilitySwitch() {
    return SwitchListTile(
      title: Text(_isPublic ? 'Public Playlist' : 'Private Playlist', style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        _isPublic ? 'Anyone can view this playlist' : 'Only you can view this playlist',
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      value: _isPublic,
      onChanged: _isEditMode ? (value) => _toggleVisibility() : (value) => setState(() => _isPublic = value),
      activeColor: AppTheme.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildTracksSection() {
    return Consumer<PlaylistLicenseProvider>(
      builder: (context, licenseProvider, _) {
        final canEdit = licenseProvider.canCurrentUserEdit;
        
        return AppTheme.buildFormCard(
          title: 'Tracks (${_playlistTracks.length})',
          titleIcon: Icons.queue_music,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (canEdit) ...[
                ElevatedButton.icon(
                  onPressed: _navigateToTrackSearch,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Songs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_playlistTracks.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.music_note, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        canEdit ? 'No tracks added yet\nAdd some songs to get started!' : 'This playlist is empty',
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                _buildTracksList(canEdit),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTracksList(bool canEdit) {
    if (canEdit) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _playlistTracks.length,
        onReorder: _reorderTracks, 
        itemBuilder: (context, index) => _buildTrackTile(index, canEdit),
      );
    } else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _playlistTracks.length,
        itemBuilder: (context, index) => _buildTrackTile(index, canEdit),
      );
    }
  }

  Widget _buildTrackTile(int index, bool canEdit) {
    final track = _playlistTracks[index];
    return Container(
      key: ValueKey(track.trackId),
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (track.track != null)
                Text(track.track!.artist, 
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text('Position: ${track.position}', 
                  style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canEdit) ...[
                Icon(Icons.drag_handle, color: Colors.grey.withOpacity(0.7)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => _removeTrackWithNotification(track),
                  tooltip: 'Remove track',
                ),
              ] else
                const Icon(Icons.lock, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (!_isEditMode) return [];

    return [
      IconButton(
        icon: const Icon(Icons.person_add),
        onPressed: _inviteUser,
        tooltip: 'Invite Friend',
      ),
      PopupMenuButton<String>(
        onSelected: _handleMenuAction,
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'export',
            child: Row(children: [Icon(Icons.file_download, size: 16), SizedBox(width: 8), Text('Export Playlist')]),
          ),
        ],
      ),
    ];
  }

  void _setupWebSocketListeners() {
    if (_isEditMode) {
      _webSocketService.operationsStream.listen((PlaylistOperation operation) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (mounted && operation.userId != authProvider.userId) {
          _handleRemoteOperation(operation);
        }
      });

      _webSocketService.collaboratorsStream.listen((List<PlaylistCollaborator> collaborators) {
        if (mounted) {
          setState(() => _collaborators = collaborators);
        }
      });

      _webSocketService.notificationsStream.listen((String notification) {
        if (mounted) {
          setState(() {
            _notifications.add(notification);
            if (_notifications.length > 5) {
              _notifications.removeAt(0);
            }
          });
        }
      });
    }
  }

  void _handleRemoteOperation(PlaylistOperation operation) {
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
    final trackId = operation.data['track_id'] as String;
    final oldIndex = operation.data['old_index'] as int;
    final newIndex = operation.data['new_index'] as int;

    setState(() {
      final trackIndex = _playlistTracks.indexWhere((t) => t.trackId == trackId);
      if (trackIndex != -1 && trackIndex == oldIndex) {
        final track = _playlistTracks.removeAt(oldIndex);
        _playlistTracks.insert(newIndex, track);
      }
    });

    _showNotification('${operation.username} moved a track');
  }

  void _showNotification(String message) {
    setState(() {
      _notifications.add(message);
      if (_notifications.length > 5) {
        _notifications.removeAt(0);
      }
    });
  }

  void _reorderTracks(int oldIndex, int newIndex) {
    if (!_isEditMode || newIndex == oldIndex) return;
    
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final track = _playlistTracks[oldIndex];
    
    setState(() {
      final movedTrack = _playlistTracks.removeAt(oldIndex);
      _playlistTracks.insert(newIndex, movedTrack);
    });

    _webSocketService.sendTrackMove(
      track.trackId,
      oldIndex,
      newIndex,
      Provider.of<AuthProvider>(context, listen: false).username ?? 'User',
    );
  }

  Future<void> _removeTrackWithNotification(PlaylistTrack track) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Track'),
        content: Text('Remove "${track.name}" from playlist?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );

    if (confirmed == true && _isEditMode) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final operation = PlaylistOperation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: auth.userId!,
        username: auth.username ?? 'User',
        type: ConflictType.trackRemove,
        data: {'track_id': track.trackId},
        timestamp: DateTime.now(),
        version: 1,
      );
      
      _webSocketService.sendOperation(operation);

      try {
        final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
        await _apiService.removeTrackFromPlaylist(
          playlistId: widget.playlistId!,
          trackId: track.trackId,
          token: auth.token!,
          deviceUuid: deviceProvider.deviceUuid,
        );
        
        setState(() {
          _playlistTracks.remove(track);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Track removed'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove track'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleMenuAction(String action) {
    if (action == 'export') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export feature coming soon!'), backgroundColor: Colors.blue),
      );
    }
  }

  Future<void> _loadPlaylist() async {
    setState(() => _isScreenLoading = true);

    try {
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      final licenseProvider = Provider.of<PlaylistLicenseProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      
      _playlist = await musicProvider.getPlaylistDetails(widget.playlistId!, auth.token!);
      
      if (_playlist != null) {
        _nameController.text = _playlist!.name;
        _descriptionController.text = _playlist!.description;
        _isPublic = _playlist!.isPublic;
        
        await licenseProvider.loadPlaylistLicense(widget.playlistId!, auth.token!);
        
        final license = licenseProvider.currentLicense;
        if (license != null) {
          _inviteOnlyMode = license.inviteOnlyEdit;
        }
        
        await _loadPlaylistTracks();
        
        await _webSocketService.connectToPlaylist(
          widget.playlistId!,
          auth.userId!,
          auth.token!,
        );
        
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load playlist'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isScreenLoading = false);
  }

  Future<void> _loadPlaylistTracks() async {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await musicProvider.fetchPlaylistTracks(widget.playlistId!, auth.token!);
    _playlistTracks = List.from(musicProvider.playlistTracks);
  }

  Future<void> _createPlaylist() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give your playlist a name'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isScreenLoading = true);

    try {
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);

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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create playlist'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isScreenLoading = false);
  }

  Future<void> _toggleVisibility() async {
    if (!_isEditMode) return;

    try {
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      bool newVisibility = !_isPublic;
      await musicProvider.changePlaylistVisibility(widget.playlistId!, newVisibility, auth.token!);
      setState(() => _isPublic = newVisibility);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playlist is now ${newVisibility ? 'public' : 'private'}'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to change visibility'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _inviteUser() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite feature coming soon!'), backgroundColor: Colors.blue),
    );
  }

  void _navigateToTrackSearch() {
    Navigator.pushNamed(context, AppRoutes.trackSearch, arguments: widget.playlistId);
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
