// screens/music/track_search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../models/track.dart';
import 'deezer_track_detail_screen.dart';

class TrackSearchScreen extends StatefulWidget {
  final String? playlistId;
  final Track? initialTrack;
  final bool searchDeezer;

  const TrackSearchScreen({
    Key? key, 
    this.playlistId,
    this.initialTrack,
    this.searchDeezer = true,
  }) : super(key: key);

  @override
  _TrackSearchScreenState createState() => _TrackSearchScreenState();
}

class _TrackSearchScreenState extends State<TrackSearchScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  bool _searchDeezer = true;

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final tracks = musicProvider.searchResults;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Tracks'),
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
                      itemBuilder: (ctx, i) => Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 5,
                        ),
                        child: ListTile(
                          title: Text(tracks[i].name),
                          subtitle: Text('${tracks[i].artist} - ${tracks[i].album}'),
                          onTap: () {
                            if (tracks[i].deezerTrackId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DeezerTrackDetailScreen(
                                    trackId: tracks[i].deezerTrackId!,
                                  ),
                                ),
                              );
                            }
                          },
                          trailing: widget.playlistId != null
                            ? IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () => _addTrackToPlaylist(tracks[i], authProvider.token!),
                              )
                            : IconButton(
                                icon: Icon(Icons.save),
                                onPressed: () => _addTrackToDatabase(tracks[i], authProvider.token!),
                              ),
                        ),
                      ),
                    ),
            ),
        ],
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

  void _addTrackToPlaylist(Track track, String token) async {
    try {
      if (track.deezerTrackId != null) {
        await Provider.of<MusicProvider>(context, listen: false)
            .addTrackFromDeezer(track.deezerTrackId!, token);
      }

      if (widget.playlistId != null) {
        await Provider.of<MusicProvider>(context, listen: false)
            .addTrackToPlaylist(widget.playlistId!, track.id, token);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${track.name} to playlist'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add track: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addTrackToDatabase(Track track, String token) async {
    try {
      if (track.deezerTrackId != null) {
        await Provider.of<MusicProvider>(context, listen: false)
            .addTrackFromDeezer(track.deezerTrackId!, token);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Track ${track.name} saved to your library'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save track: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
