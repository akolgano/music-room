import 'dart:async';
import 'dart:math';
import '../../core/navigation_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/music_providers.dart';
import '../../providers/theme_providers.dart';
import '../../services/player_services.dart';
import '../../services/api_services.dart';
import '../../services/cache_services.dart';
import '../../services/websocket_services.dart';
import '../../services/playlists_services.dart';
import '../../core/locator_core.dart'; 
import '../../models/music_models.dart';
import '../../models/sort_models.dart';
import '../../core/theme_core.dart';
import '../../core/provider_core.dart';
import '../../core/logging_core.dart';
import '../../core/responsive_core.dart';
import '../base_screens.dart';
import '../../providers/voting_providers.dart'; 
import '../../widgets/detail_widgets.dart';
import '../../widgets/sort_widgets.dart';
import '../../widgets/votes_widgets.dart';
import '../../widgets/app_widgets.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});
  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends BaseScreen<PlaylistDetailScreen> with UserActionLoggingMixin {
  late final ApiService _apiService;
  late final TrackCacheService _trackCacheService;
  late final WebSocketService _webSocketService;
  late final PlaylistVotingService _votingService;
  late final PlaylistTrackService _trackService;
  late final PlaylistTimers _timers;
  final List<Completer> _pendingOperations = []; 
  Playlist? _playlist;
  List<PlaylistTrack> _tracks = [];
  bool _isOwner = false;
  bool _canEditPlaylist = false;
  VotingProvider? _votingProvider;
  StreamSubscription<PlaylistUpdateMessage>? _playlistUpdateSubscription;
  
  final Map<String, String> _trackIdToPlaylistTrackId = {};
  
  bool _isVotingMode = false;

  @override
  String get screenTitle => _playlist?.name ?? 'Playlist Details';

  @override
  void initState() {
    super.initState();
    _apiService = getIt<ApiService>();
    _trackCacheService = getIt<TrackCacheService>();
    _webSocketService = getIt<WebSocketService>();
    _votingService = PlaylistVotingService(playlistId: widget.playlistId);
    _trackService = PlaylistTrackService(apiService: _apiService, trackCacheService: _trackCacheService);
    _timers = PlaylistTimers(
      onRefreshNeeded: _refreshPlaylistData,
      onValidationNeeded: _validateTrackCounts,
      onStateUpdate: () => mounted ? setState(() {}) : null,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _votingProvider = getProvider<VotingProvider>(listen: false);
        _votingProvider?.setVotingPermission(true);
        _setupWebSocketConnection();
        _loadData();
        _timers.startAutoRefresh();
        _timers.startTrackCountValidation();
      }
    });
  }

  @override
  void dispose() {
    _cancelPendingOperations();
    _timers.dispose();
    _playlistUpdateSubscription?.cancel();
    _webSocketService.disconnect();
    super.dispose();
  }

  @override
  List<Widget> get actions => [
    if (_playlist != null && _playlist!.isEvent) buildLoggingIconButton(
      icon: Icon(_isVotingMode ? Icons.edit : Icons.how_to_vote),
      onPressed: () {
        if (_playlist == null || !_playlist!.isEvent) return;
        logButtonClick('toggle_voting_mode', metadata: {
          'current_mode': _isVotingMode ? 'voting' : 'edit',
          'switching_to': _isVotingMode ? 'edit' : 'voting',
          'playlist_id': widget.playlistId,
        });
        setState(() => _isVotingMode = !_isVotingMode);
      },
      buttonName: 'toggle_voting_mode',
    ),
    if (_canEditPlaylist) buildLoggingIconButton(
      icon: const Icon(Icons.add), 
      onPressed: () {
        logButtonClick('add_songs_to_playlist', metadata: {'playlist_id': widget.playlistId});
        _addSongs();
      },
      buttonName: 'add_songs_button',
    ),
    if (_isOwner) buildLoggingIconButton(
      icon: const Icon(Icons.edit), 
      onPressed: () {
        logButtonClick('edit_playlist', metadata: {'playlist_id': widget.playlistId});
        _openPlaylistEditor();
      },
      buttonName: 'edit_playlist_button',
    ),
    if (_isOwner && _playlist != null && !_playlist!.isPublic) buildLoggingIconButton(
      icon: const Icon(Icons.share), 
      onPressed: () {
        logButtonClick('share_playlist', metadata: {'playlist_id': widget.playlistId});
        _sharePlaylist();
      },
      buttonName: 'share_playlist_button',
    ),
    buildLoggingIconButton(
      icon: Icon(_webSocketService.isConnected ? Icons.refresh : Icons.sync_problem), 
      onPressed: () {
        logButtonClick('refresh_playlist', metadata: {
          'playlist_id': widget.playlistId,
          'websocket_connected': _webSocketService.isConnected,
        });
        _refreshWithReconnect();
      },
      buttonName: 'refresh_playlist_button',
    ),
    if (_isOwner) buildLoggingIconButton(
      icon: const Icon(Icons.delete, color: Colors.red), 
      onPressed: () {
        logButtonClick('delete_playlist', metadata: {'playlist_id': widget.playlistId});
        _deletePlaylist();
      },
      buttonName: 'delete_playlist_button',
    ),
  ];

  @override
  Widget? get floatingActionButton => null;

  @override
  Widget buildContent() {
    if (_playlist == null) return buildLoadingState(message: 'Loading playlist...');

    return Consumer<DynamicThemeProvider>(
      builder: (context, themeProvider, _) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            vertical: MusicAppResponsive.getSpacing(context, tiny: 4.0, small: 5.0, medium: 6.0),
            horizontal: 0
          ),
          child: Column(
            children: [
              PlaylistDetailWidgets.buildThemedPlaylistHeader(context, _playlist!),
              SizedBox(height: MusicAppResponsive.getSpacing(context, tiny: 4.0, small: 5.0, medium: 6.0)),
              if (_isVotingMode) ...PlaylistVotingWidgets.buildVotingModeHeader(
                context: context,
                isOwner: _isOwner,
                isPublicVoting: _votingService.isPublicVoting,
                votingLicenseType: _votingService.votingLicenseType,
                votingStartTime: _votingService.votingStartTime,
                votingEndTime: _votingService.votingEndTime,
                votingInfo: _votingService.votingInfo,
                onPublicVotingChanged: (value) => setState(() => _votingService.setPublicVoting(value)),
                onLicenseTypeChanged: (value) => setState(() => _votingService.setVotingLicenseType(value)),
                onApplyVotingSettings: _applyVotingSettings,
                onSelectVotingDateTime: _selectVotingDateTime,
                playlistId: widget.playlistId,
                latitude: _votingService.latitude,
                longitude: _votingService.longitude,
                onDetectLocation: _isOwner ? _detectCurrentLocation : null,
                onClearLocation: _isOwner ? _clearLocation : null,
              ),
              PlaylistDetailWidgets.buildThemedPlaylistStats(context, _tracks, isEvent: _playlist?.isEvent ?? false),
              SizedBox(height: MusicAppResponsive.getSpacing(context, tiny: 4.0, small: 5.0, medium: 6.0)),
              KeyedSubtree(
                key: ValueKey('playlist_actions_${_tracks.length}_${_tracks.hashCode}'),
                child: PlaylistDetailWidgets.buildThemedPlaylistActions(
                  context, 
                  onPlayAll: _tracks.isNotEmpty ? _playPlaylist : () {}, 
                  onPlayRandom: _tracks.isNotEmpty ? _playRandomTrack : () {},
                  onAddRandomTrack: _canEditPlaylist ? _addRandomTrack : null,
                  hasTracks: _tracks.isNotEmpty,
                ),
              ),
              SizedBox(height: MusicAppResponsive.getSpacing(context, tiny: 4.0, small: 5.0, medium: 6.0)),
              _isVotingMode ? PlaylistVotingWidgets.buildVotingTracksSection(
                context: context,
                tracks: _tracks,
                playlistId: widget.playlistId,
                onLoadData: () => _loadData(),
                onSuggestTrackForVoting: _suggestTrackForVoting,
                votingInfo: _votingService.votingInfo,
                playlistOwnerId: _playlist?.creator,
                isEvent: _playlist?.isEvent ?? false,
              ) : _buildTracksSection(),
            ],
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
          margin: EdgeInsets.zero,
          color: Theme.of(context).colorScheme.surface,
          elevation: 4,
          shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: 6, 
              horizontal: 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.queue_music, color: Theme.of(context).colorScheme.primary, size: 20),
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
                if (currentSort.field != TrackSortField.position && 
                    (currentSort.field != TrackSortField.points || _playlist?.isEvent == true)) ...[
                  const SizedBox(height: 4),
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
                          },
                          child: const Icon(Icons.close, size: 14, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                if (sortedTracks.isEmpty) 
                  PlaylistDetailWidgets.buildEmptyTracksState(
                    isOwner: _canEditPlaylist,
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
      AppLogger.error('ERROR building track item at index $index: ${e.toString()}', null, null, 'PlaylistDetailScreen');
      final errorKey = needsKey ? ValueKey('error_$index') : null;
      return Container(
        key: errorKey,
        padding: const EdgeInsets.all(8),
        child: Text(
          'Error loading track at position $index', 
          style: const TextStyle(color: Colors.red)
        ),
      );
    }
  }

  Widget _buildTracksList(List<PlaylistTrack> tracks, TrackSortOption currentSort) {
    return Consumer<MusicPlayerService>(
      builder: (context, playerService, _) {
        return ListView.builder(
          shrinkWrap: true, 
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tracks.length,
          itemBuilder: (context, index) => _buildTrackItemSafely(tracks, index),
        );
      },
    );
  }

  Widget _buildTrackItem(PlaylistTrack playlistTrack, int index, {Key? key}) {
    final track = playlistTrack.track;
    
    if (_trackService.needsTrackDetailsFetch(track) && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchTrackDetailsIfNeeded(playlistTrack, index);
      });
    }

    if (track?.deezerTrackId != null && 
        _trackService.fetchingTrackDetails.contains(track!.deezerTrackId!) &&
        _trackHasMissingDetails(track)) {
      return PlaylistDetailWidgets.buildErrorTrackItem(key, playlistTrack, index, isLoading: true);
    }

    final musicProvider = getProvider<MusicProvider>();
    final sortedTracks = musicProvider.sortedPlaylistTracks;
    
    final playerService = getProvider<MusicPlayerService>(listen: false);
    final isCurrentlyPlaying = playerService.isPlaying && playerService.playlistId == widget.playlistId;
    
    final bool canModifyTracks = (_playlist?.isEvent ?? false) ? _isOwner : _canEditPlaylist;
    
    // Disable deletion of ANY track when music is playing in this playlist
    final bool canRemoveTrack = canModifyTracks && 
        !((_playlist?.isEvent ?? false) && playlistTrack.points > 0) &&
        !isCurrentlyPlaying;
    
    final bool canReorderTracks = canModifyTracks && 
        !isCurrentlyPlaying && 
        musicProvider.currentSortOption.field == TrackSortField.position;
    
    return PlaylistDetailWidgets.buildTrackItem(
      context: context,
      playlistTrack: playlistTrack,
      index: index,
      isOwner: _canEditPlaylist,
      onPlay: () => _playTrackAt(index),
      onRemove: canRemoveTrack ? () => _removeTrack(playlistTrack.trackId) : null,
      onMoveUp: canReorderTracks && index > 0 ? () => _moveTrackWithSortCheck(index, index - 1) : null,
      onMoveDown: canReorderTracks && index < sortedTracks.length - 1 ? () => _moveTrackWithSortCheck(index, index + 1) : null,
      canReorder: canReorderTracks,
      playlistId: widget.playlistId,
      playlistOwnerId: _playlist?.creator,
      isEvent: _playlist?.isEvent ?? false,
      isVotingMode: _isVotingMode,
      onVoteSuccess: _isVotingMode ? () {
        setState(() => _isVotingMode = false);
      } : null,
      key: key,
    );
  }

  void _setupWebSocketConnection() {
    _playlistUpdateSubscription = _webSocketService.playlistUpdateStream.listen(
      (updateMessage) {
        AppLogger.debug('Received WebSocket playlist update: ${updateMessage.tracks.length} tracks, action: ${updateMessage.action}', 'PlaylistDetailScreen');
        
        if (updateMessage.playlistId == widget.playlistId && mounted) {
          _handlePlaylistUpdateMessage(updateMessage);
        }
      },
      onError: (error) {
        AppLogger.error('WebSocket error', error, null, 'PlaylistDetailScreen');
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
    _updateTrackIdMapping(_tracks);
    _initializeVotingIfNeeded();
    
    final playerService = _getMountedProvider<MusicPlayerService>();
    if (playerService != null && playerService.playlistId == widget.playlistId) {
      playerService.updatePlaylist(_tracks);
    }
  }

  Future<void> _forceFullRefresh() async {
    try {
      AppLogger.debug('Force refreshing playlist data after WebSocket update', 'PlaylistDetailScreen');
      
      final musicProvider = _getMountedProvider<MusicProvider>();
      if (musicProvider == null || auth.token == null) return;
      
      final response = await _apiService.getPlaylistTracks(widget.playlistId, auth.token!);
      
      if (!mounted) return;
      
      final updatedTracks = response.tracks;
      
      AppLogger.debug('Received ${updatedTracks.length} tracks from API with new backend structure', 'PlaylistDetailScreen');
      
      setState(() {
        _tracks = updatedTracks;
        _updateTrackIdMapping(_tracks);
      });
      
      musicProvider.setPlaylistTracks(updatedTracks);
      
      final playerService = _getMountedProvider<MusicPlayerService>();
      if (playerService != null && playerService.playlistId == widget.playlistId) {
        AppLogger.debug('Clearing and updating player service with fresh data', 'PlaylistDetailScreen');
        playerService.clearFailedTracks();
        playerService.updatePlaylist(updatedTracks);
      }
      
      _initializeVotingIfNeeded();
      
      final tracksWithoutFullDetails = updatedTracks.where((pt) {
        final t = pt.track;
        return t == null || 
               t.previewUrl == null || 
               t.imageUrl == null ||
               t.artist.isEmpty ||
               t.album.isEmpty;
      }).toList();
      
      if (tracksWithoutFullDetails.isNotEmpty) {
        AppLogger.debug('${tracksWithoutFullDetails.length} tracks need additional details', 'PlaylistDetailScreen');
        for (final pt in tracksWithoutFullDetails) {
          if (pt.track?.deezerTrackId != null) {
            _fetchTrackDetailsIfNeeded(pt, _tracks.indexOf(pt));
          }
        }
      }
      
      AppLogger.debug('Force refresh completed successfully', 'PlaylistDetailScreen');
      
    } catch (e) {
      AppLogger.error('Failed to force refresh tracks', e, null, 'PlaylistDetailScreen');
      _loadData();
    }
  }


  void _logError(String message, dynamic error) {
    AppLogger.error('ERROR $message', error, null, 'PlaylistDetailScreen');
  }

  T? _getMountedProvider<T>() {
    return mounted ? getProvider<T>(listen: false) : null;
  }

  bool _trackHasMissingDetails(Track? track) {
    return track?.artist.isEmpty == true || track?.album.isEmpty == true;
  }

  Widget _buildStyledIndicator(Widget child) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MusicAppResponsive.isSmallScreen(context) ? 2 : 4, 
        vertical: 2,
      ),
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
      _votingProvider!.refreshVotingData(_tracks);
    }
  }

  void _updateTrackIdMapping(List<PlaylistTrack> webSocketTracks) {
    for (final playlistTrack in webSocketTracks) {
      final track = playlistTrack.track;
      if (track != null) {
        _trackIdToPlaylistTrackId[track.id] = playlistTrack.trackId;
        AppLogger.debug('Mapped Track.id ${track.id} -> PlaylistTrack.id ${playlistTrack.trackId}', 'PlaylistDetailScreen');
      }
    }
  }

  void _handlePlaylistUpdateMessage(PlaylistUpdateMessage updateMessage) {
    if (!mounted) return;
    AppLogger.debug('WebSocket update received - forcing refresh', 'PlaylistDetailScreen');
    _forceFullRefresh();
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
            _canEditPlaylist = _playlist!.canEdit(auth.username);
            if (!_playlist!.isEvent && _isVotingMode) {
              _isVotingMode = false;
            }
          });
          
          if (_playlist!.isEvent) {
            final musicProvider = getProvider<MusicProvider>();
            if (musicProvider.currentSortOption.field == TrackSortField.position) {
              musicProvider.setSortOption(
                const TrackSortOption(
                  field: TrackSortField.points,
                  order: SortOrder.descending,
                  displayName: 'Most Votes',
                  icon: Icons.how_to_vote,
                ),
              );
            }
            _requestLocationPermissionForVoting();
          }
          
          await _refreshTracksFromProvider();
          
          if (_votingProvider != null) {
            _votingProvider!.clearVotingData();
            _votingProvider!.setVotingPermission(true);
            _votingProvider!.setHasUserVotedForPlaylist(false);
            _votingProvider!.initializeTrackPoints(_tracks);
          }
          
          await _votingService.loadVotingSettings(auth.token!, isOwner: _isOwner);
          
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
    if (!_webSocketService.isConnected && auth.token != null) await _webSocketService.forceReconnect();
    await _loadData();
  }

  Future<void> _refreshPlaylistData() async {
    try { await _refreshTracksFromProvider(); } 
    catch (e) { AppLogger.error('Error refreshing playlist data', e, null, 'PlaylistDetailScreen'); }
  }

  Future<void> _fetchTrackDetailsIfNeeded(PlaylistTrack playlistTrack, int index) async {
    final trackDetails = await _trackService.fetchTrackDetailsIfNeeded(playlistTrack, auth.token!);
    if (trackDetails != null && mounted) _updateTrackDetails(playlistTrack.trackId, trackDetails);
  }

  Future<Track?> _fetchTrackDetailsForPlay(PlaylistTrack playlistTrack) async {
    try {
      final trackIdToFetch = playlistTrack.track?.deezerTrackId ?? 
        (playlistTrack.trackId.startsWith('deezer_') ? playlistTrack.trackId.replaceFirst('deezer_', '') : playlistTrack.trackId);
      return await _trackCacheService.getTrackDetails(trackIdToFetch, auth.token!, getIt<ApiService>());
    } catch (e) {
      AppLogger.error('Failed to fetch track details', e, null, 'PlaylistDetailScreen');
      return null;
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
    final tracksNeedingDetails = _tracks.where((t) => _trackService.needsTrackDetailsFetch(t.track)).toList();
    _trackService.batchFetchTrackDetailsProgressive(
      tracksNeedingDetails, auth.token!,
      onTrackLoaded: (playlistTrack, trackDetails) {
        if (mounted && trackDetails != null) _updateTrackDetails(playlistTrack.trackId, trackDetails);
      },
    );
  }

  Future<void> _playPlaylist() async {
    final sortedTracks = getProvider<MusicProvider>().sortedPlaylistTracks;
    if (sortedTracks.isEmpty) return;
    try {
      await _ensureTracksHaveDetails(sortedTracks);
      final playerService = getProvider<MusicPlayerService>();
      playerService.clearFailedTracks();
      await playerService.setPlaylistAndPlay(
        playlist: sortedTracks, startIndex: 0,
        playlistId: widget.playlistId, authToken: auth.token,
      );
    } catch (e) {
      AppLogger.error('Failed to play playlist', e, null, 'PlaylistDetailScreen');
      showError('Failed to play playlist');
    }
  }

  Future<void> _playRandomTrack() async {
    final sortedTracks = getProvider<MusicProvider>().sortedPlaylistTracks;
    if (sortedTracks.isEmpty) { showError('No tracks available to play'); return; }
    try {
      final randomIndex = Random().nextInt(sortedTracks.length);
      await _ensureTracksHaveDetails(sortedTracks);
      final playerService = getProvider<MusicPlayerService>();
      playerService.clearFailedTracks();
      await playerService.setPlaylistAndPlay(
        playlist: sortedTracks, startIndex: randomIndex,
        playlistId: widget.playlistId, authToken: auth.token,
      );
    } catch (e) {
      AppLogger.error('Failed to play random track', e, null, 'PlaylistDetailScreen');
      showError('Failed to play random track');
    }
  }
  
  Future<void> _ensureTracksHaveDetails(List<PlaylistTrack> tracks) async {
    final needsDetails = tracks.where((pt) => pt.track == null || pt.track!.deezerTrackId == null || pt.track!.previewUrl == null).toList();
    for (final pt in needsDetails) {
      final details = await _fetchTrackDetailsForPlay(pt);
      if (details != null) {
        final index = tracks.indexOf(pt);
        if (index >= 0) {
          tracks[index] = PlaylistTrack(
            trackId: pt.trackId, name: pt.name,
            position: pt.position, points: pt.points, track: details,
          );
        }
      }
    }
  }

  Future<void> _addRandomTrack() async {
    if (auth.token == null) return;
    await runAsyncAction(
      () async {
        final result = await getProvider<MusicProvider>().addRandomTrackToPlaylist(widget.playlistId, auth.token!);
        if (result.success) await _refreshTracksFromProvider();
      },
      errorMessage: 'Failed to add random track',
    );
  }

  Future<void> _playTrackAt(int index) async {
    final sortedTracks = getProvider<MusicProvider>().sortedPlaylistTracks;
    if (index < 0 || index >= sortedTracks.length) return;
    try {
      final playlistTrack = sortedTracks[index];
      var track = playlistTrack.track;
      if (track == null || track.previewUrl == null || track.deezerTrackId == null || track.artist.isEmpty || track.album.isEmpty) {
        final trackDetails = await _fetchTrackDetailsForPlay(playlistTrack);
        if (trackDetails == null) { showError('Unable to play track'); return; }
        track = trackDetails;
        sortedTracks[index] = PlaylistTrack(
          trackId: playlistTrack.trackId, name: playlistTrack.name,
          position: playlistTrack.position, points: playlistTrack.points, track: trackDetails,
        );
        _updateTrackDetails(playlistTrack.trackId, trackDetails);
      }
      await getProvider<MusicPlayerService>().setPlaylistAndPlay(
        playlist: sortedTracks, startIndex: index,
        playlistId: widget.playlistId, authToken: auth.token,
      );
    } catch (e) {
      AppLogger.error('Failed to play track', e, null, 'PlaylistDetailScreen');
      showError('Failed to play track');
    }
  }

  Future<void> _removeTrack(String trackId) async {
    final bool canModifyTracks = (_playlist?.isEvent ?? false) ? _isOwner : _canEditPlaylist;
    if (!canModifyTracks) return;
    
    if (_playlist?.isEvent ?? false) {
      final track = _tracks.firstWhere((t) => t.trackId == trackId, 
          orElse: () => PlaylistTrack(trackId: '', name: '', position: 0, points: 0));
      if (track.points > 0) {
        showError('Cannot remove tracks with votes in events');
        return;
      }
    }
    
    final confirmed = await showConfirmDialog('Remove Track', 'Remove this track from the playlist?');
    if (!confirmed) return;
    await runAsyncAction(
      () async {
        final playlistTrackId = _trackIdToPlaylistTrackId[trackId] ?? trackId;
        await getProvider<MusicProvider>().removeTrackFromPlaylist(
          playlistId: widget.playlistId, trackId: playlistTrackId, token: auth.token!
        );
        await _refreshTracksFromProvider();
      },
      successMessage: 'Track removed', errorMessage: 'Failed to remove track',
    );
  }

  Future<void> _moveTrackWithSortCheck(int fromIndex, int toIndex) async {
    final bool canModifyTracks = (_playlist?.isEvent ?? false) ? _isOwner : _canEditPlaylist;
    if (!canModifyTracks) return;
    
    final playerService = getProvider<MusicPlayerService>(listen: false);
    if (playerService.isPlaying && playerService.playlistId == widget.playlistId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cannot reorder tracks while music is playing. Please stop playback first.'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    final musicProvider = getProvider<MusicProvider>();
    final currentSort = musicProvider.currentSortOption;
    
    if (currentSort.field != TrackSortField.position) {
      musicProvider.resetToCustomOrder();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Switched to Custom Order to enable track reordering'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
      
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    await _moveTrack(fromIndex, toIndex);
  }

  Future<void> _moveTrack(int fromIndex, int toIndex) async {
    if (!mounted || fromIndex == toIndex || fromIndex < 0 || toIndex < 0) return;
    
    final playerService = getProvider<MusicPlayerService>(listen: false);
    if (playerService.isPlaying && playerService.playlistId == widget.playlistId) {
      AppLogger.warning('Attempted to move track while music is playing', 'PlaylistDetailScreen');
      return;
    }
    
    final sortedTracks = getProvider<MusicProvider>().sortedPlaylistTracks;
    if (fromIndex >= sortedTracks.length || toIndex >= sortedTracks.length) return;
    try {
      setState(() {
        final tracks = List<PlaylistTrack>.from(sortedTracks);
        tracks.insert(toIndex, tracks.removeAt(fromIndex));
        for (int i = 0; i < tracks.length; i++) {
          tracks[i] = PlaylistTrack(
            trackId: tracks[i].trackId, name: tracks[i].name, position: i,
            track: tracks[i].track, points: tracks[i].points,
          );
        }
        _tracks = tracks;
      });
      await _updateTrackOrder(fromIndex, toIndex);
    } catch (e) { _logError('moving track', e); }
  }

  Future<void> _updateTrackOrder(int oldIndex, int newIndex) async {
    try {
      await getProvider<MusicProvider>().moveTrackInPlaylist(
        playlistId: widget.playlistId, rangeStart: oldIndex,
        insertBefore: newIndex > oldIndex ? newIndex + 1 : newIndex,
        token: auth.token!,
      );
      if (mounted) await _refreshTracksFromProvider();
    } catch (e) {
      _logError('updating track order', e);
      if (mounted) await _loadData();
    }
  }

  void _showSortOptions() => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => TrackSortBottomSheet(
      currentSort: getProvider<MusicProvider>().currentSortOption,
      onSortChanged: (sortOption) => getProvider<MusicProvider>().setSortOption(sortOption),
      isEvent: _playlist?.isEvent ?? false,
    ),
  );

  void _openPlaylistEditor() => Navigator.pushNamed(context, AppRoutes.playlistEditor, arguments: widget.playlistId)
    .then((_) { if (mounted) _loadData(); });

  Future<void> _sharePlaylist() async {
    if (_playlist != null && mounted) {
      final result = await Navigator.pushNamed(context, AppRoutes.playlistSharing, arguments: _playlist);
      if (result is Playlist && mounted) setState(() => _playlist = result);
    }
  }

  Future<void> _addSongs() async {
    final result = await Navigator.pushNamed(context, AppRoutes.trackSearch, arguments: widget.playlistId);
    if (result == true && mounted) await _loadData();
  }

  void _validateTrackCounts() {
    final musicProvider = _getMountedProvider<MusicProvider>();
    if (musicProvider == null) return;
    if (_tracks.length != musicProvider.sortedPlaylistTracks.length) _loadData();
  }

  void _cancelPendingOperations() {
    for (final c in _pendingOperations) {
      if (!c.isCompleted) c.complete();
    }
    _pendingOperations.clear();
    _trackService.clearFetchingState();
    _trackIdToPlaylistTrackId.clear();
  }

  Future<void> _applyVotingSettings() async {
    if (auth.token == null) {
      AppWidgets.showSnackBar(context, 'Authentication required', backgroundColor: Colors.red);
      return;
    }
    try {
      await _votingService.applyVotingSettings(auth.token!);
      if (mounted) AppWidgets.showSnackBar(context, 'Voting settings updated!', backgroundColor: Colors.green);
    } catch (e) {
      if (mounted) AppWidgets.showSnackBar(context, 'Failed to update voting settings', backgroundColor: Colors.red);
    }
    setState(() {});
  }

  Future<void> _selectVotingDateTime(bool isStartTime) async {
    final result = await _votingService.selectVotingDateTime(context, isStartTime);
    if (result != null && mounted) setState(() {});
  }

  Future<void> _suggestTrackForVoting() async {
    final selectedTrack = await Navigator.pushNamed(context, AppRoutes.trackSearch, arguments: {'selectMode': true}) as Track?;
    if (selectedTrack != null) {
      try {
        await getProvider<MusicProvider>().addTrackObjectToPlaylist(widget.playlistId, selectedTrack, auth.token!);
        await _loadData();
      } catch (e) { AppLogger.error('Failed to suggest track', e, null, 'PlaylistDetailScreen'); }
    }
  }

  Future<void> _deletePlaylist() async {
    final confirmed = await showConfirmDialog(
      'Delete Playlist', 
      'Are you sure you want to delete "${_playlist?.name}"? This action cannot be undone.'
    );
    
    if (confirmed) {
      await runAsyncAction(
        () async {
          final musicProvider = getProvider<MusicProvider>();
          await musicProvider.deletePlaylist(widget.playlistId, auth.token!);
          
          if (mounted) {
            Navigator.pop(context);
            showSuccess('Playlist deleted successfully');
          }
        },
        errorMessage: 'Failed to delete playlist',
      );
    }
  }

  Future<void> _requestLocationPermissionForVoting() async {
    try {
      if (_playlist?.licenseType == 'location_time') {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            AppWidgets.showSnackBar(
              context, 
              'This event requires location for voting. Please allow location access.',
              backgroundColor: Colors.blue,
            );
          }
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
            AppLogger.info('Location permission denied - will use IP location as fallback', 'PlaylistDetailScreen');
            if (mounted) {
              AppWidgets.showSnackBar(
                context,
                'Location denied. Using approximate location for voting.',
                backgroundColor: Colors.orange,
              );
            }
          } else {
            AppLogger.info('Location permission granted for voting', 'PlaylistDetailScreen');
            if (mounted) {
              AppWidgets.showSnackBar(
                context,
                'Location enabled! You can now vote on tracks.',
                backgroundColor: Colors.green,
              );
            }
          }
        } else if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          AppLogger.debug('Location permission already granted', 'PlaylistDetailScreen');
        }
      }
    } catch (e) {
      AppLogger.debug('Could not request location permission: $e', 'PlaylistDetailScreen');
    }
  }

  Future<void> _detectCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            AppWidgets.showSnackBar(context, 'Location permissions are denied', backgroundColor: Colors.red);
          }
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          AppWidgets.showSnackBar(context, 'Location permissions are permanently denied', backgroundColor: Colors.red);
        }
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          AppWidgets.showSnackBar(context, 'Location services are disabled', backgroundColor: Colors.red);
        }
        return;
      }

      if (mounted) {
        AppWidgets.showSnackBar(context, 'Detecting location...', backgroundColor: Colors.blue);
      }
      
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      
      if (!mounted) return;
      
      setState(() {
        _votingService.setLatitude(position.latitude);
        _votingService.setLongitude(position.longitude);
      });
      
      AppWidgets.showSnackBar(
        context, 
        'Location detected: Lat ${position.latitude.toStringAsFixed(6)}, Lng ${position.longitude.toStringAsFixed(6)}',
        backgroundColor: Colors.green
      );
    } catch (e) {
      if (mounted) {
        AppWidgets.showSnackBar(context, 'Failed to get location: ${e.toString()}', backgroundColor: Colors.red);
      }
    }
  }

  void _clearLocation() {
    setState(() {
      _votingService.setLatitude(null);
      _votingService.setLongitude(null);
    });
    AppWidgets.showSnackBar(context, 'Location cleared', backgroundColor: Colors.green);
  }
}
