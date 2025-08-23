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
  List<Playlist> _sortedEvents = [];
  DateTime? _lastRefresh;

  @override
  String get screenTitle => 'Playlists & Events';

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
        _updateSortedPlaylistsAndEvents(musicProvider.playlists);
        return Column(
          children: [
            if ((_sortedPlaylists.isNotEmpty || _sortedEvents.isNotEmpty) && _currentSort.displayName != PlaylistSortOption.defaultOptions.first.displayName)
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
              child: RefreshIndicator(
                onRefresh: _loadPlaylists,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPlaylistsSection(),
                      const SizedBox(height: 16),
                      _buildEventsSection(),
                    ],
                  ),
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
        AppLogger.debug('Loading all playlists (user + public)', 'AllPlaylistsScreen');
        await musicProvider.fetchAllPlaylists(auth.token!);
        _lastRefresh = DateTime.now();
        AppLogger.debug('Loaded ${musicProvider.playlists.length} total playlists', 'AllPlaylistsScreen');
        
        if (musicProvider.playlists.isEmpty) {
          AppLogger.debug('NO PLAYLISTS FOUND - This could be the issue!', 'AllPlaylistsScreen');
        } else {
          for (final playlist in musicProvider.playlists) {
            AppLogger.debug('Playlist: ID=${playlist.id}, Name="${playlist.name}", Public=${playlist.isPublic}', 'AllPlaylistsScreen');
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

  void _updateSortedPlaylistsAndEvents(List<Playlist> allPlaylists) {
    _sortedPlaylists = allPlaylists.where((p) => !p.isEvent).toList();
    _sortedEvents = allPlaylists.where((p) => p.isEvent).toList();
    
    _sortPlaylists(_sortedPlaylists);
    _sortPlaylists(_sortedEvents);
  }

  void _sortPlaylists(List<Playlist> playlists) {
    switch (_currentSort.field) {
      case PlaylistSortField.name:
        playlists.sort((a, b) {
          final comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          return _currentSort.order == SortOrder.ascending ? comparison : -comparison;
        });
        break;
        
      case PlaylistSortField.creator:
        playlists.sort((a, b) {
          final comparison = a.creator.toLowerCase().compareTo(b.creator.toLowerCase());
          return _currentSort.order == SortOrder.ascending ? comparison : -comparison;
        });
        break;
        
      case PlaylistSortField.trackCount:
        playlists.sort((a, b) {
          final aCount = a.tracks.length;
          final bCount = b.tracks.length;
          final comparison = aCount.compareTo(bCount);
          return _currentSort.order == SortOrder.ascending ? comparison : -comparison;
        });
        break;
        
      case PlaylistSortField.dateCreated:
        playlists.sort((a, b) {
          final comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          return _currentSort.order == SortOrder.ascending ? comparison : -comparison;
        });
        break;
    }
  }

  Widget _buildPlaylistsSection() {
    return _buildSection(
      title: 'Playlists',
      icon: Icons.playlist_play,
      items: _sortedPlaylists,
      emptyMessage: 'No playlists found',
      emptySubtitle: 'Your regular playlists will appear here',
      createButtonText: 'Create Playlist',
      onCreatePressed: () => navigateTo(AppRoutes.playlistEditor),
    );
  }

  Widget _buildEventsSection() {
    return _buildSection(
      title: 'Events',
      icon: Icons.event,
      items: _sortedEvents,
      emptyMessage: 'No events found',
      emptySubtitle: 'Your event playlists will appear here',
      createButtonText: 'Create Event',
      onCreatePressed: () => navigateTo(AppRoutes.playlistEditor, arguments: {'isEvent': true}),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Playlist> items,
    required String emptyMessage,
    required String emptySubtitle,
    required String createButtonText,
    required VoidCallback onCreatePressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '${items.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            AppWidgets.emptyState(
              icon: icon,
              title: emptyMessage,
              subtitle: emptySubtitle,
              buttonText: createButtonText,
              onButtonPressed: onCreatePressed,
            )
          else
            ...items.map((playlist) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppWidgets.playlistCard(
                playlist: playlist,
                onTap: () => navigateTo(AppRoutes.playlistDetail, arguments: playlist.id),
                onPlay: () => _playPlaylist(playlist),
                onDelete: () => _deletePlaylist(playlist),
                showPlayButton: true,
                showDeleteButton: true,
                currentUsername: auth.username,
              ),
            )),
        ],
      ),
    );
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
