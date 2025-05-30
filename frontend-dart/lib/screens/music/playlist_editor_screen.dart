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
      _loadPlaylist();
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
          _showSnackBar('Real-time sync enabled', isError: false);
        } else if (status.contains('error') || status.contains('failed')) {
          _showSnackBar('Real-time sync unavailable', isError: true);
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
      _showSnackBar('Error loading playlist: $e', isError: true);
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
      _showSnackBar('Please enter a playlist name', isError: true);
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
        _showSnackBar('Playlist created successfully');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PlaylistEditorScreen(playlistId: playlistId),
          ),
        );
        return;
      }
    } catch (e) {
      print('Error creating playlist: $e');
      _showSnackBar('Error creating playlist: $e', isError: true);
    }

    setState(() => _isLoading = false);
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
      _showSnackBar('Playlist visibility updated');
    } catch (e) {
      _showSnackBar('Error updating visibility: $e', isError: true);
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
        _showSnackBar('Error removing track: $e', isError: true);
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
      _showSnackBar('Error moving track: $e', isError: true);
    }
  }

  Future<void> _inviteUser() async {
    if (widget.playlistId == null) return;

    final userId = await DialogHelper.showTextInput(
      context,
      title: 'Invite User',
      hintText: 'Enter user ID',
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

        _showSnackBar('User invited to playlist successfully');
      } catch (e) {
        _showSnackBar('Error inviting user: $e', isError: true);
      }
    }
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
            Text(_isEditMode ? 'Playlist Details' : 'Create Playlist'),
            if (_isEditMode) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isWebSocketConnected ? Colors.green : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _isWebSocketConnected ? 'Live' : 'Offline',
                style: TextStyle(
                  fontSize: 12,
                  color: _isWebSocketConnected ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_isEditMode) ...[
            IconButton(
              icon: Icon(_isPublic ? Icons.public : Icons.lock),
              onPressed: _isLoading ? null : _toggleVisibility,
              tooltip: _isPublic ? 'Make Private' : 'Make Public',
            ),
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _isLoading ? null : _inviteUser,
              tooltip: 'Invite User',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _createPlaylist,
              tooltip: 'Create Playlist',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlaylistInfo(),
                  const SizedBox(height: 24),
                  if (_isEditMode) _buildTracksSection(),
                  const SizedBox(height: 80), 
                ],
              ),
            ),
      floatingActionButton: _isEditMode ? FloatingActionButton(
        onPressed: () => _navigateToTrackSearch(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.black),
        tooltip: 'Add Tracks',
      ) : null,
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
            Text(
              _isEditMode ? 'Playlist Information' : 'New Playlist',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _nameController,
              labelText: 'Playlist Name',
              validator: (value) => value?.isEmpty == true ? 'Please enter a name' : null,
              onChanged: _isEditMode ? null : (_) {},
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              labelText: 'Description',
              maxLines: 3,
              onChanged: _isEditMode ? null : (_) {},
            ),
            if (_isEditMode) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isPublic ? Icons.public : Icons.lock,
                      color: _isPublic ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isPublic ? 'Public - Anyone can see this playlist' : 'Private - Only you can see this playlist',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Public Playlist', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  _isPublic ? 'Anyone can see this playlist' : 'Only you can see this playlist',
                  style: const TextStyle(color: AppTheme.onSurfaceVariant),
                ),
                value: _isPublic,
                onChanged: (value) => setState(() => _isPublic = value),
                activeColor: AppTheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTracksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tracks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Row(
              children: [
                Text(
                  '${_playlistTracks.length} songs',
                  style: const TextStyle(color: AppTheme.onSurfaceVariant),
                ),
                if (_isWebSocketConnected) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.sync, color: Colors.green, size: 16),
                  const Text(' Live', style: TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_playlistTracks.isEmpty)
          const EmptyState(
            icon: Icons.music_note,
            title: 'No tracks added',
            subtitle: 'Add tracks to your playlist using the + button',
          )
        else
          ReorderableListView.builder(
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
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      '${track.position}',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    track.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Position: ${track.position}',
                    style: const TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.drag_handle, color: AppTheme.onSurfaceVariant),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeTrack(track),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
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
