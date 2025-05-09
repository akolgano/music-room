// lib/screens/music/playlist_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';
import '../../widgets/track_item.dart';
import 'track_search_screen.dart';

class MusicPlaylistEditorScreen extends StatelessWidget {
  const MusicPlaylistEditorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlaylistEditorScreen();
  }
}

class PlaylistEditorScreen extends StatefulWidget {
  final String? playlistId;
  final bool isEnhanced;
  
  const PlaylistEditorScreen({
    Key? key, 
    this.playlistId,
    this.isEnhanced = true,
  }) : super(key: key);

  @override
  _PlaylistEditorScreenState createState() => _PlaylistEditorScreenState();
}

class _PlaylistEditorScreenState extends State<PlaylistEditorScreen> {
  bool _isLoading = true;
  bool _isEditing = false;
  Playlist? _playlist;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late bool _isPublic;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _isPublic = false;
    _isEditing = widget.playlistId == null;
    _loadPlaylist();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylist() async {
    if (widget.playlistId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      
      _playlist = await musicProvider.getPlaylist(
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

  Future<void> _savePlaylist() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      
      if (widget.playlistId == null) {
        await musicProvider.createPlaylist(
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
        
        Navigator.of(context).pop();
      } else {
        await musicProvider.updatePlaylist(
          widget.playlistId!,
          _nameController.text,
          _descriptionController.text,
          _isPublic,
          authProvider.token!,
        );
        
        _playlist = await musicProvider.getPlaylist(
          widget.playlistId!,
          authProvider.token!,
        );
        
        setState(() {
          _isEditing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Playlist updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save playlist: ${error.toString()}'),
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
      _isLoading = true;
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
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistId == null 
            ? 'Create Playlist' 
            : _isEditing ? 'Edit Playlist' : (_playlist?.name ?? 'Playlist')),
        actions: _buildAppBarActions(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isEditing || widget.playlistId == null
              ? _buildPlaylistForm()
              : _buildPlaylistView(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
  
  List<Widget> _buildAppBarActions() {
    return [
      if (widget.playlistId != null && !_isEditing)
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            setState(() {
              _isEditing = true;
              _nameController.text = _playlist?.name ?? '';
              _descriptionController.text = _playlist?.description ?? '';
              _isPublic = _playlist?.isPublic ?? false;
            });
          },
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
    ];
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (widget.playlistId != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _nameController.text = _playlist?.name ?? '';
                          _descriptionController.text = _playlist?.description ?? '';
                          _isPublic = _playlist?.isPublic ?? false;
                        });
                      },
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
                    onPressed: _savePlaylist,
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
              const SizedBox(height: 5),
              Chip(
                label: Text(_playlist!.isPublic ? 'Public' : 'Private'),
                backgroundColor: _playlist!.isPublic ? Colors.green[100] : Colors.red[100],
              ),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Tracks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: _playlist!.tracks.isEmpty
              ? const Center(child: Text('No tracks in this playlist'))
              : ListView.builder(
                  itemCount: _playlist!.tracks.length,
                  itemBuilder: (ctx, i) => _buildTrackItem(_playlist!.tracks[i]),
                ),
        ),
      ],
    );
  }
  
  Widget? _buildFloatingActionButton() {
    if (widget.playlistId != null && !_isEditing) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => TrackSearchScreen(playlistId: widget.playlistId),
            ),
          ).then((_) => _loadPlaylist());
        },
        child: const Icon(Icons.add),
      );
    }
    return null;
  }
  
  Widget _buildTrackItem(Track track) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: track.imageUrl != null && track.imageUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  track.imageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.music_note, color: Colors.grey[700]),
                    );
                  },
                ),
              )
            : CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.music_note, color: Colors.grey[700]),
              ),
        title: Text(track.name),
        subtitle: Text('${track.artist} - ${track.album}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Playing ${track.name}'),
                  ),
                );
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
    );
  }
  
  Future<void> _removeTrackFromPlaylist(Track track) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${track.name}" from playlist'),
        backgroundColor: Colors.green,
      ),
    );
    
    _loadPlaylist();
  }
}
