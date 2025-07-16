// lib/screens/playlists/playlist_detail_screen.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'playlist_licensing_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/dynamic_theme_provider.dart';
import '../../services/music_player_service.dart';
import '../../services/api_service.dart';
import '../../services/track_cache_service.dart';
import '../../core/service_locator.dart'; 
import '../../models/models.dart';
import '../../models/sort_models.dart';
import '../../services/track_sorting_service.dart';
import '../../core/core.dart';
import '../base_screen.dart';
import '../../providers/voting_provider.dart';
import '../../models/voting_models.dart';
import '../../core/theme_utils.dart'; 
import '../../widgets/widgets.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});
  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

// Voting is required as per PDF requirements
class _PlaylistDetailScreenState extends BaseScreen<PlaylistDetailScreen> {
  late final ApiService _apiService;
  late final TrackCacheService _trackCacheService;
  final Set<String> _fetchingTrackDetails = {};
  final List<Completer> _pendingOperations = []; 
  Playlist? _playlist;
  List<PlaylistTrack> _tracks = [];
  bool _isOwner = false;
  VotingProvider? _votingProvider;
  Timer? _autoRefreshTimer;

  @override
  String get screenTitle => _playlist?.name ?? 'Playlist Details';

  @override
  void initState() {
    super.initState();
    _apiService = getIt<ApiService>();
    _trackCacheService = getIt<TrackCacheService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _votingProvider = getProvider<VotingProvider>(listen: false);
        _votingProvider?.setVotingPermission(true);
        _loadData();
        _startAutoRefresh();
      }
    });
  }

  @override
  void dispose() {
    _cancelPendingOperations();
    _stopAutoRefresh();
    super.dispose();
  }

  @override
  List<Widget> get actions => [
    if (_isOwner) IconButton(icon: const Icon(Icons.settings), onPressed: _openPlaylistSettings, tooltip: 'Playlist Settings'),
    IconButton(icon: const Icon(Icons.share), onPressed: _sharePlaylist, tooltip: 'Share Playlist'),
    IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData, tooltip: 'Refresh'),
  ];

  @override
  Widget? get floatingActionButton {
    if (!_isOwner) return null;
    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await Navigator.pushNamed(context, AppRoutes.trackSearch, arguments: widget.playlistId);
        if (result == true && mounted) await _loadData();
      },
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.add), 
      label: const Text('Add Songs'),
    );
  }

  @override
  Widget buildContent() {
    if (_playlist == null) return buildLoadingState(message: 'Loading playlist...');

    return Consumer<DynamicThemeProvider>(
      builder: (context, themeProvider, _) {
        return RefreshIndicator(
          onRefresh: _loadData,
          color: ThemeUtils.getPrimary(context),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                PlaylistDetailWidgets.buildThemedPlaylistHeader(context, _playlist!),
                const SizedBox(height: 16), 
                PlaylistDetailWidgets.buildThemedPlaylistStats(context, _tracks),
                const SizedBox(height: 16), 
                PlaylistDetailWidgets.buildThemedPlaylistActions(context, onPlayAll: _playPlaylist, onShuffle: _shufflePlaylist),
                const SizedBox(height: 16), 
                _buildTracksSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTracksSection() {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, _) {
        final sortedTracks = musicProvider.sortedPlaylistTracks;
        final currentSort = musicProvider.currentSortOption;
        
        try {
          return Card(
            color: ThemeUtils.getSurface(context),
            elevation: 4,
            shadowColor: ThemeUtils.getPrimary(context).withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.queue_music, color: ThemeUtils.getPrimary(context), size: 20),
                          const SizedBox(width: 8),
                          Text('Tracks', style: ThemeUtils.getSubheadingStyle(context)),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '${sortedTracks.length} tracks',
                            style: ThemeUtils.getCaptionStyle(context),
                          ),
                          const SizedBox(width: 8),
                          SortButton(currentSort: currentSort, onPressed: _showSortOptions, showLabel: false),
                        ],
                      ),
                    ],
                  ),
                  if (currentSort.field != TrackSortField.position) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(currentSort.icon, size: 14, color: AppTheme.primary), 
                          const SizedBox(width: 4),
                          Text(
                            'Sorted by ${currentSort.displayName}',
                            style: const TextStyle(
                              color: AppTheme.primary, 
                              fontSize: 12, 
                              fontWeight: FontWeight.w500
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              musicProvider.resetToCustomOrder();
                              if (mounted) showInfo('Restored to custom order');
                            },
                            child: const Icon(Icons.close, size: 14, color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (sortedTracks.isEmpty) 
                    PlaylistDetailWidgets.buildEmptyTracksState(
                      isOwner: _isOwner,
                      onAddTracks: () => navigateTo(AppRoutes.trackSearch, arguments: widget.playlistId),
                    )
                  else 
                    _buildTracksList(sortedTracks, currentSort),
                ],
              ),
            ),
          );
        } catch (e, stackTrace) {
          if (kDebugMode) {
            developer.log('ERROR building tracks section: $e', name: 'PlaylistDetailScreen');
          }
          if (kDebugMode) {
            developer.log('Stack trace: $stackTrace', name: 'PlaylistDetailScreen');
          }
          return _buildErrorState(e.toString());
        }
      },
    );
  }

  Widget _buildTracksList(List<PlaylistTrack> tracks, TrackSortOption currentSort) {
    final canReorder = currentSort.field == TrackSortField.position && _isOwner;
    if (kDebugMode) {
      developer.log('Building tracks list: canReorder=$canReorder, tracks.length=${tracks.length}', name: 'PlaylistDetailScreen');
    }
    
    if (canReorder) {
      return ReorderableListView.builder(
        shrinkWrap: true, 
        physics: const NeverScrollableScrollPhysics(), 
        itemCount: tracks.length,
        onReorder: _onReorderTracks,
        itemBuilder: (context, index) {
          try {
            final playlistTrack = tracks[index];
            final keyString = 'reorder_${playlistTrack.trackId}_${playlistTrack.position}_$index';
            final uniqueKey = ValueKey(keyString);
            
            final widget = _buildTrackItem(playlistTrack, index, key: uniqueKey);
            return KeyedSubtree(key: uniqueKey, child: widget);
          } catch (e, stackTrace) {
            if (kDebugMode) {
              developer.log('ERROR building reorderable track item at index $index: $e', name: 'PlaylistDetailScreen');
            }
            return Container(
              key: ValueKey('error_$index'),
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error loading track at position $index', 
                style: const TextStyle(color: Colors.red)
              ),
            );
          }
        },
      );
    } else {
      return ListView.builder(
        shrinkWrap: true, 
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          try {
            final playlistTrack = tracks[index];
            return _buildTrackItem(playlistTrack, index);
          } catch (e, stackTrace) {
            if (kDebugMode) {
              developer.log('ERROR building track item at index $index: $e', name: 'PlaylistDetailScreen');
            }
            return Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error loading track at position $index', 
                style: const TextStyle(color: Colors.red)
              ),
            );
          }
        },
      );
    }
  }

  Widget _buildTrackItem(PlaylistTrack playlistTrack, int index, {Key? key}) {
    final track = playlistTrack.track;
    
    if (track?.deezerTrackId != null && 
        (track?.artist.isEmpty == true || track?.album.isEmpty == true) &&
        !_fetchingTrackDetails.contains(track!.deezerTrackId!) &&
        mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchTrackDetailsIfNeeded(playlistTrack, index);
      });
    }

    if (track?.deezerTrackId != null && 
        _fetchingTrackDetails.contains(track!.deezerTrackId!) &&
        (track.artist.isEmpty || track.album.isEmpty)) {
      return PlaylistDetailWidgets.buildLoadingTrackItem(key, playlistTrack, index);
    }

    return PlaylistDetailWidgets.buildTrackItem(
      context: context,
      playlistTrack: playlistTrack,
      index: index,
      isOwner: _isOwner,
      onPlay: () => _playTrackAt(index),
      onRemove: _isOwner ? () => _removeTrack(playlistTrack.trackId) : null,
      playlistId: widget.playlistId,
      key: key,
    );
  }

  Widget _buildErrorState(String error) {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Error loading tracks',
              style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $error',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadData() async {
    await runAsyncAction(
      () async {
        final musicProvider = getProvider<MusicProvider>();
        final themeProvider = getProvider<DynamicThemeProvider>();
        
        _playlist = await musicProvider.getPlaylistDetails(widget.playlistId, auth.token!);
        if (_playlist != null) {
          setState(() {
            _isOwner = _playlist!.creator == auth.username;
          });
          
          await musicProvider.fetchPlaylistTracks(widget.playlistId, auth.token!);
          setState(() => _tracks = musicProvider.playlistTracks);
          
          if (_votingProvider != null) {
            _votingProvider!.clearVotingData();
            _votingProvider!.setVotingPermission(true);
            _votingProvider!.initializeTrackPoints(_tracks);
          }
          
          if (_playlist!.imageUrl?.isNotEmpty == true) {
            themeProvider.extractAndApplyDominantColor(_playlist!.imageUrl);
          } else if (_tracks.isNotEmpty && _tracks.first.track?.imageUrl?.isNotEmpty == true) {
            themeProvider.extractAndApplyDominantColor(_tracks.first.track!.imageUrl);
          }
          
          _startBatchTrackDetailsFetch();
        }
      },
      errorMessage: 'Failed to load playlist details',
    );
  }

  Future<void> _refreshPlaylistData() async {
    try {
      final musicProvider = getProvider<MusicProvider>();
      await musicProvider.fetchPlaylistTracks(widget.playlistId, auth.token!);
      if (mounted) {
        setState(() => _tracks = musicProvider.playlistTracks);
        if (_votingProvider != null) _votingProvider!.initializeTrackPoints(_tracks);
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error refreshing playlist data: $e', name: 'PlaylistDetailScreen');
      }
    }
  }

  Future<void> _fetchTrackDetailsIfNeeded(PlaylistTrack playlistTrack, int index) async {
    final track = playlistTrack.track;
    final deezerTrackId = track?.deezerTrackId;
    
    if (deezerTrackId == null || 
        _fetchingTrackDetails.contains(deezerTrackId) || 
        !mounted ||
        (track != null && track.artist.isNotEmpty && track.album.isNotEmpty)) return;

    // Check if track is already cached
    if (_trackCacheService.isTrackCached(deezerTrackId)) {
      final cachedTrack = await _trackCacheService.getTrackDetails(deezerTrackId, auth.token!, _apiService);
      if (cachedTrack != null && mounted) {
        setState(() {
          if (index < _tracks.length && _tracks[index].trackId == playlistTrack.trackId) {
            _tracks[index] = PlaylistTrack(
              trackId: playlistTrack.trackId,
              name: playlistTrack.name,
              position: playlistTrack.position,
              points: playlistTrack.points,
              track: cachedTrack,
            );
          }
        });
        
        final musicProvider = getProvider<MusicProvider>();
        final providerTracks = List<PlaylistTrack>.from(musicProvider.playlistTracks);
        final providerIndex = providerTracks.indexWhere((t) => t.trackId == playlistTrack.trackId);
        if (providerIndex != -1) {
          providerTracks[providerIndex] = PlaylistTrack(
            trackId: playlistTrack.trackId,
            name: playlistTrack.name,
            position: playlistTrack.position,
            points: playlistTrack.points, 
            track: cachedTrack,
          );
          musicProvider.playlistTracks.clear();
          musicProvider.playlistTracks.addAll(providerTracks);
          musicProvider.notifyListeners();
        }
      }
      return;
    }

    _fetchingTrackDetails.add(deezerTrackId);
    try {
      final trackDetails = await _trackCacheService.getTrackDetails(deezerTrackId, auth.token!, _apiService);
      if (!mounted) return;
      
      if (trackDetails != null) {
        setState(() {
          if (index < _tracks.length && _tracks[index].trackId == playlistTrack.trackId) {
            _tracks[index] = PlaylistTrack(
              trackId: playlistTrack.trackId,
              name: playlistTrack.name,
              position: playlistTrack.position,
              points: playlistTrack.points,
              track: trackDetails,
            );
          }
        });
        
        final musicProvider = getProvider<MusicProvider>();
        final providerTracks = List<PlaylistTrack>.from(musicProvider.playlistTracks);
        final providerIndex = providerTracks.indexWhere((t) => t.trackId == playlistTrack.trackId);
        if (providerIndex != -1) {
          providerTracks[providerIndex] = PlaylistTrack(
            trackId: playlistTrack.trackId,
            name: playlistTrack.name,
            position: playlistTrack.position,
            points: playlistTrack.points, 
            track: trackDetails,
          );
          musicProvider.playlistTracks.clear();
          musicProvider.playlistTracks.addAll(providerTracks);
          musicProvider.notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('ERROR fetching track details for $deezerTrackId: $e', name: 'PlaylistDetailScreen');
      }
    } finally {
      if (mounted) _fetchingTrackDetails.remove(deezerTrackId);
    }
  }

  Future<void> _startBatchTrackDetailsFetch() async {
    if (!mounted) return;
    final tracksNeedingDetails = <int>[];
    
    for (int i = 0; i < _tracks.length; i++) {
      final track = _tracks[i].track;
      if (track?.deezerTrackId != null && 
          (track?.artist.isEmpty == true || track?.album.isEmpty == true)) {
        tracksNeedingDetails.add(i);
      }
    }
    
    for (int index in tracksNeedingDetails) {
      if (!mounted) break;
      final playlistTrack = _tracks[index];
      await _fetchTrackDetailsIfNeeded(playlistTrack, index);
      if (mounted && index < tracksNeedingDetails.length - 1) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  Future<void> _playPlaylist() async {
    if (_tracks.isEmpty) {
      showInfo('No tracks to play');
      return;
    }
    
    try {
      final playerService = getProvider<MusicPlayerService>();
      await playerService.setPlaylistAndPlay(
        playlist: _tracks,
        startIndex: 0,
        playlistId: widget.playlistId,
      );
      showInfo('Playing "${_playlist!.name}"');
    } catch (e) {
      showError('Failed to play playlist: $e');
    }
  }

  void _shufflePlaylist() async {
    if (_tracks.isEmpty) {
      showInfo('No tracks to shuffle');
      return;
    }
    
    try {
      final playerService = getProvider<MusicPlayerService>();
      final shuffledTracks = List<PlaylistTrack>.from(_tracks);
      shuffledTracks.shuffle();
      
      await playerService.setPlaylistAndPlay(
        playlist: shuffledTracks,
        startIndex: 0,
        playlistId: widget.playlistId,
      );
      playerService.toggleShuffle();
      
      showInfo('Shuffling "${_playlist!.name}"');
    } catch (e) {
      showError('Failed to shuffle playlist: $e');
    }
  }

  Future<void> _playTrackAt(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    
    try {
      final playerService = getProvider<MusicPlayerService>();
      
      if (playerService.playlistId == widget.playlistId && 
          playerService.playlist.length == _tracks.length) {
        await playerService.playTrackAtIndex(index);
      } else {
        await playerService.setPlaylistAndPlay(
          playlist: _tracks,
          startIndex: index,
          playlistId: widget.playlistId,
        );
      }
      
      final track = _tracks[index].track;
      if (track != null) {
        showSuccess('Playing "${track.name}"');
      }
    } catch (e) {
      showError('Failed to play track: $e');
    }
  }

  Future<void> _removeTrack(String trackId) async {
    if (!_isOwner) return;
    
    final confirmed = await showConfirmDialog('Remove Track', 'Remove this track from the playlist?');
    
    if (confirmed) {
      await runAsyncAction(
        () async {
          final musicProvider = getProvider<MusicProvider>();
          await musicProvider.removeTrackFromPlaylist(
            playlistId: widget.playlistId, 
            trackId: trackId, 
            token: auth.token!
          );
          await musicProvider.fetchPlaylistTracks(widget.playlistId, auth.token!);
          setState(() => _tracks = musicProvider.playlistTracks);
        },
        successMessage: 'Track removed from playlist',
        errorMessage: 'Failed to remove track',
      );
    }
  }

  void _onReorderTracks(int oldIndex, int newIndex) {
    if (!mounted) return;
    
    try {
      setState(() {
        if (newIndex > oldIndex) newIndex -= 1;
        final musicProvider = getProvider<MusicProvider>();
        final tracks = List<PlaylistTrack>.from(musicProvider.playlistTracks);
        final item = tracks.removeAt(oldIndex);
        tracks.insert(newIndex, item);
        
        for (int i = 0; i < tracks.length; i++) {
          tracks[i] = PlaylistTrack(
            trackId: tracks[i].trackId, 
            name: tracks[i].name, 
            position: i, 
            track: tracks[i].track
          );
        }
        _tracks = tracks;
      });
      _updateTrackOrder(oldIndex, newIndex);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        developer.log('ERROR reordering tracks: $e', name: 'PlaylistDetailScreen');
      }
      if (mounted) showError('Failed to reorder tracks: $e');
    }
  }

  Future<void> _updateTrackOrder(int oldIndex, int newIndex) async {
    try {
      final musicProvider = getProvider<MusicProvider>();
      await musicProvider.moveTrackInPlaylist(
        playlistId: widget.playlistId, 
        rangeStart: oldIndex, 
        insertBefore: newIndex,
        token: auth.token!,
      );
      
      if (mounted) {
        await musicProvider.fetchPlaylistTracks(widget.playlistId, auth.token!);
        setState(() => _tracks = musicProvider.playlistTracks);
        if (_votingProvider != null) _votingProvider!.initializeTrackPoints(_tracks);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        developer.log('ERROR updating track order: $e', name: 'PlaylistDetailScreen');
      }
      if (mounted) {
        showError('Failed to update track order: $e');
        await _loadData();
      }
    }
  }

  void _showSortOptions() {
    TrackSortBottomSheet.show(
      context, 
      currentSort: getProvider<MusicProvider>().currentSortOption,
      onSortChanged: (sortOption) {
        final musicProvider = getProvider<MusicProvider>();
        musicProvider.setSortOption(sortOption);
        final isCustomOrder = sortOption.field == TrackSortField.position;
        if (mounted) {
          showInfo(isCustomOrder ? 'Tracks restored to custom order' : 'Tracks sorted by ${sortOption.displayName}');
        }
      },
    );
  }

  void _openPlaylistSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistLicensingScreen(playlistId: widget.playlistId, playlistName: _playlist?.name ?? 'Playlist'),
      ),
    ).then((_) {
      if (mounted) _loadData();
    });
  }

  void _sharePlaylist() {
    if (_playlist != null && mounted) {
      navigateTo(AppRoutes.playlistSharing, arguments: _playlist);
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) _refreshPlaylistData();
    });
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  void _cancelPendingOperations() {
    for (final completer in _pendingOperations) {
      if (!completer.isCompleted) completer.complete();
    }
    _pendingOperations.clear();
    _fetchingTrackDetails.clear();
  }
}
