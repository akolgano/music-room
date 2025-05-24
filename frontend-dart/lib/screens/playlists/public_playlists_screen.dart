// lib/screens/playlists/public_playlists_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/playlist.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/common_widgets.dart';

class PublicPlaylistsScreen extends StatefulWidget {
  const PublicPlaylistsScreen({Key? key}) : super(key: key);

  @override
  _PublicPlaylistsScreenState createState() => _PublicPlaylistsScreenState();
}

class _PublicPlaylistsScreenState extends State<PublicPlaylistsScreen> {
  final _searchController = TextEditingController();
  List<Playlist> _filteredPlaylists = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaylists());
  }

  Future<void> _loadPlaylists() async {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.token != null) {
      await musicProvider.fetchPublicPlaylists(authProvider.token!);
      _filterPlaylists('');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to view playlists'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterPlaylists(String query) {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    setState(() {
      final allPlaylists = musicProvider.playlists;
      _filteredPlaylists = query.isEmpty 
          ? List.from(allPlaylists) 
          : allPlaylists.where((p) => 
              p.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (musicProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          title: const Text('Public Playlists'),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Public Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlaylists,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AppTextField(
              controller: _searchController,
              labelText: 'Search playlists',
              prefixIcon: Icons.search,
              onChanged: _filterPlaylists,
            ),
          ),
          Expanded(
            child: musicProvider.hasConnectionError 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Connection Error',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          musicProvider.errorMessage ?? 'Failed to load playlists',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadPlaylists,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _filteredPlaylists.isEmpty
                    ? const EmptyState(
                        icon: Icons.public,
                        title: 'No public playlists found',
                        subtitle: 'Be the first to create a public playlist!',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPlaylists,
                        color: AppTheme.primary,
                        child: ListView.builder(
                          itemCount: _filteredPlaylists.length,
                          itemBuilder: (_, i) => PlaylistCard(
                            playlist: _filteredPlaylists[i],
                            onTap: () => _viewPlaylist(_filteredPlaylists[i]),
                            onPlay: () => _showPlayMessage(_filteredPlaylists[i]),
                            onShare: () => _savePlaylist(_filteredPlaylists[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _viewPlaylist(Playlist playlist) {
    if (playlist.id.isNotEmpty && playlist.id != 'null') {
      Navigator.of(context).pushNamed(AppRoutes.playlistEditor, arguments: playlist.id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot view playlist: Invalid ID'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPlayMessage(Playlist playlist) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing ${playlist.name}'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _savePlaylist(Playlist playlist) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to Your Library'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
