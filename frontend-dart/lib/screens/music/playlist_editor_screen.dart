// screens/music/playlist_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';
import 'track_search_screen.dart';

class MusicPlaylistEditorScreen extends StatefulWidget {
  final String? playlistId;
  
  const MusicPlaylistEditorScreen({Key? key, this.playlistId}) : super(key: key);

  @override
  _MusicPlaylistEditorScreenState createState() => _MusicPlaylistEditorScreenState();
}

class _MusicPlaylistEditorScreenState extends State<MusicPlaylistEditorScreen> {
  bool _isLoading = true;
  Playlist? _playlist;
  
  @override
  void initState() {
    super.initState();
    _loadPlaylist();
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistId == null 
            ? 'Create Playlist' 
            : _playlist?.name ?? 'Playlist Editor'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.playlistId == null
              ? _buildCreatePlaylistForm()
              : _buildPlaylistEditor(),
      floatingActionButton: widget.playlistId != null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => TrackSearchScreen(playlistId: widget.playlistId),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  Widget _buildCreatePlaylistForm() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isPublic = false;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create New Playlist',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Playlist Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: descriptionController,
            decoration: InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 15),
          StatefulBuilder(
            builder: (context, setState) => SwitchListTile(
              title: const Text('Make Public'),
              value: isPublic,
              onChanged: (value) {
                setState(() {
                  isPublic = value;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a playlist name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final musicProvider = Provider.of<MusicProvider>(context, listen: false);
                
                await musicProvider.createPlaylist(
                  nameController.text,
                  descriptionController.text,
                  isPublic,
                  authProvider.token!,
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Playlist created successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                Navigator.of(context).pop();
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to create playlist: ${error.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('CREATE PLAYLIST'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlaylistEditor() {
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
  
  Widget _buildTrackItem(Track track) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(track.name),
        subtitle: Text('${track.artist} - ${track.album}'),
        trailing: IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Playing ${track.name}'),
              ),
            );
          },
        ),
      ),
    );
  }
}
