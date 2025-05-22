// screens/music/public_playlists_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/scheduler.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../models/playlist.dart';
import '../../widgets/api_error_widget.dart';
import '../../widgets/playlist_item.dart';
import '../../config/theme.dart';

class MusicColors {
  static const Color primary = Color(0xFF1DB954);
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF282828);
  static const Color surfaceVariant = Color(0xFF333333);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFB3B3B3);
  static const Color error = Color(0xFFE91429);
}

class PublicPlaylistsScreen extends StatefulWidget {
  const PublicPlaylistsScreen({Key? key}) : super(key: key);

  @override
  _PublicPlaylistsScreenState createState() => _PublicPlaylistsScreenState();
}

class _PublicPlaylistsScreenState extends State<PublicPlaylistsScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<Playlist> _filteredPlaylists = [];
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadPlaylists();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _loadPlaylists();
      });
      _isInit = true;
    }
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
      backgroundColor: MusicColors.background,
      appBar: AppBar(
        backgroundColor: MusicColors.background,
        title: const Text(
          'Public Playlists',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Find in playlists',
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.7),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _filterPlaylists('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: MusicColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: MusicColors.primary),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              cursorColor: MusicColors.primary,
              onChanged: _filterPlaylists,
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: MusicColors.primary,
                ),
              ),
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
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.playlist_play,
                      size: 64,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No playlists found',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your search',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadPlaylists,
                color: MusicColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: _filteredPlaylists.length,
                  itemBuilder: (ctx, i) => PlaylistItem(
                    playlist: _filteredPlaylists[i],
                    onPlay: () => _playPlaylist(_filteredPlaylists[i]),
                    onShare: () => _savePlaylist(_filteredPlaylists[i]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _playPlaylist(Playlist playlist) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing ${playlist.name}'),
        backgroundColor: MusicColors.surfaceVariant,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: MusicColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Added to Your Library',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: MusicColors.surfaceVariant,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save playlist: ${error.toString()}'),
          backgroundColor: MusicColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }
}
