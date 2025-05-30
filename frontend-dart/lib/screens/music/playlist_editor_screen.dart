// lib/screens/music/playlist_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../services/websocket_service.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';
import '../../models/playlist_track.dart';
import '../../core/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/dialog_helper.dart';

class PlaylistEditorScreen extends StatefulWidget {
  final String? playlistId;

  const PlaylistEditorScreen({Key? key, this.playlistId}) : super(key: key);

  @override
  State<PlaylistEditorScreen> createState() => _PlaylistEditorScreenState();
}

class _PlaylistEditorScreenState extends State<PlaylistEditorScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = false;
  bool _isLoading = false;
  Playlist? _playlist;
  List<PlaylistTrack> _playlistTracks = [];
  
  late WebSocketService _webSocketService;
  StreamSubscription<List<PlaylistTrack>>? _tracksSubscription;
  StreamSubscription<String>? _connectionSubscription;
  bool _isWebSocketConnected = false;

  @override
  void initState() {
    super.initState();
    _webSocketService = WebSocketService();
    _setupWebSocketListeners();
    
    if (widget.playlistId != null && widget.playlistId!.isNotEmpty && widget.playlistId != 'null') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPlaylist();
      });
    }
  }

  void _setupWebSocketListeners() {
    _tracksSubscription = _webSocketService.playlistTracksStream.listen(
      (tracks) {
        print('Received real-time track update: ${tracks.length} tracks');
        setState(() {
          _playlistTracks = tracks;
        });
      },
    );

    _connectionSubscription = _webSocketService.connectionStatusStream.listen(
      (status) {
        print('WebSocket status: $status');
        setState(() {
          _isWebSocketConnected = _webSocketService.isConnected;
        });
        
        if (status.contains('Connected')) {
          _showSnackBar('Real-time collaboration is now active', isError: false);
        } else if (status.contains('error') || status.contains('failed')) {
          _showSnackBar('Real-time sync unavailable - changes will save normally', isError: false);
        }
      },
    );
  }

  Future<void> _loadPlaylist() async {
    if (widget.playlistId == null || widget.playlistId!.isEmpty || widget.playlistId == 'null') {
      print('Warning: Invalid playlistId: ${widget.playlistId}');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      
      print('Loading playlist with ID: ${widget.playlistId}');
      _playlist = await musicProvider.getPlaylistDetails(widget.playlistId!, authProvider.token!);
      
      if (_playlist != null) {
        _nameController.text = _playlist!.name;
        _descriptionController.text = _playlist!.description;
        _isPublic = _playlist!.isPublic;
        
        await musicProvider.fetchPlaylistTracks(widget.playlistId!, authProvider.token!);
        _playlistTracks = List.from(musicProvider.playlistTracks);
        
        await _connectToWebSocket();
      }
    } catch (e) {
      print('Error loading playlist: $e');
      _showSnackBar('Unable to load playlist. Please check your connection and try again.', isError: true);
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _connectToWebSocket() async {
    if (widget.playlistId != null && widget.playlistId!.isNotEmpty && widget.playlistId != 'null') {
      try {
        await _webSocketService.connectToPlaylist(widget.playlistId!);
        print('Connected to WebSocket for playlist ${widget.playlistId}');
      } catch (e) {
        print('Failed to connect to WebSocket: $e');
      }
    }
  }

  Future<void> _createPlaylist() async {
    if (_nameController.text.isEmpty) {
      _showSnackBar('Please give your playlist a name before creating it', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);

      final playlistId = await musicProvider.createPlaylist(
        _nameController.text,
        _descriptionController.text,
        _isPublic,
        authProvider.token!,
      );
      if (playlistId != null) {
        _showSnackBar('Playlist "${_nameController.text}" created successfully!');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PlaylistEditorScreen(playlistId: playlistId),
          ),
        );
        return;
      }
    } catch (e) {
      print('Error creating playlist: $e');
      _showSnackBar('Failed to create playlist. Please try again.', isError: true);
    }

    setState(() => _isLoading = false);
  }

  bool get _isEditMode => widget.playlistId != null && 
                         widget.playlistId!.isNotEmpty && 
                         widget.playlistId != 'null';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Row(
          children: [
            Icon(
              _isEditMode ? Icons.edit : Icons.add,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(_isEditMode ? 'Edit Playlist' : 'Create New Playlist'),
            if (_isEditMode) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isWebSocketConnected ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isWebSocketConnected ? Colors.green : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isWebSocketConnected ? Icons.sync : Icons.sync_disabled,
                      size: 12,
                      color: _isWebSocketConnected ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isWebSocketConnected ? 'Live Sync' : 'Offline',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _isWebSocketConnected ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: _buildAppBarActions(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isEditMode) _buildCreatePlaylistHeader(),
                  _buildPlaylistInfo(),
                  const SizedBox(height: 24),
                  if (_isEditMode) _buildTracksSection(),
                  const SizedBox(height: 100), 
                ],
              ),
            ),
      floatingActionButton: _isEditMode ? _buildFloatingActionButton() : null,
    );
  }

  List<Widget> _buildAppBarActions() {
    if (!_isEditMode) {
      return [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Create'),
            onPressed: _isLoading ? null : _createPlaylist,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
      ];
    }

    return [
      Padding(
        padding: const EdgeInsets.only(right: 4),
        child: TextButton.icon(
          icon: Icon(_isPublic ? Icons.public : Icons.lock, size: 18),
          label: Text(_isPublic ? 'Public' : 'Private', style: const TextStyle(fontSize: 12)),
          onPressed: _isLoading ? null : _toggleVisibility,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: TextButton.icon(
          icon: const Icon(Icons.person_add, size: 18),
          label: const Text('Invite', style: TextStyle(fontSize: 12)),
          onPressed: _isLoading ? null : _inviteUser,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ),
    ];
  }

  Widget _buildCreatePlaylistHeader() {
    return Card(
      color: AppTheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.lightbulb, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Getting Started',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your custom playlist by giving it a name and description. You can add songs later!',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              '• Make it public to share with friends\n• Keep it private for personal use\n• Add a description to help others understand your playlist',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistInfo() {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isEditMode ? Icons.edit : Icons.create,
                  color: AppTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isEditMode ? 'Playlist Details' : 'Playlist Information',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _nameController,
              labelText: 'Playlist Name *',
              hintText: 'e.g., My Favorite Songs, Workout Mix, Road Trip Hits',
              validator: (value) => value?.isEmpty == true ? 'Please enter a name for your playlist' : null,
              onChanged: _isEditMode ? null : (_) {},
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              labelText: 'Description (Optional)',
              hintText: 'Tell others what this playlist is about...',
              maxLines: 3,
              onChanged: _isEditMode ? null : (_) {},
            ),
            const SizedBox(height: 16),
            
            if (_isEditMode) 
              _buildVisibilityDisplay()
            else
              _buildVisibilitySelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isPublic ? Colors.green.withOpacity(0.5) : Colors.orange.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isPublic ? Icons.public : Icons.lock,
            color: _isPublic ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPublic ? 'Public Playlist' : 'Private Playlist',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _isPublic 
                      ? 'Anyone can discover and listen to this playlist'
                      : 'Only you can see and play this playlist',
                  style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _toggleVisibility,
            child: Text(
              'Change to ${_isPublic ? 'Private' : 'Public'}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Who can see this playlist?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Text(
            _isPublic ? 'Public - Anyone can find it' : 'Private - Just for you',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            _isPublic 
                ? 'Your playlist will appear in public searches and can be shared'
                : 'Your playlist will only be visible to you',
            style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
          ),
          value: _isPublic,
          onChanged: (value) => setState(() => _isPublic = value),
          activeColor: AppTheme.primary,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildTracksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: AppTheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.queue_music, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Playlist Tracks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_playlistTracks.length} songs',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isWebSocketConnected 
                      ? 'Real-time sync active - changes appear instantly for all collaborators'
                      : 'Changes will be saved when you make them',
                  style: TextStyle(
                    color: _isWebSocketConnected ? Colors.green : AppTheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        if (_playlistTracks.isEmpty)
          _buildEmptyTracksState()
        else
          _buildTracksList(),
      ],
    );
  }

  Widget _buildEmptyTracksState() {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.music_note_outlined,
              size: 48,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No tracks yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start building your playlist by adding some music!',
              style: TextStyle(color: AppTheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToTrackSearch,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Your First Song'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTracksList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _playlistTracks.length,
      onReorder: _moveTrack,
      itemBuilder: (context, index) {
        final track = _playlistTracks[index];
        return Card(
          key: ValueKey(track.trackId),
          margin: const EdgeInsets.only(bottom: 8),
          color: AppTheme.surface,
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.drag_handle, color: AppTheme.onSurfaceVariant),
                    Text(
                      'Drag',
                      style: TextStyle(
                        fontSize: 8,
                        color: AppTheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            title: Text(
              track.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Track position: ${track.position}',
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            trailing: TextButton.icon(
              onPressed: () => _removeTrack(track),
              icon: const Icon(Icons.delete, color: Colors.red, size: 16),
              label: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
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
      tooltip: 'Search and add songs to your playlist',
    );
  }

  Future<void> _toggleVisibility() async {
    if (widget.playlistId == null || widget.playlistId!.isEmpty || widget.playlistId == 'null') {
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);

      bool newVisibility = !_isPublic;
      await musicProvider.changePlaylistVisibility(
        widget.playlistId!,
        newVisibility,
        authProvider.token!,
      );
      
      setState(() => _isPublic = newVisibility);
      _showSnackBar('Playlist is now ${newVisibility ? 'public' : 'private'}');
    } catch (e) {
      _showSnackBar('Unable to change visibility. Please try again.', isError: true);
    }
  }

  Future<void> _removeTrack(PlaylistTrack track) async {
    final confirm = await DialogHelper.showConfirm(
      context,
      title: 'Remove Track',
      message: 'Are you sure you want to remove "${track.name}" from this playlist?',
      confirmText: 'Remove',
      isDangerous: true,
    );

    if (confirm == true && widget.playlistId != null) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final musicProvider = Provider.of<MusicProvider>(context, listen: false);

        await musicProvider.removeTrackFromPlaylist(
          widget.playlistId!,
          track.trackId,
          authProvider.token!,
        );

        _showSnackBar('Track removed from playlist');
        
        if (!_isWebSocketConnected) {
          await musicProvider.fetchPlaylistTracks(widget.playlistId!, authProvider.token!);
          setState(() {
            _playlistTracks = List.from(musicProvider.playlistTracks);
          });
        }
      } catch (e) {
        _showSnackBar('Unable to remove track. Please try again.', isError: true);
      }
    }
  }

  Future<void> _moveTrack(int oldIndex, int newIndex) async {
    if (widget.playlistId == null || oldIndex == newIndex) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);

      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      await musicProvider.moveTrackInPlaylist(
        widget.playlistId!,
        oldIndex,
        newIndex,
        1, 
        authProvider.token!,
      );

      _showSnackBar('Track moved successfully');
      
      if (!_isWebSocketConnected) {
        await musicProvider.fetchPlaylistTracks(widget.playlistId!, authProvider.token!);
        setState(() {
          _playlistTracks = List.from(musicProvider.playlistTracks);
        });
      }
    } catch (e) {
      _showSnackBar('Unable to move track. Please try again.', isError: true);
    }
  }

  Future<void> _inviteUser() async {
    if (widget.playlistId == null) return;

    final userId = await DialogHelper.showTextInput(
      context,
      title: 'Invite User to Playlist',
      hintText: 'Enter user ID or username',
    );

    if (userId != null && userId.isNotEmpty) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final musicProvider = Provider.of<MusicProvider>(context, listen: false);

        await musicProvider.inviteUserToPlaylist(
          widget.playlistId!,
          userId,
          authProvider.token!,
        );

        _showSnackBar('User invited to collaborate on this playlist!');
      } catch (e) {
        _showSnackBar('Unable to invite user. Please check the ID and try again.', isError: true);
      }
    }
  }

  void _navigateToTrackSearch() {
    Navigator.of(context).pushNamed('/track_search', arguments: widget.playlistId);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        action: isError ? SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ) : null,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tracksSubscription?.cancel();
    _connectionSubscription?.cancel();
    _webSocketService.disconnect();
    super.dispose();
  }
}
