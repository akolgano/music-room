// lib/screens/music/enhanced_playlist_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';
import '../../core/theme.dart';
import '../../widgets/common_widgets.dart';

class EnhancedPlaylistEditorScreen extends StatefulWidget {
  final String? playlistId;

  const EnhancedPlaylistEditorScreen({Key? key, this.playlistId}) : super(key: key);

  @override
  _EnhancedPlaylistEditorScreenState createState() => _EnhancedPlaylistEditorScreenState();
}

class _EnhancedPlaylistEditorScreenState extends State<EnhancedPlaylistEditorScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = false;
  bool _isLoading = false;
  Playlist? _playlist;
  List<Track> _tracks = [];

  @override
  void initState() {
    super.initState();
    if (widget.playlistId != null && widget.playlistId!.isNotEmpty && widget.playlistId != 'null') {
      _loadPlaylist();
    }
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
        _tracks = List.from(_playlist!.tracks);
      }
    } catch (e) {
      print('Error loading playlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading playlist: $e'), backgroundColor: Colors.red),
      );
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _savePlaylist() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a playlist name'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);

      bool isEditing = widget.playlistId != null && 
                      widget.playlistId!.isNotEmpty && 
                      widget.playlistId != 'null';

      if (isEditing) {
        await musicProvider.updatePlaylist(
          widget.playlistId!,
          _nameController.text,
          _descriptionController.text,
          _isPublic,
          authProvider.token!,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist updated successfully'), backgroundColor: Colors.green),
        );
      } else {
        await musicProvider.createPlaylist(
          _nameController.text,
          _descriptionController.text,
          _isPublic,
          authProvider.token!,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist created successfully'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error saving playlist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving playlist: $e'), backgroundColor: Colors.red),
      );
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
        title: Text(_isEditMode ? 'Edit Playlist' : 'Create Playlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _savePlaylist,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: _nameController,
                    labelText: 'Playlist Name',
                    validator: (value) => value?.isEmpty == true ? 'Please enter a name' : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _descriptionController,
                    labelText: 'Description',
                    maxLines: 3,
                  ),
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
                  const SizedBox(height: 24),
                  const Text(
                    'Tracks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  if (_tracks.isEmpty)
                    const EmptyState(
                      icon: Icons.music_note,
                      title: 'No tracks added',
                      subtitle: 'Add tracks to your playlist using the search feature',
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _tracks.length,
                      itemBuilder: (context, index) {
                        final track = _tracks[index];
                        return TrackCard(
                          track: track,
                          onTap: () {},
                        );
                      },
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final playlistId = _isEditMode ? widget.playlistId : null;
          Navigator.of(context).pushNamed('/track_search', arguments: playlistId);
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.black),
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
