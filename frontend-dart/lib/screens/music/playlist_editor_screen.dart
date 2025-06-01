// lib/screens/music/playlist_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/device_provider.dart';
import '../../models/playlist.dart';
import '../../models/playlist_track.dart';
import '../../core/theme.dart';
import '../../core/app_strings.dart';
import '../../widgets/unified_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaylist());
    }
  }

  bool get _isEditMode => widget.playlistId != null && 
                         widget.playlistId!.isNotEmpty && 
                         widget.playlistId != 'null';

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
      }
    } catch (e) {
      _showSnackBar('Failed to load playlist. Please check your connection.', isError: true);
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _createPlaylist() async {
    if (_nameController.text.isEmpty) {
      _showSnackBar('Please give your playlist a name', isError: true);
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
        _showSnackBar('Playlist created successfully!');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PlaylistEditorScreen(playlistId: playlistId),
          ),
        );
        return;
      }
    } catch (e) {
      _showSnackBar('Failed to create playlist', isError: true);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(_isEditMode ? AppStrings.editPlaylist : AppStrings.createPlaylist),
        actions: _buildAppBarActions(),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
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
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Create'),
            onPressed: _isLoading ? null : _createPlaylist,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
            ),
          ),
        ),
      ];
    }

    return [
      TextButton.icon(
        icon: Icon(_isPublic ? Icons.public : Icons.lock, size: 16),
        label: Text(_isPublic ? 'Public' : 'Private', style: const TextStyle(fontSize: 12)),
        onPressed: _isLoading ? null : _toggleVisibility,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
    ];
  }

  Widget _buildCreatePlaylistHeader() {
    return Card(
      color: AppTheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: AppTheme.primary, size: 24),
                SizedBox(width: 8),
                Text('Getting Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your custom playlist by giving it a name and description. You can add songs later!',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
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
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _nameController,
              labelText: 'Playlist Name',
              prefixIcon: Icons.title,
              validator: (value) => (value?.isEmpty ?? true) ? 'Please enter a playlist name' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              labelText: 'Description (optional)',
              prefixIcon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(_isPublic ? 'Public Playlist' : 'Private Playlist', style: const TextStyle(color: Colors.white)),
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
                Text('Tracks (${_playlistTracks.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 16),
            if (_playlistTracks.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.music_note, size: 48, color: Colors.white.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text('No tracks added yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      const Text('Add some songs to get started!', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _navigateToTrackSearch,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Songs'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _playlistTracks.length,
                itemBuilder: (context, index) {
                  final track = _playlistTracks[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: AppTheme.surfaceVariant,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${index + 1}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      title: Text(track.name, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('Position: ${track.position}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => _removeTrack(track),
                        tooltip: 'Remove track',
                      ),
                    ),
                  );
                },
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
    );
  }

  Future<void> _toggleVisibility() async {
    if (!_isEditMode) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);

      bool newVisibility = !_isPublic;
      await musicProvider.changePlaylistVisibility(widget.playlistId!, newVisibility, authProvider.token!);
      
      setState(() => _isPublic = newVisibility);
      _showSnackBar('Playlist is now ${newVisibility ? 'public' : 'private'}');
    } catch (e) {
      _showSnackBar('Unable to change visibility', isError: true);
    }
  }

  Future<void> _removeTrack(PlaylistTrack track) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Remove Track', style: TextStyle(color: Colors.white)),
        content: Text('Remove "${track.name}" from this playlist?', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && _isEditMode) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final musicProvider = Provider.of<MusicProvider>(context, listen: false);
        final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

        await musicProvider.removeTrackFromPlaylist(widget.playlistId!, track.trackId, authProvider.token!, deviceProvider.deviceUuid);
        _showSnackBar(AppStrings.trackRemoved);
        
        await musicProvider.fetchPlaylistTracks(widget.playlistId!, authProvider.token!);
        setState(() => _playlistTracks = List.from(musicProvider.playlistTracks));
      } catch (e) {
        _showSnackBar('Unable to remove track', isError: true);
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
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
