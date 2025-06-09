// lib/screens/playlists/playlists_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../core/app_core.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/api_error_widget.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../utils/dialog_utils.dart';
import '../base_screen.dart';

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

class _PlaylistsScreenState extends BaseScreen<PlaylistsScreen> {
  List<Playlist> _filteredPlaylists = [];

  @override
  String get screenTitle => widget.title ?? 
      (widget.publicOnly ? 'Public Playlists' : 'Your Playlists');
  
  @override
  List<Widget> get actions => [
    IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPlaylists),
    if (widget.publicOnly)
      IconButton(
        icon: const Icon(Icons.info_outline),
        onPressed: _showPublicPlaylistsInfo,
      ),
  ];

  @override
  Widget? get floatingActionButton => (widget.showCreateButton && !widget.publicOnly) 
      ? FloatingActionButton.extended(
          onPressed: () => navigateTo(AppRoutes.playlistEditor),
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

  @override
  Widget buildContent() {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, _) {
        return Column(
          children: [
            if (widget.publicOnly) _buildPublicPlaylistsBanner(),
            Expanded(child: _buildPlaylistContent(musicProvider)),
          ],
        );
      },
    );
  }

  Widget _buildPublicPlaylistsBanner() {
    return InfoBanner(
      title: 'Discover Community Playlists',
      message: 'Explore playlists created by the Music Room community',
      icon: Icons.public,
      actionText: 'Learn More',
      onAction: _showPublicPlaylistsInfo,
    );
  }

  Widget _buildPlaylistContent(MusicProvider musicProvider) {
    if (musicProvider.isLoading) {
      return buildLoadingState('Loading playlists...');
    }

    if (musicProvider.hasConnectionError) {
      return ApiErrorWidget(
        message: musicProvider.errorMessage ?? 'Failed to load playlists',
        onRetry: _loadPlaylists,
        errorType: ErrorType.connection,
        context: 'playlist loading',
      );
    }

    return buildSearchableList<Playlist>(
      items: musicProvider.playlists,
      itemBuilder: (playlist, index) => PlaylistCard(
        playlist: playlist,
        onTap: () => _viewPlaylist(playlist),
        onPlay: () => _playPlaylist(playlist),
        onShare: widget.publicOnly ? () => _savePlaylist(playlist) : null,
      ),
      searchFilter: (playlist) => playlist.name,
      searchHint: 'Search playlists...',
      emptyState: _buildEmptyState(),
      noResultsState: _buildNoResultsState(),
      onRefresh: _loadPlaylists,
    );
  }

  Widget _buildEmptyState() {
    if (widget.publicOnly) {
      return EmptyState(
        icon: Icons.public,
        title: 'No public playlists found',
        subtitle: 'Be the first to create a public playlist!',
        buttonText: 'Create Public Playlist',
        onButtonPressed: () => navigateTo(AppRoutes.playlistEditor),
      );
    }

    return EmptyState(
      icon: Icons.playlist_play,
      title: 'No playlists found',
      subtitle: 'Create your first playlist to get started!',
      buttonText: 'Create Playlist',
      onButtonPressed: () => navigateTo(AppRoutes.playlistEditor),
    );
  }

  Widget _buildNoResultsState() {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No playlists match your search',
      subtitle: 'Try different keywords or create a new playlist',
      buttonText: widget.publicOnly ? null : 'Create Playlist',
      onButtonPressed: widget.publicOnly ? null : () => navigateTo(AppRoutes.playlistEditor),
    );
  }

  Future<void> _loadPlaylists() async {
    await runAsyncAction(
      () async {
        final musicProvider = Provider.of<MusicProvider>(context, listen: false);
        
        if (auth.token != null) {
          if (widget.publicOnly) {
            await musicProvider.fetchPublicPlaylists(auth.token!);
          } else {
            await musicProvider.fetchUserPlaylists(auth.token!);
          }
        }
      },
      errorMessage: 'Failed to load playlists',
    );
  }

  void _viewPlaylist(Playlist playlist) {
    if (playlist.id.isNotEmpty && playlist.id != 'null') {
      navigateTo(AppRoutes.playlistEditor, arguments: playlist.id);
    } else {
      showError('Cannot view playlist: Invalid ID');
    }
  }

  void _playPlaylist(Playlist playlist) {
    showSuccess('Playing ${playlist.name}');
  }

  Future<void> _savePlaylist(Playlist playlist) async {
    if (widget.publicOnly) {
      await runAsyncAction(
        () async {
          final musicProvider = Provider.of<MusicProvider>(context, listen: false);
          await musicProvider.savePublicPlaylist(playlist.id, auth.token!);
        },
        successMessage: 'Added "${playlist.name}" to your library',
        errorMessage: 'Failed to save playlist',
      );
    }
  }

  void _showPublicPlaylistsInfo() {
    DialogUtils.showInfoDialog(
      context: context,
      title: 'Public Playlists',
      icon: Icons.public,
      message: 'Discover and explore music from the community',
      points: [
        'Created by Music Room community members',
        'Anyone can discover and add them to their library',
        'Perfect for finding new music and artists',
        'Create your own public playlist to share with others',
      ],
      tip: 'Tap the share icon to add a playlist to your library!',
      onAction: () => navigateTo(AppRoutes.playlistEditor),
      actionText: 'Create Public Playlist',
    );
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
