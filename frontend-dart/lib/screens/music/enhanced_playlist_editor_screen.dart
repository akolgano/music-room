// screens/music/enhanced_playlist_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/scheduler.dart';
import 'track_search_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';
import '../../services/music_player_service.dart';

class EnhancedPlaylistEditorScreen extends StatefulWidget {
  final String? playlistId;
  
  const EnhancedPlaylistEditorScreen({Key? key, this.playlistId}) : super(key: key);

  @override
  _EnhancedPlaylistEditorScreenState createState() => _EnhancedPlaylistEditorScreenState();
}

class _EnhancedPlaylistEditorScreenState extends State<EnhancedPlaylistEditorScreen> {
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isDeleting = false;
  Playlist? _playlist;
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage; 
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late bool _isPublic;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _isPublic = false;
    
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadPlaylist();
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _playTrack(Track track) async {
    try {
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      final playerService = Provider.of<MusicPlayerService>(context, listen: false);
      
      if (track.deezerTrackId != null) {
        final previewUrl = await musicProvider.getDeezerTrackPreviewUrl(track.deezerTrackId!);
        
        if (previewUrl != null) {
          await playerService.playTrack(track, previewUrl);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No preview available for this track'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preview not available for non-Deezer tracks'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to play track: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadPlaylist() async {
    if (widget.playlistId == null) {
      setState(() {
        _isLoading = false;
        _isEditing = true;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      
      _playlist = await musicProvider.getPlaylistDetails(
        widget.playlistId!,
        authProvider.token!,
      );
      
      _nameController.text = _playlist?.name ?? '';
      _descriptionController.text = _playlist?.description ?? '';
      _isPublic = _playlist?.isPublic ?? false;
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load playlist: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      
      if (!_isEditing) {
        _nameController.text = _playlist?.name ?? '';
        _descriptionController.text = _playlist?.description ?? '';
        _isPublic = _playlist?.isPublic ?? false;
      }
    });
  }
  
  Future<void> _savePlaylistChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      
      await musicProvider.updatePlaylist(
        widget.playlistId!,
        _nameController.text,
        _descriptionController.text,
        _isPublic,
        authProvider.token!,
      );
      
      _playlist = await musicProvider.getPlaylistDetails(
        widget.playlistId!,
        authProvider.token!,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playlist updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {
        _isEditing = false;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update playlist: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _createNewPlaylist() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      
      final playlistId = await musicProvider.createNewPlaylist(
        _nameController.text,
        _descriptionController.text,
        _isPublic,
        authProvider.token!,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playlist created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).pop(playlistId);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create playlist: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _deletePlaylist() async {
    setState(() {
      _isDeleting = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      
      await musicProvider.deletePlaylist(
        widget.playlistId!,
        authProvider.token!,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playlist deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).pop();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete playlist: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() {
      _isDeleting = false;
    });
  }
  
  Future<void> _removeTrackFromPlaylist(Track track) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      
      _playlist = await musicProvider.getPlaylistDetails(
        widget.playlistId!,
        authProvider.token!,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "${track.name}" from playlist'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove track: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<T?> apiCallSilent<T>(Future<T> Function() call) async {
    _isLoading = true;
    
    try {
      final result = await call();
      return result;
    } catch (error) {
      _errorMessage = 'Unable to connect to server. Please check your internet connection.';
      print('API error: $error');
    } finally {
      _isLoading = false;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistId == null 
            ? 'Create Playlist' 
            : _isEditing ? 'Edit Playlist' : (_playlist?.name ?? 'Playlist')),
        actions: [
          if (widget.playlistId != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEditMode,
            ),
          if (widget.playlistId != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Playlist'),
                    content: const Text('Are you sure you want to delete this playlist? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _deletePlaylist();
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isEditing || widget.playlistId == null
              ? _buildPlaylistForm()
              : _buildPlaylistView(),
      floatingActionButton: widget.playlistId != null && !_isEditing
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => TrackSearchScreen(playlistId: widget.playlistId),
                  ),
                ).then((_) => _loadPlaylist());
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  Widget _buildPlaylistForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text(
              widget.playlistId == null ? 'Create New Playlist' : 'Edit Playlist',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Playlist Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a playlist name';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 15),
            SwitchListTile(
              title: const Text('Make Public'),
              subtitle: const Text('Public playlists can be seen by all users'),
              value: _isPublic,
              onChanged: (value) {
                setState(() {
                  _isPublic = value;
                });
              },
            ),
            const SizedBox(height: 20),
            if (_isDeleting)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (widget.playlistId != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _toggleEditMode,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('CANCEL'),
                      ),
                    ),
                  if (widget.playlistId != null)
                    const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.playlistId == null ? _createNewPlaylist : _savePlaylistChanges,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(widget.playlistId == null ? 'CREATE' : 'SAVE'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlaylistView() {
    if (_playlist == null) {
      return const Center(child: Text('Playlist not found'));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _playlist!.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              if (_playlist!.description.isNotEmpty)
                Text(
                  _playlist!.description,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              const SizedBox(height: 5),
              Text(
                'Created by: ${_playlist!.creator}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Row(
                children: [
                  Chip(
                    label: Text(_playlist!.isPublic ? 'Public' : 'Private'),
                    backgroundColor: _playlist!.isPublic ? Colors.green[100] : Colors.red[100],
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('${_playlist!.tracks.length} tracks'),
                    backgroundColor: Colors.blue[100],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tracks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_playlist!.tracks.isEmpty)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => TrackSearchScreen(playlistId: widget.playlistId),
                          ),
                        ).then((_) => _loadPlaylist());
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Tracks'),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _playlist!.tracks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text('No tracks in this playlist'),
                      const SizedBox(height: 16),
                      const Text(
                        'Tap the + button to add tracks',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _playlist!.tracks.length,
                  itemBuilder: (ctx, i) => _buildTrackItem(_playlist!.tracks[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildTrackItem(Track track) {
    final playerService = Provider.of<MusicPlayerService>(context);
    final isPlaying = playerService.currentTrack?.id == track.id && playerService.isPlaying;
    
    return Dismissible(
      key: Key(track.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) {
        return showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove Track'),
            content: Text('Are you sure you want to remove "${track.name}" from this playlist?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _removeTrackFromPlaylist(track);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: _buildTrackImage(track),
          title: Text(track.name),
          subtitle: Text('${track.artist} - ${track.album}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: isPlaying ? Colors.indigo : null,
                ),
                onPressed: () {
                  if (isPlaying) {
                    playerService.pause();
                  } else {
                    _playTrack(track);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Remove Track'),
                      content: Text('Are you sure you want to remove "${track.name}" from this playlist?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _removeTrackFromPlaylist(track);
                          },
                          child: const Text('Remove'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackImage(Track track) {
    if (track.imageUrl != null && track.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          track.imageUrl!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackTrackImage();
          },
        ),
      );
    } else {
      return _buildFallbackTrackImage();
    }
  }

  Widget _buildFallbackTrackImage() {
    return CircleAvatar(
      backgroundColor: Colors.grey[300],
      child: Icon(Icons.music_note, color: Colors.grey[700]),
    );
  }
}
