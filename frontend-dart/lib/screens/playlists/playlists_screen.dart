import 'package:flutter/material.dart';
import '../../providers/music_provider.dart';
import '../../core/constants.dart';
import '../../core/service_locator.dart';
import '../../core/logging_navigation_observer.dart';
import '../../widgets/app_widgets.dart'; 
import '../../widgets/track_sort_bottom_sheet.dart';
import '../../models/music_models.dart';
import '../../models/sort_models.dart';
import '../../services/music_player_service.dart';
import '../base_screen.dart';

class AllPlaylistsScreen extends StatefulWidget {
  const AllPlaylistsScreen({super.key});

  @override
  State<AllPlaylistsScreen> createState() => _AllPlaylistsScreenState();
}

class _AllPlaylistsScreenState extends BaseScreen<AllPlaylistsScreen> {
  PlaylistSortOption _currentSort = PlaylistSortOption.defaultOptions.first;
  List<Playlist> _sortedPlaylists = [];

  @override
  String get screenTitle => 'All Playlists';

  @override
  List<Widget> get actions => [
    PlaylistSortButton(
      currentSort: _currentSort,
      onPressed: () => _showSortOptions(),
      showLabel: false,
    ),
    IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPlaylists),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaylists());
  }

  @override
  Widget buildContent() {
    return buildConsumerContent<MusicProvider>(
      builder: (context, musicProvider) {
        _updateSortedPlaylists(musicProvider.playlists);
        return Column(
          children: [
            if (_sortedPlaylists.isNotEmpty && _currentSort.displayName != PlaylistSortOption.defaultOptions.first.displayName)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.sort, size: 16, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text(
                      'Sorted by: ${_currentSort.displayName}',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: buildListWithRefresh<Playlist>(
                items: _sortedPlaylists,
                onRefresh: _loadPlaylists,
                itemBuilder: (playlist, index) => AppWidgets.playlistCard( 
                  playlist: playlist,
                  onTap: () => _viewPlaylist(playlist), 
                  onPlay: () => _playPlaylist(playlist),
                  showPlayButton: true,
                ),
                emptyState: AppWidgets.emptyState( 
                  icon: Icons.playlist_play,
                  title: 'No playlists found',
                  subtitle: 'Your playlists and public playlists from other users will appear here',
                  buttonText: 'Create Playlist',
                  onButtonPressed: () => navigateTo(AppRoutes.playlistEditor),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadPlaylists() async {
    await runAsyncAction(
      () async {
        final musicProvider = getProvider<MusicProvider>();
        AppLogger.debug('Loading all playlists (user + public) with token: ${auth.token?.substring(0, 10)}...', 'AllPlaylistsScreen');
        await musicProvider.fetchAllPlaylists(auth.token!);
        AppLogger.debug('Loaded ${musicProvider.playlists.length} total playlists', 'AllPlaylistsScreen');
        

        if (musicProvider.playlists.isEmpty) {
          AppLogger.debug('NO PLAYLISTS FOUND - This could be the issue!', 'AllPlaylistsScreen');
        } else {
          for (final playlist in musicProvider.playlists) {
            AppLogger.debug('Playlist: ID=${playlist.id}, Name="${playlist.name}", Public=${playlist.isPublic}, Creator="${playlist.creator}", Current User: ${auth.username}', 'AllPlaylistsScreen');
          }
        }
      },
      errorMessage: 'Failed to load playlists',
    );
  }

  void _viewPlaylist(Playlist playlist) => navigateTo(AppRoutes.playlistDetail, arguments: playlist.id); 
  
  void _playPlaylist(Playlist playlist) async {
    if (playlist.tracks.isNotEmpty != true) {
      showInfo('This playlist is empty or tracks are not loaded');
      return;
    }

    try {
      setState(() {});
      final musicProvider = getProvider<MusicProvider>();
      await musicProvider.fetchPlaylistTracks(playlist.id, auth.token!);
      
      final playlistTracks = musicProvider.playlistTracks;
      if (playlistTracks.isEmpty) {
        showInfo('This playlist has no tracks to play');
        return;
      }

      final musicPlayerService = getIt<MusicPlayerService>();
      await musicPlayerService.setPlaylistAndPlay(
        playlist: playlistTracks,
        startIndex: 0,
        playlistId: playlist.id,
        authToken: auth.token,
      );
      
      showSuccess('Playing ${playlist.name}');
    } catch (e) {
      showError('Failed to play playlist: ${e.toString()}');
    } finally {
      setState(() {});
    }
  }
  

  void _showSortOptions() {
    PlaylistSortBottomSheet.show(
      context,
      currentSort: _currentSort,
      onSortChanged: (PlaylistSortOption newSort) {
        setState(() {
          _currentSort = newSort;
        });
      },
    );
  }

  void _updateSortedPlaylists(List<Playlist> playlists) {
    _sortedPlaylists = List.from(playlists);
    
    switch (_currentSort.field) {
      case PlaylistSortField.name:
        _sortedPlaylists.sort((a, b) {
          final comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          return _currentSort.order == SortOrder.ascending ? comparison : -comparison;
        });
        break;
        
      case PlaylistSortField.creator:
        _sortedPlaylists.sort((a, b) {
          final comparison = a.creator.toLowerCase().compareTo(b.creator.toLowerCase());
          return _currentSort.order == SortOrder.ascending ? comparison : -comparison;
        });
        break;
        
      case PlaylistSortField.trackCount:
        _sortedPlaylists.sort((a, b) {
          final aCount = a.tracks.length;
          final bCount = b.tracks.length;
          final comparison = aCount.compareTo(bCount);
          return _currentSort.order == SortOrder.ascending ? comparison : -comparison;
        });
        break;
        
      case PlaylistSortField.dateCreated:

        _sortedPlaylists.sort((a, b) {

          final comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          return _currentSort.order == SortOrder.ascending ? comparison : -comparison;
        });
        break;
    }
  }
}
