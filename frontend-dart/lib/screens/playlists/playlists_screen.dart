// lib/screens/playlists/playlists_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../core/app_core.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../utils/snackbar_utils.dart';

class PlaylistsScreen extends StatefulWidget {
  final bool publicOnly;
  final String? title; 
  final bool showCreateButton; 

  const PlaylistsScreen({
    Key? key, 
    this.publicOnly = false,
    this.title,
    this.showCreateButton = true,
  }) : super(key: key);

  @override 
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final _searchController = TextEditingController();
  List<Playlist> _filteredPlaylists = [];
  bool _isLoading = false;

  String get screenTitle => widget.title ?? 
      (widget.publicOnly ? 'Public Playlists' : 'Your Playlists');
  
  List<Widget> get actions => [
    IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPlaylists),
    if (widget.publicOnly)
      IconButton(
        icon: const Icon(Icons.info_outline),
        onPressed: _showPublicPlaylistsInfo,
      ),
  ];

  Widget? get floatingActionButton => (widget.showCreateButton && !widget.publicOnly) 
      ? FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add),
          label: const Text('Create Playlist'),
        ) : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaylists());
  }

  Future<void> _loadPlaylists() async {
    setState(() => _isLoading = true);

    try {
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
    } catch (e) {
      SnackBarUtils.showError(context, 'Failed to load playlists');
    }

    setState(() => _isLoading = false);
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
          _buildSearchHeader(),
          if (widget.publicOnly) _buildPublicPlaylistsBanner(),
          Expanded(child: _buildPlaylistContent(musicProvider)),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: AppTextField(
        controller: _searchController,
        labelText: 'Search playlists',
        prefixIcon: Icons.search,
        onChanged: _filterPlaylists,
      ),
    );
  }

  Widget _buildPublicPlaylistsBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.public, color: AppTheme.primary, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Discover playlists created by the Music Room community',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: _showPublicPlaylistsInfo,
            child: const Text('Learn More', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistContent(MusicProvider musicProvider) {
    if (_isLoading) {
      return CommonWidgets.loadingWidget('Loading playlists...');
    }

    if (musicProvider.hasConnectionError) {
      return _buildErrorView(musicProvider);
    }

    if (_filteredPlaylists.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadPlaylists,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80), 
        itemCount: _filteredPlaylists.length,
        itemBuilder: (_, i) => PlaylistCard(
          playlist: _filteredPlaylists[i],
          onTap: () => _viewPlaylist(_filteredPlaylists[i]),
          onPlay: () => _playPlaylist(_filteredPlaylists[i]),
          onShare: widget.publicOnly ? () => _savePlaylist(_filteredPlaylists[i]) : null,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (widget.publicOnly) {
      return CommonWidgets.emptyState(
        icon: Icons.public,
        title: 'No public playlists found',
        subtitle: _searchController.text.isNotEmpty 
            ? 'Try searching with different keywords'
            : 'Be the first to create a public playlist!',
        buttonText: 'Create Public Playlist',
        onButtonPressed: () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
      );
    }

    return CommonWidgets.emptyState(
      icon: Icons.playlist_play,
      title: 'No playlists found',
      subtitle: _searchController.text.isNotEmpty 
          ? 'No playlists match your search'
          : 'Create your first playlist to get started!',
      buttonText: 'Create Playlist',
      onButtonPressed: () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
    );
  }

  Widget _buildErrorView(MusicProvider musicProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Connection Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            musicProvider.errorMessage ?? 'Failed to load playlists',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadPlaylists,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
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
      SnackBarUtils.showError(context, 'Cannot view playlist: Invalid ID');
    }
  }

  void _playPlaylist(Playlist playlist) {
    SnackBarUtils.showSuccess(context, 'Playing ${playlist.name}');
  }

  void _savePlaylist(Playlist playlist) {
    if (widget.publicOnly) {
      SnackBarUtils.showSuccess(context, 'Added "${playlist.name}" to your library');
    }
  }

  void _showPublicPlaylistsInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Row(
          children: [
            Icon(Icons.public, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Public Playlists', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About Public Playlists:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Created by Music Room community members', style: TextStyle(color: Colors.grey)),
            Text('• Anyone can discover and add them to their library', style: TextStyle(color: Colors.grey)),
            Text('• Perfect for finding new music and artists', style: TextStyle(color: Colors.grey)),
            Text('• Create your own public playlist to share with others', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
            Text('Tip: Tap the share icon to add a playlist to your library!', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.playlistEditor);
            },
            child: const Text('Create Public Playlist'),
          ),
        ],
      ),
    );
  }

  @override 
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class PublicPlaylistsScreen extends StatelessWidget {
  const PublicPlaylistsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const PlaylistsScreen(
      publicOnly: true,
      title: 'Public Playlists',
      showCreateButton: false,
    );
  }
}
