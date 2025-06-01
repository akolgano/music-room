// lib/screens/playlists/playlists_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/playlist.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';

class PlaylistsScreen extends StatefulWidget {
  final bool publicOnly;
  const PlaylistsScreen({Key? key, this.publicOnly = false}) : super(key: key);

  @override 
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final _searchController = TextEditingController();
  List<Playlist> _filteredPlaylists = [];

  String get screenTitle => widget.publicOnly ? 'Public Playlists' : 'Your Playlists';
  
  List<Widget> get actions => [
    IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPlaylists),
  ];

  Widget? get floatingActionButton => !widget.publicOnly 
      ? FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
          child: const Icon(Icons.add),
        ) : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaylists());
  }

  Future<void> _loadPlaylists() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    
    if (authProvider.token != null) {
      if (widget.publicOnly) {
        await musicProvider.fetchPublicPlaylists(authProvider.token!);
      } else {
        await musicProvider.fetchUserPlaylists(authProvider.token!);
      }
    }
    _filterPlaylists('');
  }

  void _filterPlaylists(String query) {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    setState(() {
      final allPlaylists = musicProvider.playlists;
      _filteredPlaylists = query.isEmpty ? List.from(allPlaylists) : 
          allPlaylists.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(screenTitle),
        actions: actions,
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
            child: musicProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _filteredPlaylists.isEmpty
                    ? EmptyState(
                        icon: Icons.playlist_play,
                        title: 'No playlists found',
                        buttonText: widget.publicOnly ? null : 'Create Playlist',
                        onButtonPressed: widget.publicOnly ? null : () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPlaylists,
                        child: ListView.builder(
                          itemCount: _filteredPlaylists.length,
                          itemBuilder: (_, i) => PlaylistCard(
                            playlist: _filteredPlaylists[i],
                            onTap: () => Navigator.pushNamed(context, AppRoutes.playlistEditor, arguments: _filteredPlaylists[i].id),
                            onPlay: () => _showSuccess('Playing ${_filteredPlaylists[i].name}'),
                            onShare: widget.publicOnly ? () => _savePlaylist(_filteredPlaylists[i]) : null,
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Future<void> _savePlaylist(Playlist playlist) async {
    _showSuccess('Added to Your Library');
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
