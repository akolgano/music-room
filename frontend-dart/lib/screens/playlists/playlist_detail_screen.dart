import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'playlist_licensing_screen.dart';
import '../../providers/music_provider.dart';
import '../../providers/dynamic_theme_provider.dart';
import '../../services/music_player_service.dart';
import '../../services/api_service.dart';
import '../../services/track_cache_service.dart';
import '../../services/websocket_service.dart';
import '../../core/service_locator.dart'; 
import '../../models/music_models.dart';
import '../../models/sort_models.dart';
import '../../core/theme_utils.dart';
import '../../core/constants.dart';
import '../base_screen.dart';
import '../../providers/voting_provider.dart'; 
import '../../widgets/playlist_detail_widgets.dart';
import '../../widgets/sort_button.dart';
import '../../widgets/track_sort_bottom_sheet.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});
  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends BaseScreen<PlaylistDetailScreen> {
  late final ApiService _apiService;
  late final TrackCacheService _trackCacheService;
  late final WebSocketService _webSocketService;
  final Set<String> _fetchingTrackDetails = {};
  final List<Completer> _pendingOperations = []; 
  Playlist? _playlist;
  List<PlaylistTrack> _tracks = [];
  bool _isOwner = false;
  VotingProvider? _votingProvider;
  Timer? _autoRefreshTimer;
  StreamSubscription<PlaylistUpdateMessage>? _playlistUpdateSubscription;

  @override
  String get screenTitle => _playlist?.name ?? 'Playlist Details';

  @override
  void initState() {
    super.initState();
    _apiService = getIt<ApiService>();
    _trackCacheService = getIt<TrackCacheService>();
    _webSocketService = getIt<WebSocketService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _votingProvider = getProvider<VotingProvider>(listen: false);
        _votingProvider?.setVotingPermission(true);
        _setupTrackReplacementNotifications();
        _setupWebSocketConnection();
        _loadData();
        _startAutoRefresh();
      }
    });
  }

  @override
  void dispose() {
    _cancelPendingOperations();
    _stopAutoRefresh();
    _playlistUpdateSubscription?.cancel();
    _webSocketService.disconnect();
    super.dispose();
  }

  @override
  List<Widget> get actions => [
    IconButton(
      icon: const Icon(Icons.how_to_vote),
      onPressed: () => navigateTo(AppRoutes.votingEvent),
      tooltip: 'Track Voting',
    ),
    if (_isOwner) IconButton(icon: const Icon(Icons.settings), onPressed: _openPlaylistSettings, tooltip: 'Playlist Settings'),
    IconButton(icon: const Icon(Icons.share), onPressed: _sharePlaylist, tooltip: 'Share Playlist'),
    IconButton(
      icon: Icon(_webSocketService.isConnected ? Icons.refresh : Icons.sync_problem), 
      onPressed: _refreshWithReconnect, 
      tooltip: _webSocketService.isConnected ? 'Refresh' : 'Refresh & Reconnect'
    ),
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
                PlaylistDetailWidgets.buildThemedPlaylistActions(
                  context, 
                  onPlayAll: _playPlaylist, 
                  onShuffle: _shufflePlaylist,
                  onAddRandomTrack: _isOwner ? _addRandomTrack : null,
                ),
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
                  _buildStyledIndicator(
                    Row(
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
      },
    );
  }

  Widget _buildTrackItemSafely(List<PlaylistTrack> tracks, int index, {bool needsKey = false}) {
    try {
      final playlistTrack = tracks[index];
      final key = needsKey ? ValueKey('reorder_${playlistTrack.trackId}_${playlistTrack.position}_$index') : null;
      final widget = _buildTrackItem(playlistTrack, index, key: key);
      return needsKey ? KeyedSubtree(key: key!, child: widget) : widget;
    } catch (e) {
      if (kDebugMode) {
        developer.log('ERROR building track item at index $index: $e', name: 'PlaylistDetailScreen');
      }
      final errorKey = needsKey ? ValueKey('error_$index') : null;
      return Container(
        key: errorKey,
        padding: const EdgeInsets.all(16),
        child: Text(
          'Error loading track at position $index', 
          style: const TextStyle(color: Colors.red)
        ),
      );
    }
  }

  Widget _buildTracksList(List<PlaylistTrack> tracks, TrackSortOption currentSort) {
    final canReorder = currentSort.field == TrackSortField.position && _isOwner;
    if (kDebugMode) {
      developer.log('Building tracks list: canReorder=$canReorder, tracks.length=${tracks.length}', name: 'PlaylistDetailScreen');
    }
    
    return canReorder
      ? ReorderableListView.builder(
          shrinkWrap: true, 
          physics: const NeverScrollableScrollPhysics(), 
          itemCount: tracks.length,
          onReorder: _onReorderTracks,
          itemBuilder: (context, index) => _buildTrackItemSafely(tracks, index, needsKey: true),
        )
      : ListView.builder(
          shrinkWrap: true, 
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tracks.length,
          itemBuilder: (context, index) => _buildTrackItemSafely(tracks, index),
        );
  }

  Widget _buildTrackItem(PlaylistTrack playlistTrack, int index, {Key? key}) {
    final track = playlistTrack.track;
    
    if (_needsTrackDetailsFetch(track) && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchTrackDetailsIfNeeded(playlistTrack, index);
      });
    }

    if (track?.deezerTrackId != null && 
        _fetchingTrackDetails.contains(track!.deezerTrackId!) &&
        _trackHasMissingDetails(track)) {
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


  void _setupTrackReplacementNotifications() {
    final playerService = getProvider<MusicPlayerService>(listen: false);
    playerService.setTrackReplacedCallback((originalTrack, replacementTrack) {
      if (mounted) {
        showSuccess('Replaced unplayable track:\n"$originalTrack"\nwith\n"$replacementTrack"');
        _loadData();
      }
    });
  }

  void _setupWebSocketConnection() {
    _playlistUpdateSubscription = _webSocketService.playlistUpdateStream.listen(
      (updateMessage) {
        if (kDebugMode) {
          developer.log('Received WebSocket playlist update: ${updateMessage.tracks.length} tracks', 
              name: 'PlaylistDetailScreen');
        }
        
        if (updateMessage.playlistId == widget.playlistId && mounted) {
          _handlePlaylistUpdate(updateMessage.tracks);
        }
      },
      onError: (error) {
        if (kDebugMode) {
          developer.log('WebSocket error: $error', name: 'PlaylistDetailScreen');
        }
      },
    );

    if (auth.token != null) {
      _webSocketService.connectToPlaylist(widget.playlistId, auth.token!);
    }
  }

  Future<void> _refreshTracksFromProvider() async {
    final musicProvider = _getMountedProvider<MusicProvider>();
    if (musicProvider == null) return;
    await musicProvider.fetchPlaylistTracks(widget.playlistId, auth.token!);
    setState(() => _tracks = musicProvider.playlistTracks);
    _initializeVotingIfNeeded();
  }

  bool _needsTrackDetailsFetch(Track? track) {
    return track?.deezerTrackId != null && 
           _trackHasMissingDetails(track) &&
           !_fetchingTrackDetails.contains(track!.deezerTrackId!);
  }

  void _logError(String message, dynamic error) {
    if (kDebugMode) {
      developer.log('ERROR $message: $error', name: 'PlaylistDetailScreen');
    }
  }

  T? _getMountedProvider<T>() {
    return mounted ? getProvider<T>(listen: false) : null;
  }

  bool _trackHasMissingDetails(Track? track) {
    return track?.artist.isEmpty == true || track?.album.isEmpty == true;
  }

  Widget _buildStyledIndicator(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: child,
    );
  }

  void _initializeVotingIfNeeded() {
    if (_votingProvider != null) {
      _votingProvider!.initializeTrackPoints(_tracks);
    }
  }

  bool _shouldSkipTrackDetailsFetch(String? deezerTrackId, Track? track) {
    return deezerTrackId == null || 
           _fetchingTrackDetails.contains(deezerTrackId) || 
           !mounted ||
           (track != null && !_trackHasMissingDetails(track));
  }

  void _handlePlaylistUpdate(List<PlaylistTrack> updatedTracks) {
    final musicProvider = _getMountedProvider<MusicProvider>();
    if (musicProvider == null) return;
    
    setState(() {
      _tracks = updatedTracks;
    });
    
    musicProvider.updatePlaylistTracks(updatedTracks);
    
    _initializeVotingIfNeeded();
    
    if (kDebugMode) {
      developer.log('Updated playlist tracks via WebSocket: ${_tracks.length} tracks', 
          name: 'PlaylistDetailScreen');
    }
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
          
          await _refreshTracksFromProvider();
          
          if (_votingProvider != null) {
            _votingProvider!.clearVotingData();
            _votingProvider!.setVotingPermission(true);
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

  Future<void> _refreshWithReconnect() async {
    if (!_webSocketService.isConnected && auth.token != null) {
      await _webSocketService.forceReconnect();
    }
    await _loadData();
  }

  Future<void> _refreshPlaylistData() async {
    try {
      await _refreshTracksFromProvider();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error refreshing playlist data: $e', name: 'PlaylistDetailScreen');
      }
    }
  }

  Future<void> _fetchTrackDetailsIfNeeded(PlaylistTrack playlistTrack, int index) async {
    final track = playlistTrack.track;
    final deezerTrackId = track?.deezerTrackId;
    final trackId = playlistTrack.trackId;
    
    if (_shouldSkipTrackDetailsFetch(deezerTrackId, track)) {
      return;
    }

    final nonNullDeezerTrackId = deezerTrackId!;
    _fetchingTrackDetails.add(nonNullDeezerTrackId);
    
    try {
      final trackDetails = await _trackCacheService.getTrackDetails(nonNullDeezerTrackId, auth.token!, _apiService);
      if (!mounted) return;
      
      if (trackDetails != null) {
        _updateTrackDetails(trackId, trackDetails);
      }
    } catch (e) {
      _logError('fetching track details for $deezerTrackId', e);
    } finally {
      _fetchingTrackDetails.remove(nonNullDeezerTrackId);
    }
  }

  void _updateTrackDetails(String trackId, Track trackDetails) {
    final musicProvider = _getMountedProvider<MusicProvider>();
    if (musicProvider == null) return;
    
    final updatedTracks = _tracks.map((playlistTrack) =>
      playlistTrack.trackId == trackId
        ? PlaylistTrack(
            trackId: playlistTrack.trackId,
            name: playlistTrack.name,
            position: playlistTrack.position,
            points: playlistTrack.points,
            track: trackDetails,
          )
        : playlistTrack
    ).toList();
    
    setState(() => _tracks = updatedTracks);
    musicProvider.updateTrackInPlaylist(trackId, trackDetails);
  }

  Future<void> _startBatchTrackDetailsFetch() async {
    if (!mounted) return;
    
    final tracksNeedingDetails = <PlaylistTrack>[];
    
    for (int i = 0; i < _tracks.length; i++) {
      final track = _tracks[i].track;
      if (_needsTrackDetailsFetch(track)) {
        tracksNeedingDetails.add(_tracks[i]);
      }
    }
    
    if (tracksNeedingDetails.isEmpty) return;
    
    if (kDebugMode) {
      developer.log('Starting parallel fetch for ${tracksNeedingDetails.length} tracks', name: 'PlaylistDetailScreen');
    }
    
    final futures = tracksNeedingDetails.map((playlistTrack) {
      return _fetchTrackDetailsIfNeeded(playlistTrack, -1); 
    }).toList();
    
    try {
      await Future.wait(futures);
      if (kDebugMode) {
        developer.log('Completed parallel fetch for ${tracksNeedingDetails.length} tracks', name: 'PlaylistDetailScreen');
      }
    } catch (e) {
      _logError('in batch track fetch', e);
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
        authToken: auth.token,
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
        authToken: auth.token,
      );
      playerService.toggleShuffle();
      
      showInfo('Shuffling "${_playlist!.name}"');
    } catch (e) {
      showError('Failed to shuffle playlist: $e');
    }
  }

  Future<void> _addRandomTrack() async {
    if (auth.token == null) {
      showError('Authentication required');
      return;
    }

    await runAsyncAction(
      () async {
        final musicProvider = getProvider<MusicProvider>();
        final result = await musicProvider.addRandomTrackToPlaylist(widget.playlistId, auth.token!);
        
        if (result.success) {
          showInfo('Random track added successfully!');
          await _refreshTracksFromProvider();
        } else {
          showError(result.message);
        }
      },
      errorMessage: 'Failed to add random track',
    );
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
          authToken: auth.token,
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
          await _refreshTracksFromProvider();
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
    } catch (e) {
      _logError('reordering tracks', e);
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
        await _refreshTracksFromProvider();
      }
    } catch (e) {
      _logError('updating track order', e);
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
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        final trackCacheService = getIt<TrackCacheService>();
        final cacheStats = trackCacheService.getCacheStats();
        final hasRetryingTracks = cacheStats['tracks_retrying'] > 0;
        
        if (hasRetryingTracks) {
          _refreshPlaylistData();
        } else if (!_webSocketService.isConnected && timer.tick % 3 == 0) {
          _refreshPlaylistData();
        } else {
          if (mounted) setState(() {});
        }
      }
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
