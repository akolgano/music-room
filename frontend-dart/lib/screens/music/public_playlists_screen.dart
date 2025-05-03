// screens/music/public_playlists_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../models/playlist.dart';
import '../../widgets/api_error_widget.dart';

class PublicPlaylistsScreen extends StatefulWidget {
  const PublicPlaylistsScreen({Key? key}) : super(key: key);

  @override
  _PublicPlaylistsScreenState createState() => _PublicPlaylistsScreenState();
}

class _PublicPlaylistsScreenState extends State<PublicPlaylistsScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<Playlist> _filteredPlaylists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      await musicProvider.fetchPublicPlaylists();
      _filterPlaylists('');
    } catch (error) {
      print('Error loading public playlists: $error');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _filterPlaylists(String query) {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final allPlaylists = musicProvider.playlists;

    if (query.isEmpty) {
      setState(() {
        _filteredPlaylists = List.from(allPlaylists);
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredPlaylists = allPlaylists.where((playlist) {
        return playlist.name.toLowerCase().contains(lowercaseQuery) ||
               playlist.description.toLowerCase().contains(lowercaseQuery) ||
               playlist.creator.toLowerCase().contains(lowercaseQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Playlists'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search playlists',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterPlaylists('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _filterPlaylists,
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (musicProvider.hasConnectionError)
            Expanded(
              child: ApiErrorWidget(
                message: musicProvider.errorMessage ?? 'Failed to load public playlists',
                onRetry: _loadPlaylists,
                isRetrying: musicProvider.isRetrying,
              ),
            )
          else if (_filteredPlaylists.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.playlist_play,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text('No playlists found'),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadPlaylists,
                child: ListView.builder(
                  itemCount: _filteredPlaylists.length,
                  itemBuilder: (ctx, i) => _buildPlaylistItem(_filteredPlaylists[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem(Playlist playlist) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        onTap: () => _openPlaylistDetails(playlist),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.playlist_play,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created by ${playlist.creator}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Chip(
                              label: Text('${playlist.tracks.length} tracks'),
                              backgroundColor: Colors.blue[100],
                              labelStyle: const TextStyle(fontSize: 12),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 8),
                            if (playlist.isPublic)
                              Chip(
                                label: const Text('Public'),
                                backgroundColor: Colors.green[100],
                                labelStyle: const TextStyle(fontSize: 12),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (playlist.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  playlist.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                    onPressed: () => _playPlaylist(playlist),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Save'),
                    onPressed: () => _savePlaylist(playlist),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPlaylistDetails(Playlist playlist) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PlaylistDetailScreen(playlist: playlist),
      ),
    );
  }

  void _playPlaylist(Playlist playlist) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing playlist: ${playlist.name}'),
      ),
    );
  }

  void _savePlaylist(Playlist playlist) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);

      final trackIds = playlist.tracks.map((track) => track.id).toList();

      await musicProvider.saveSharedPlaylist(
        playlist.name,
        playlist.description,
        playlist.isPublic,
        trackIds,
        authProvider.token!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playlist "${playlist.name}" saved to your library'),
          backgroundColor: Colors.green,
        ),
      );
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
}

class PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({Key? key, required this.playlist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Created by: ${playlist.creator}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                if (playlist.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    playlist.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Playing playlist: ${playlist.name}'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _savePlaylist(context, playlist);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Save'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Tracks (${playlist.tracks.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: playlist.tracks.isEmpty
                ? const Center(child: Text('No tracks in this playlist'))
                : ListView.builder(
                    itemCount: playlist.tracks.length,
                    itemBuilder: (ctx, i) => ListTile(
                      leading: CircleAvatar(
                        child: Text('${i + 1}'),
                      ),
                      title: Text(playlist.tracks[i].name),
                      subtitle: Text(playlist.tracks[i].artist),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Playing: ${playlist.tracks[i].name}'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _savePlaylist(BuildContext context, Playlist playlist) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);

      final trackIds = playlist.tracks.map((track) => track.id).toList();

      await musicProvider.saveSharedPlaylist(
        playlist.name,
        playlist.description,
        playlist.isPublic,
        trackIds,
        authProvider.token!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playlist "${playlist.name}" saved to your library'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save playlist: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
