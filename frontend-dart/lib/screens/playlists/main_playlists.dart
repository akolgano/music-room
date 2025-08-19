import 'package:flutter/material.dart';
import '../../providers/music_providers.dart';
import '../../core/constants_core.dart';
import '../../core/locator_core.dart';
import '../../core/navigation_core.dart';
import '../../widgets/app_widgets.dart'; 
import '../../widgets/sort_widgets.dart';
import '../../models/music_models.dart';
import '../../models/sort_models.dart';
import '../../services/player_services.dart';
import '../base_screens.dart';

class AllPlaylistsScreen extends StatefulWidget {
  const AllPlaylistsScreen({super.key});

  @override
  State<AllPlaylistsScreen> createState() => _AllPlaylistsScreenState();
}

class _AllPlaylistsScreenState extends BaseScreen<AllPlaylistsScreen> with WidgetsBindingObserver {
  PlaylistSortOption _currentSort = PlaylistSortOption.defaultOptions.first;
  List<Playlist> _sortedPlaylists = [];
  DateTime? _lastRefresh;

  @override
  String get screenTitle => 'All Playlists';

  @override
  List<Widget> get actions => [
    SortButton<PlaylistSortOption>(
      currentSort: _currentSort,
      onPressed: () => _showSortOptions(),
      showLabel: false,
    ),
    PopupMenuButton<String>(
      icon: const Icon(Icons.refresh),
      onSelected: (value) {
        if (value == 'normal') {
          _loadPlaylists();
        } else if (value == 'force') {
          _forceRefreshPlaylists();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'normal',
          child: Row(
            children: [
              Icon(Icons.refresh, size: 20),
              SizedBox(width: 8),
              Text('Refresh'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'force',
          child: Row(
            children: [
              Icon(Icons.refresh_sharp, size: 20),
              SizedBox(width: 8),
              Text('Force Refresh'),
            ],
          ),
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaylists());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshPlaylistsIfNeeded();
    }
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
                  onTap: () => navigateTo(AppRoutes.playlistDetail, arguments: playlist.id), 
                  onPlay: () => _playPlaylist(playlist),
                  onDelete: () => _deletePlaylist(playlist),
                  showPlayButton: true,
                  showDeleteButton: true,
                  currentUsername: auth.username,
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
        _lastRefresh = DateTime.now();
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PlaylistSortBottomSheet(
        currentSort: _currentSort,
        onSortChanged: (PlaylistSortOption newSort) {
          setState(() {
            _currentSort = newSort;
          });
        },
      ),
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

  void _refreshPlaylistsIfNeeded() {
    if (_lastRefresh == null || DateTime.now().difference(_lastRefresh!).inSeconds > 30) {
      AppLogger.debug('Auto-refreshing playlists due to app resume', 'AllPlaylistsScreen');
      _loadPlaylists();
    }
  }

  Future<void> _forceRefreshPlaylists() async {
    await runAsyncAction(
      () async {
        final musicProvider = getProvider<MusicProvider>();
        AppLogger.debug('Force refreshing all playlists (clearing cache first)', 'AllPlaylistsScreen');
        await musicProvider.forceRefreshPlaylists(auth.token!);
        _lastRefresh = DateTime.now();
        AppLogger.debug('Force refresh completed: ${musicProvider.playlists.length} total playlists', 'AllPlaylistsScreen');
      },
      errorMessage: 'Failed to refresh playlists',
      successMessage: 'Playlists refreshed successfully',
    );
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    final confirmed = await showConfirmDialog(
      'Delete Playlist',
      'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.'
    );
    
    if (confirmed) {
      await runAsyncAction(
        () async {
          final musicProvider = getProvider<MusicProvider>();
          await musicProvider.deletePlaylist(playlist.id, auth.token!);
        },
        successMessage: 'Playlist "${playlist.name}" deleted successfully',
        errorMessage: 'Failed to delete playlist',
      );
    }
  }
}
