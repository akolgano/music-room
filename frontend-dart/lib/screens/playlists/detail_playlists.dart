import 'dart:async';
import '../../core/navigation_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_providers.dart';
import '../../providers/theme_providers.dart';
import '../../services/player_services.dart';
import '../../services/api_services.dart';
import '../../services/cache_services.dart';
import '../../services/websocket_services.dart';
import '../../core/locator_core.dart'; 
import '../../models/music_models.dart';
import '../../models/sort_models.dart';
import '../../core/theme_core.dart';
import '../../core/constants_core.dart';
import '../../core/logging_core.dart';
import '../../core/responsive_core.dart';
import '../base_screens.dart';
import '../../providers/voting_providers.dart'; 
import '../../widgets/detail_widgets.dart';
import '../../widgets/sort_widgets.dart';
import '../../models/voting_models.dart';
import '../../widgets/votes_widgets.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/app_widgets.dart';
import '../../models/api_models.dart';

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
  final Set<String> _fetchingTrackDetails = {};
  final List<Completer> _pendingOperations = []; 
  Playlist? _playlist;
  List<PlaylistTrack> _tracks = [];
  bool _isOwner = false;
  bool _canEditPlaylist = false;
  VotingProvider? _votingProvider;
  Timer? _autoRefreshTimer;
  Timer? _trackCountValidationTimer;
  StreamSubscription<PlaylistUpdateMessage>? _playlistUpdateSubscription;
  
  final Map<String, String> _trackIdToPlaylistTrackId = {};
  
  bool _isVotingMode = false;
  bool _isPublicVoting = true;
  String _votingLicenseType = 'open';
  DateTime? _votingStartTime;
  DateTime? _votingEndTime;
  PlaylistVotingInfo? _votingInfo;
  double? _latitude;
  double? _longitude;
  int? _allowedRadiusMeters;

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
        _setupWebSocketConnection();
        _loadData();
        _startAutoRefresh();
        _startTrackCountValidation();
      }
    });
  }

  @override
  void dispose() {
    _cancelPendingOperations();
    _stopAutoRefresh();
    _stopTrackCountValidation();
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
    if (_canEditPlaylist) buildLoggingIconButton(
      icon: const Icon(Icons.edit), 
      onPressed: () {
        logButtonClick('edit_playlist', metadata: {'playlist_id': widget.playlistId});
        _openPlaylistEditor();
      },
      buttonName: 'edit_playlist_button',
    ),
    if (_playlist != null && !_playlist!.isPublic) buildLoggingIconButton(
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
        return CustomSingleChildScrollView(
          padding: EdgeInsets.symmetric(
            vertical: MusicAppResponsive.getSpacing(context, tiny: 4.0, small: 5.0, medium: 6.0),
            horizontal: MusicAppResponsive.getSpacing(context, tiny: 1.0, small: 1.5, medium: 2.0)
          ),
          child: Column(
            children: [
              PlaylistDetailWidgets.buildThemedPlaylistHeader(context, _playlist!),
              SizedBox(height: MusicAppResponsive.getSpacing(context, tiny: 4.0, small: 5.0, medium: 6.0)),
              if (_isVotingMode) ...PlaylistVotingWidgets.buildVotingModeHeader(
                context: context,
                isOwner: _isOwner,
                isPublicVoting: _isPublicVoting,
                votingLicenseType: _votingLicenseType,
                votingStartTime: _votingStartTime,
                votingEndTime: _votingEndTime,
                votingInfo: _votingInfo,
                onPublicVotingChanged: (value) => setState(() => _isPublicVoting = value),
                onLicenseTypeChanged: (value) => setState(() => _votingLicenseType = value),
                onApplyVotingSettings: _applyVotingSettings,
                onSelectVotingDateTime: _selectVotingDateTime,
              ),
              PlaylistDetailWidgets.buildThemedPlaylistStats(context, _tracks),
              SizedBox(height: MusicAppResponsive.getSpacing(context, tiny: 4.0, small: 5.0, medium: 6.0)),
              PlaylistDetailWidgets.buildThemedPlaylistActions(
                context, 
                onPlayAll: _playPlaylist, 
                onShuffle: _shufflePlaylist,
                onAddRandomTrack: _canEditPlaylist ? _addRandomTrack : null,
              ),
              SizedBox(height: MusicAppResponsive.getSpacing(context, tiny: 4.0, small: 5.0, medium: 6.0)),
              _isVotingMode ? PlaylistVotingWidgets.buildVotingTracksSection(
                context: context,
                tracks: _tracks,
                playlistId: widget.playlistId,
                onLoadData: () => _loadData(),
                onSuggestTrackForVoting: _suggestTrackForVoting,
                votingInfo: _votingInfo,
                playlistOwnerId: _playlist?.creator,
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
          color: Theme.of(context).colorScheme.surface,
          elevation: 4,
          shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
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
                if (currentSort.field != TrackSortField.position) ...[
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
    final canReorder = currentSort.field == TrackSortField.position && _canEditPlaylist;
    AppLogger.debug('Building tracks list: canReorder=$canReorder, tracks.length=${tracks.length}, _canEditPlaylist=$_canEditPlaylist', 'PlaylistDetailScreen');
    
    return ListView.builder(
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
      return PlaylistDetailWidgets.buildErrorTrackItem(key, playlistTrack, index, isLoading: true);
    }

    final musicProvider = getProvider<MusicProvider>();
    final sortedTracks = musicProvider.sortedPlaylistTracks;
    
    return PlaylistDetailWidgets.buildTrackItem(
      context: context,
      playlistTrack: playlistTrack,
      index: index,
      isOwner: _canEditPlaylist,
      onPlay: () => _playTrackAt(index),
      onRemove: _canEditPlaylist ? () => _removeTrack(playlistTrack.trackId) : null,
      onMoveUp: _canEditPlaylist && index > 0 ? () => _moveTrackWithSortCheck(index, index - 1) : null,
      onMoveDown: _canEditPlaylist && index < sortedTracks.length - 1 ? () => _moveTrackWithSortCheck(index, index + 1) : null,
      canReorder: _canEditPlaylist,
      playlistId: widget.playlistId,
      isEvent: _playlist?.isEvent ?? false,
      key: key,
    );
  }



  void _setupWebSocketConnection() {
    _playlistUpdateSubscription = _webSocketService.playlistUpdateStream.listen(
      (updateMessage) {
        AppLogger.debug('Received WebSocket playlist update: ${updateMessage.tracks.length} tracks', 'PlaylistDetailScreen');
        
        if (updateMessage.playlistId == widget.playlistId && mounted) {
          _handlePlaylistUpdate(updateMessage.tracks);
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

  bool _needsTrackDetailsFetch(Track? track) {
    return track?.deezerTrackId != null && 
           _trackHasMissingDetails(track) &&
           !_fetchingTrackDetails.contains(track!.deezerTrackId!);
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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

  bool _shouldSkipTrackDetailsFetch(String? deezerTrackId, Track? track) {
    return deezerTrackId == null || 
           _fetchingTrackDetails.contains(deezerTrackId) || 
           !mounted ||
           (track != null && !_trackHasMissingDetails(track));
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

  void _handlePlaylistUpdate(List<PlaylistTrack> updatedTracks) {
    AppLogger.debug('Handling playlist update - WebSocket received', 'PlaylistDetailScreen');
    
    _updateTrackIdMapping(updatedTracks);
    
    if (mounted) {
      _loadData();
    }
    
    AppLogger.debug('Triggered data reload via WebSocket update', 'PlaylistDetailScreen');
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
            // Disable voting mode if playlist is not an event
            if (!_playlist!.isEvent && _isVotingMode) {
              _isVotingMode = false;
            }
          });
          
          await _refreshTracksFromProvider();
          
          if (_votingProvider != null) {
            _votingProvider!.setVotingPermission(true);
            _votingProvider!.initializeTrackPoints(_tracks);
          }
          
          await _loadVotingSettings();
          
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
      AppLogger.error('Error refreshing playlist data: ${e.toString()}', null, null, 'PlaylistDetailScreen');
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
    
    AppLogger.debug('Starting parallel fetch for ${tracksNeedingDetails.length} tracks', 'PlaylistDetailScreen');
    
    final futures = tracksNeedingDetails.map((playlistTrack) {
      return _fetchTrackDetailsIfNeeded(playlistTrack, -1); 
    }).toList();
    
    try {
      await Future.wait(futures);
      AppLogger.debug('Completed parallel fetch for ${tracksNeedingDetails.length} tracks', 'PlaylistDetailScreen');
    } catch (e) {
      _logError('in batch track fetch', e);
    }
  }

  Future<void> _playPlaylist() async {
    final musicProvider = getProvider<MusicProvider>();
    final sortedTracks = musicProvider.sortedPlaylistTracks;
    
    if (sortedTracks.isEmpty) {
      return;
    }
    
    try {
      final playerService = getProvider<MusicPlayerService>();
      await playerService.setPlaylistAndPlay(
        playlist: sortedTracks,
        startIndex: 0,
        playlistId: widget.playlistId,
        authToken: auth.token,
      );
    } catch (e) {
      AppLogger.error('Failed to play playlist', e, null, 'PlaylistDetailScreen');
    }
  }

  Future<void> _shufflePlaylist() async {
    final musicProvider = getProvider<MusicProvider>();
    final sortedTracks = musicProvider.sortedPlaylistTracks;
    
    if (sortedTracks.isEmpty) {
      return;
    }
    
    if (!_canEditPlaylist) {
      return;
    }
    
    await runAsyncAction(
      () async {
        await musicProvider.shufflePlaylistTracks(widget.playlistId, auth.token!);
        
        final playerService = getProvider<MusicPlayerService>();
        final shuffledTracks = List<PlaylistTrack>.from(musicProvider.sortedPlaylistTracks);
        
        await playerService.setPlaylistAndPlay(
          playlist: shuffledTracks,
          startIndex: 0,
          playlistId: widget.playlistId,
          authToken: auth.token,
        );
        playerService.toggleShuffle();
      },
      successMessage: 'Shuffled "${_playlist!.name}"',
      errorMessage: 'Failed to shuffle playlist',
    );
  }

  Future<void> _addRandomTrack() async {
    if (auth.token == null) {
      return;
    }

    await runAsyncAction(
      () async {
        final musicProvider = getProvider<MusicProvider>();
        final result = await musicProvider.addRandomTrackToPlaylist(widget.playlistId, auth.token!);
        
        if (result.success) {
          await _refreshTracksFromProvider();
        } else {
        }
      },
      errorMessage: 'Failed to add random track',
    );
  }

  Future<void> _playTrackAt(int index) async {
    final musicProvider = getProvider<MusicProvider>();
    final sortedTracks = musicProvider.sortedPlaylistTracks;
    
    if (index < 0 || index >= sortedTracks.length) return;
    
    try {
      final playerService = getProvider<MusicPlayerService>();
      
      await playerService.setPlaylistAndPlay(
        playlist: sortedTracks,
        startIndex: index,
        playlistId: widget.playlistId,
        authToken: auth.token,
      );
      
      final track = sortedTracks[index].track;
      if (track != null) {
        AppLogger.debug('Playing track: ${track.name}', 'PlaylistDetailScreen');
      }
    } catch (e) {
      AppLogger.error('Failed to play track at index $index', e, null, 'PlaylistDetailScreen');
    }
  }

  Future<void> _removeTrack(String trackId) async {
    if (!_canEditPlaylist) return;
    
    final confirmed = await showConfirmDialog('Remove Track', 'Remove this track from the playlist?');
    
    if (confirmed) {
      await runAsyncAction(
        () async {
          final musicProvider = getProvider<MusicProvider>();
          
          final playlistTrackId = _trackIdToPlaylistTrackId[trackId] ?? trackId;
          AppLogger.debug('Removing track: Track.id=$trackId, using PlaylistTrackId=$playlistTrackId', 'PlaylistDetailScreen');
          AppLogger.debug('TrackId mapping size: ${_trackIdToPlaylistTrackId.length}', 'PlaylistDetailScreen');
          
          
          try {
            int.parse(playlistTrackId);
            AppLogger.debug('PlaylistTrackId $playlistTrackId is valid integer', 'PlaylistDetailScreen');
          } catch (e) {
            AppLogger.error('PlaylistTrackId $playlistTrackId is not a valid integer', e, null, 'PlaylistDetailScreen');
          }
          
          await musicProvider.removeTrackFromPlaylist(
            playlistId: widget.playlistId, 
            trackId: playlistTrackId, 
            token: auth.token!
          );
          await _refreshTracksFromProvider();
        },
        successMessage: 'Track removed from playlist',
        errorMessage: 'Failed to remove track',
      );
    }
  }

  Future<void> _moveTrackWithSortCheck(int fromIndex, int toIndex) async {
    if (!_canEditPlaylist) return;
    
    final musicProvider = getProvider<MusicProvider>();
    final currentSort = musicProvider.currentSortOption;
    
    
    if (currentSort.field != TrackSortField.position) {
      musicProvider.resetToCustomOrder();
      
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Switched to Custom Order to enable track reordering'),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
      
      
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    
    await _moveTrack(fromIndex, toIndex);
  }

  Future<void> _moveTrack(int fromIndex, int toIndex) async {
    if (!mounted || fromIndex == toIndex || fromIndex < 0 || toIndex < 0) return;
    
    final musicProvider = getProvider<MusicProvider>();
    final sortedTracks = musicProvider.sortedPlaylistTracks;
    
    if (fromIndex >= sortedTracks.length || toIndex >= sortedTracks.length) return;
    
    try {
      setState(() {
        final tracks = List<PlaylistTrack>.from(sortedTracks);
        final item = tracks.removeAt(fromIndex);
        tracks.insert(toIndex, item);
        
        for (int i = 0; i < tracks.length; i++) {
          tracks[i] = PlaylistTrack(
            trackId: tracks[i].trackId, 
            name: tracks[i].name, 
            position: i, 
            track: tracks[i].track,
            points: tracks[i].points,
          );
        }
        _tracks = tracks;
      });
      await _updateTrackOrder(fromIndex, toIndex);
    } catch (e) {
      _logError('moving track', e);
    }
  }

  Future<void> _updateTrackOrder(int oldIndex, int newIndex) async {
    try {
      final musicProvider = getProvider<MusicProvider>();
      
      
      
      int adjustedInsertBefore = newIndex;
      if (newIndex > oldIndex) {
        adjustedInsertBefore = newIndex + 1;
      }
      
      await musicProvider.moveTrackInPlaylist(
        playlistId: widget.playlistId, 
        rangeStart: oldIndex, 
        insertBefore: adjustedInsertBefore,
        token: auth.token!,
      );
      
      if (mounted) {
        await _refreshTracksFromProvider();
      }
    } catch (e) {
      _logError('updating track order', e);
      if (mounted) {
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
        if (mounted) {
        }
      },
    );
  }

  void _openPlaylistEditor() {
    Navigator.pushNamed(
      context,
      AppRoutes.playlistEditor,
      arguments: widget.playlistId,
    ).then((_) {
      if (mounted) _loadData();
    });
  }


  Future<void> _sharePlaylist() async {
    if (_playlist != null && mounted) {
      final result = await Navigator.pushNamed(context, AppRoutes.playlistSharing, arguments: _playlist);
      if (result is Playlist && mounted) {
        setState(() {
          _playlist = result;
        });
      }
    }
  }

  Future<void> _addSongs() async {
    final result = await Navigator.pushNamed(context, AppRoutes.trackSearch, arguments: widget.playlistId);
    if (result == true && mounted) await _loadData();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        final trackCacheService = getIt<TrackCacheService>();
        if (trackCacheService.retryCount.isNotEmpty) {
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

  void _startTrackCountValidation() {
    _trackCountValidationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _validateTrackCounts();
      }
    });
  }

  void _stopTrackCountValidation() {
    _trackCountValidationTimer?.cancel();
    _trackCountValidationTimer = null;
  }

  void _validateTrackCounts() {
    final musicProvider = _getMountedProvider<MusicProvider>();
    if (musicProvider == null) return;

    final displayedTracks = musicProvider.sortedPlaylistTracks;
    final localTracksCount = _tracks.length;
    final displayedTracksCount = displayedTracks.length;

    if (localTracksCount != displayedTracksCount) {
      AppLogger.debug('Track count mismatch detected: local=$localTracksCount, displayed=$displayedTracksCount - triggering hard refresh', 'PlaylistDetailScreen');
      _loadData();
    }
  }

  void _cancelPendingOperations() {
    for (final completer in _pendingOperations) {
      if (!completer.isCompleted) completer.complete();
    }
    _pendingOperations.clear();
    _fetchingTrackDetails.clear();
    _trackIdToPlaylistTrackId.clear();
  }

  Future<void> _applyVotingSettings() async {
    final auth = getProvider<AuthProvider>();
    if (auth.token == null) {
      AppWidgets.showSnackBar(context, 'Authentication required', backgroundColor: Colors.red);
      return;
    }

    try {
      String? voteStartTimeStr;
      String? voteEndTimeStr;
      
      if (_votingLicenseType == 'location_time') {
        if (_votingStartTime != null) {
          voteStartTimeStr = '${_votingStartTime!.hour.toString().padLeft(2, '0')}:${_votingStartTime!.minute.toString().padLeft(2, '0')}:${_votingStartTime!.second.toString().padLeft(2, '0')}';
        }
        if (_votingEndTime != null) {
          voteEndTimeStr = '${_votingEndTime!.hour.toString().padLeft(2, '0')}:${_votingEndTime!.minute.toString().padLeft(2, '0')}:${_votingEndTime!.second.toString().padLeft(2, '0')}';
        }
      }

      final request = PlaylistLicenseRequest(
        licenseType: _votingLicenseType,
        invitedUsers: _votingLicenseType != 'open' ? [] : null,
        voteStartTime: voteStartTimeStr,
        voteEndTime: voteEndTimeStr,
        latitude: _votingLicenseType == 'location_time' ? _latitude : null,
        longitude: _votingLicenseType == 'location_time' ? _longitude : null,
        allowedRadiusMeters: _votingLicenseType == 'location_time' ? _allowedRadiusMeters : null,
      );

      final apiService = getIt<ApiService>();
      await apiService.updatePlaylistLicense(widget.playlistId, auth.token!, request);
      
      AppWidgets.showSnackBar(context, 'Voting settings updated successfully!', backgroundColor: Colors.green);
      
      await _loadVotingSettings();
      
      _votingInfo = PlaylistVotingInfo(
        playlistId: widget.playlistId,
        restrictions: VotingRestrictions(
          licenseType: _votingLicenseType,
          isInvited: true,
          isInTimeWindow: _votingLicenseType != 'location_time' || _isInVotingTimeWindow(),
          isInLocation: true,
        ),
        trackVotes: {},
      );
      
    } catch (e) {
      AppLogger.error('Failed to update voting settings', e, null, 'PlaylistDetailScreen');
      AppWidgets.showSnackBar(context, 'Failed to update voting settings: ${e.toString()}', backgroundColor: Colors.red);
    }
    
    setState(() {});
  }

  Future<void> _loadVotingSettings() async {
    final auth = getProvider<AuthProvider>();
    if (auth.token == null) {
      AppLogger.warning('Cannot load voting settings - no authentication token', 'PlaylistDetailScreen');
      return;
    }

    try {
      final apiService = getIt<ApiService>();
      final licenseResponse = await apiService.getPlaylistLicense(widget.playlistId, auth.token!);
      
      setState(() {
        _votingLicenseType = licenseResponse.licenseType;
        
        if (licenseResponse.voteStartTime != null) {
          final timeStr = licenseResponse.voteStartTime!;
          final timeParts = timeStr.split(':');
          if (timeParts.length >= 2) {
            final hour = int.tryParse(timeParts[0]) ?? 0;
            final minute = int.tryParse(timeParts[1]) ?? 0;
            final second = timeParts.length > 2 ? (int.tryParse(timeParts[2]) ?? 0) : 0;
            _votingStartTime = DateTime(2000, 1, 1, hour, minute, second);
          }
        }
        if (licenseResponse.voteEndTime != null) {
          final timeStr = licenseResponse.voteEndTime!;
          final timeParts = timeStr.split(':');
          if (timeParts.length >= 2) {
            final hour = int.tryParse(timeParts[0]) ?? 0;
            final minute = int.tryParse(timeParts[1]) ?? 0;
            final second = timeParts.length > 2 ? (int.tryParse(timeParts[2]) ?? 0) : 0;
            _votingEndTime = DateTime(2000, 1, 1, hour, minute, second);
          }
        }
        
        _latitude = licenseResponse.latitude;
        _longitude = licenseResponse.longitude;
        _allowedRadiusMeters = licenseResponse.allowedRadiusMeters;
        
        _isPublicVoting = licenseResponse.licenseType == 'open';
      });
      
      AppLogger.info('Successfully loaded voting settings: ${licenseResponse.licenseType}', 'PlaylistDetailScreen');
      
    } catch (e) {
      AppLogger.error('Failed to load voting settings: $e', null, null, 'PlaylistDetailScreen');
    }
  }

  bool _isInVotingTimeWindow() {
    final now = DateTime.now();
    if (_votingStartTime != null && now.isBefore(_votingStartTime!)) return false;
    if (_votingEndTime != null && now.isAfter(_votingEndTime!)) return false;
    return true;
  }

  Future<void> _selectVotingDateTime(bool isStartTime) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isStartTime) {
            _votingStartTime = dateTime;
          } else {
            _votingEndTime = dateTime;
          }
        });
      }
    }
  }

  Future<void> _suggestTrackForVoting() async {
    final selectedTrack = await Navigator.pushNamed(
      context, 
      AppRoutes.trackSearch,
      arguments: {'selectMode': true},
    ) as Track?;

    if (selectedTrack != null) {
      try {
        final musicProvider = getProvider<MusicProvider>();
        await musicProvider.addTrackObjectToPlaylist(
          widget.playlistId,
          selectedTrack,
          auth.token!,
        );
        
        await _loadData();
      } catch (e) {
        AppLogger.error('Failed to suggest track for voting', e, null, 'PlaylistDetailScreen');
      }
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
}
