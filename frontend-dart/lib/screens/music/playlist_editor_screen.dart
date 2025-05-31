// lib/screens/music/playlist_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/device_provider.dart';
import '../../services/websocket_service.dart';
import '../../models/playlist.dart';
import '../../models/playlist_track.dart';
import '../../core/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/dialog_helper.dart';
import 'components/playlist_info_form.dart';
import 'components/playlist_tracks_section.dart';
import 'components/websocket_status_indicator.dart';

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
    
    if (_isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPlaylist();
      });
    }
  }

  bool get _isEditMode => widget.playlistId != null && 
                         widget.playlistId!.isNotEmpty && 
                         widget.playlistId != 'null';

  void _setupWebSocketListeners() {
    _tracksSubscription = _webSocketService.playlistTracksStream.listen(
      (tracks) {
        setState(() {
          _playlistTracks = tracks;
        });
      },
    );

    _connectionSubscription = _webSocketService.connectionStatusStream.listen(
      (status) {
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
    if (!_isEditMode) return;

    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      
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
      _showSnackBar('Unable to load playlist. Please check your connection and try again.', isError: true);
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _connectToWebSocket() async {
    if (_isEditMode) {
      try {
        await _webSocketService.connectToPlaylist(widget.playlistId!);
      } catch (e) {
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
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

      final playlistId = await musicProvider.createPlaylist(
        _nameController.text,
        _descriptionController.text,
        _isPublic,
        authProvider.token!,
        deviceProvider.deviceUuid,
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
      _showSnackBar('Failed to create playlist. Please try again.', isError: true);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isEditMode) _buildCreatePlaylistHeader(),
                  PlaylistInfoForm(
                    nameController: _nameController,
                    descriptionController: _descriptionController,
                    isPublic: _isPublic,
                    isEditMode: _isEditMode,
                    onVisibilityChanged: (value) => setState(() => _isPublic = value),
                    onToggleVisibility: _toggleVisibility,
                  ),
                  const SizedBox(height: 24),
                  if (_isEditMode) 
                    PlaylistTracksSection(
                      tracks: _playlistTracks,
                      isWebSocketConnected: _isWebSocketConnected,
                      onRemoveTrack: _removeTrack,
                      onMoveTrack: _moveTrack,
                      onAddTracks: _navigateToTrackSearch,
                    ),
                  const SizedBox(height: 100), 
                ],
              ),
            ),
      floatingActionButton: _isEditMode ? _buildFloatingActionButton() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
            WebSocketStatusIndicator(isConnected: _isWebSocketConnected),
          ],
        ],
      ),
      actions: _buildAppBarActions(),
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
    if (!_isEditMode) return;

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

    if (confirm == true && _isEditMode) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final musicProvider = Provider.of<MusicProvider>(context, listen: false);
        final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

        await musicProvider.removeTrackFromPlaylist(
          widget.playlistId!,
          track.trackId,
          authProvider.token!,
          deviceProvider.deviceUuid,
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
    if (!_isEditMode || oldIndex == newIndex) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      await musicProvider.moveTrackInPlaylist(
        widget.playlistId!,
        oldIndex,
        newIndex,
        1, 
        authProvider.token!,
        deviceProvider.deviceUuid,
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
    if (!_isEditMode) return;

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
