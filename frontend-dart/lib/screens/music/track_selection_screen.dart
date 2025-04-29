// screens/music/track_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../models/track.dart';

class TrackSelectionScreen extends StatefulWidget {
  final String? playlistId;
  
  const TrackSelectionScreen({Key? key, this.playlistId}) : super(key: key);

  @override
  _TrackSelectionScreenState createState() => _TrackSelectionScreenState();
}

class _TrackSelectionScreenState extends State<TrackSelectionScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  bool _searchDeezer = true;
  
  final Set<Track> _selectedTracks = {};

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final tracks = musicProvider.searchResults;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Tracks'),
        actions: [
          Switch(
            value: _searchDeezer,
            onChanged: (value) {
              setState(() {
                _searchDeezer = value;
              });
            },
          ),
          Text(_searchDeezer ? 'Deezer' : 'Local'),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for tracks',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: _performSearch,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text('Search'),
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: tracks.isEmpty
                  ? const Center(child: Text('No tracks found'))
                  : ListView.builder(
                      itemCount: tracks.length,
                      itemBuilder: (ctx, i) => _buildTrackItem(tracks[i]),
                    ),
            ),
          if (tracks.isNotEmpty && _selectedTracks.isNotEmpty)
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_selectedTracks.length} track${_selectedTracks.length > 1 ? 's' : ''} selected',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _addSelectedTracks,
                      child: const Text('Add to Playlist'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackItem(Track track) {
    final isSelected = _selectedTracks.contains(track);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      color: isSelected ? Colors.blue.withOpacity(0.1) : null,
      child: ListTile(
        leading: isSelected
            ? Icon(Icons.check_circle, color: Colors.blue)
            : Icon(Icons.music_note),
        title: Text(track.name),
        subtitle: Text('${track.artist} - ${track.album}'),
        trailing: Checkbox(
          value: isSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedTracks.add(track);
              } else {
                _selectedTracks.remove(track);
              }
            });
          },
        ),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedTracks.remove(track);
            } else {
              _selectedTracks.add(track);
            }
          });
        },
      ),
    );
  }

  void _performSearch() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_searchDeezer) {
        await Provider.of<MusicProvider>(context, listen: false)
            .searchDeezerTracks(_searchController.text);
      } else {
        await Provider.of<MusicProvider>(context, listen: false)
            .searchTracks(_searchController.text);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to search tracks: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addSelectedTracks() async {
    if (_selectedTracks.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      
      for (final track in _selectedTracks) {
        if (track.deezerTrackId != null) {
          await musicProvider.addTrackFromDeezer(
            track.deezerTrackId!,
            authProvider.token!,
          );
        }
      }
      
      if (widget.playlistId != null) {
        final trackIds = _selectedTracks.map((t) => t.id).toList();
        
        await musicProvider.addTracksToPlaylist(
          widget.playlistId!,
          trackIds,
          authProvider.token!,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${_selectedTracks.length} tracks to playlist'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop(true);
      } else {
        showDialog(
          context: context,
          builder: (ctx) => _buildNewPlaylistDialog(),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add tracks: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Widget _buildNewPlaylistDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isPublic = false;
    
    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Create New Playlist'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Playlist Name',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Make Public'),
                value: isPublic,
                onChanged: (value) {
                  setState(() {
                    isPublic = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              Text(
                '${_selectedTracks.length} tracks will be added',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a playlist name'),
                  ),
                );
                return;
              }
              
              Navigator.of(context).pop();
              
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final musicProvider = Provider.of<MusicProvider>(context, listen: false);
                
                final trackIds = _selectedTracks.map((t) => t.id).toList();
                
                final playlistId = await musicProvider.saveSharedPlaylist(
                  nameController.text,
                  descController.text,
                  isPublic,
                  trackIds,
                  authProvider.token!,
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Created playlist with ${_selectedTracks.length} tracks'),
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
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
