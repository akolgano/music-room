// lib/screens/playlists/playlist_detail_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'playlist_licensing_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/dynamic_theme_provider.dart';
import '../../services/music_player_service.dart';
import '../../services/api_service.dart';
import '../../core/service_locator.dart'; 
import '../../models/models.dart';
import '../../models/sort_models.dart';
import '../../services/track_sorting_service.dart';
import '../../core/core.dart';
import '../../widgets/widgets.dart'; 
import '../../widgets/app_widgets.dart';
import '../../widgets/track_sort_bottom_sheet.dart';
import '../../widgets/sort_button.dart';
import '../base_screen.dart';
import '../../providers/voting_provider.dart';
import '../../widgets/voting_widgets.dart';
import '../../models/voting_models.dart';
import '../../core/theme_utils.dart'; 

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  const PlaylistDetailScreen({Key? key, required this.playlistId}) : super(key: key);
  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends BaseScreen<PlaylistDetailScreen> {
  late final ApiService _apiService;
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
    for (final completer in _pendingOperations) if (!completer.isCompleted) completer.complete();
    _pendingOperations.clear();
    _fetchingTrackDetails.clear();
  }

  @override
  List<Widget> get actions => [
    if (_isOwner)
      IconButton(icon: const Icon(Icons.settings), onPressed: _openPlaylistSettings, tooltip: 'Playlist Settings'),
    IconButton(icon: const Icon(Icons.share), onPressed: _sharePlaylist, tooltip: 'Share Playlist'),
    IconButton(
      icon: const Icon(Icons.refresh), 
      onPressed: _loadData, tooltip: 'Refresh'
    ),
  ];

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
            print('Initializing voting system with ${_tracks.length} tracks');
            _votingProvider!.clearVotingData();
            _votingProvider!.setVotingPermission(true);
            _votingProvider!.initializeTrackPoints(_tracks);
            for (int i = 0; i < _tracks.length; i++) {
              print('Track $i: ${_tracks[i].name} - ${_tracks[i].points} points');
            }
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
      print('Error refreshing playlist data: $e');
    }
  }

  void _initializeVotingData(VotingProvider votingProvider) {
    votingProvider.clearVotingData();
  }

  Future<void> _fetchTrackDetailsIfNeeded(PlaylistTrack playlistTrack, int index) async {
    final track = playlistTrack.track;
    final deezerTrackId = track?.deezerTrackId;
    if (deezerTrackId == null || 
        _fetchingTrackDetails.contains(deezerTrackId) || 
        !mounted ||
        (track != null && track.artist.isNotEmpty && track.album.isNotEmpty)) return;

    print('Fetching track details for Deezer ID: $deezerTrackId (index: $index)');
    _fetchingTrackDetails.add(deezerTrackId);
    
    try {
      final trackDetails = await _apiService.getDeezerTrack(deezerTrackId, auth.token!);
      if (!mounted) return;
      
      if (trackDetails != null) {
        print('Successfully fetched track details: ${trackDetails.name}');
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
      print('ERROR fetching track details for $deezerTrackId: $e');
    } finally {
      if (mounted) _fetchingTrackDetails.remove(deezerTrackId);
    }
  }

  String _generateUniqueKey(PlaylistTrack playlistTrack, int index) {
    final trackId = playlistTrack.trackId ?? 'unknown';
    final trackName = playlistTrack.track?.name ?? playlistTrack.name ?? 'unknown';
    final position = playlistTrack.position;
    final deezerTrackId = playlistTrack.track?.deezerTrackId ?? 'none';
    final keyString = 'track_${trackId}_${position}_${index}_${deezerTrackId}_${trackName.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
    print('Generated key for track at index $index: $keyString');
    return keyString;
  }

  Widget _buildTracksList(List<PlaylistTrack> tracks, TrackSortOption currentSort) {
    final canReorder = currentSort.field == TrackSortField.position && _isOwner;
    print('Building tracks list: canReorder=$canReorder, tracks.length=${tracks.length}');
    
    if (canReorder) {
      print('Creating ReorderableListView with ${tracks.length} items');
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
            print('Building reorderable item $index with key: $keyString');
            final widget = _buildTrackItem(playlistTrack, index, key: uniqueKey);
            return KeyedSubtree(
              key: uniqueKey,
              child: widget,
            );
          } catch (e, stackTrace) {
            print('ERROR building reorderable track item at index $index: $e');
            print('Stack trace: $stackTrace');
            return Container(
              key: ValueKey('error_$index'),
              padding: const EdgeInsets.all(16),
              child: Text('Error loading track at position $index', style: const TextStyle(color: Colors.red)),
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
            print('ERROR building track item at index $index: $e');
            print('Stack trace: $stackTrace');
            return Container(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading track at position $index', style: const TextStyle(color: Colors.red)),
            );
          }
        },
      );
    }
  }

  Widget _buildTrackItem(PlaylistTrack playlistTrack, int index, {Key? key}) {
    try {
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
        return _buildLoadingTrackItem(key, playlistTrack, index);
      }
      if (track != null) {
        return Container(
          key: key,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildTrackImage(track),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.artist,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 1, child: _buildVotingSection(index, playlistTrack)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_arrow, color: AppTheme.primary, size: 20),
                      onPressed: () => _playTrackAt(index),
                      tooltip: 'Play track',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    if (_isOwner)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                        onPressed: () => _removeTrack(playlistTrack.trackId),
                        tooltip: 'Remove from playlist', constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
      return _buildErrorTrackItem(key, playlistTrack, index);
      
    } catch (e, stackTrace) {
      print('ERROR in _buildTrackItem for index $index: $e');
      print('Stack trace: $stackTrace');
      return _buildErrorTrackItem(key, playlistTrack, index);
    }
  }

  Widget _buildErrorTrackItem(Key? key, PlaylistTrack playlistTrack, int index) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: Colors.red.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.music_off, color: Colors.white),
        ),
        title: Text(
          playlistTrack.name,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: const Text('Track details unavailable', style: TextStyle(color: Colors.grey)),
        trailing: _buildVotingSection(index, playlistTrack),
      ),
    );
  }

  Widget _buildLoadingTrackItem(Key? key, PlaylistTrack playlistTrack, int index) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface, 
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.music_note, color: Colors.white),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          playlistTrack.track?.name ?? playlistTrack.name,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: const Text('Loading track details...', style: TextStyle(color: Colors.grey)),
        trailing: _buildVotingSection(index, playlistTrack),
      ),
    );
  }

  Future<void> _voteForTrack(int trackIndex) async {
    print('Attempting to vote for track at index $trackIndex');
    
    if (_votingProvider == null) {
      print('ERROR: Voting provider is null');
      showError('Voting system not initialized');
      return;
    }

    if (trackIndex < 0 || trackIndex >= _tracks.length) {
      print('ERROR: Invalid track index $trackIndex');
      showError('Invalid track index');
      return;
    }

    try {
      if (!_votingProvider!.canVote) {
        print('Forcing voting to be enabled');
        _votingProvider!.setVotingPermission(true);
      }

      print('Voting for track at index $trackIndex');
      final success = await _votingProvider!.upvoteTrackByIndex(
        widget.playlistId,
        trackIndex,
        auth.token!,
      );
      
      if (success && mounted) {
        print('Vote successful, updating local state');
        setState(() {
          if (trackIndex < _tracks.length) {
            final currentTrack = _tracks[trackIndex];
            _tracks[trackIndex] = PlaylistTrack(trackId: currentTrack.trackId,
              name: currentTrack.name,
              position: currentTrack.position,
              points: currentTrack.points + 1,
              track: currentTrack.track,
            );
          }
        });
        await _refreshAfterVoting();
        showSuccess('Vote recorded!');
      } else {
        print('Vote failed');
        showError('Failed to vote');
      }
    } catch (e, stackTrace) {
      print('ERROR voting: $e');
      print('Stack trace: $stackTrace');
      showError('Error voting: $e');
    }
  }

  List<Widget> _buildTrackActionButtons(int index, PlaylistTrack playlistTrack) {
    final buttons = <Widget>[];
    
    buttons.add(
      IconButton(
        icon: const Icon(Icons.play_arrow, color: AppTheme.primary),
        onPressed: () => _playTrackAt(index),
        tooltip: 'Play track',
      ),
    );
    
    if (_isOwner) {
      buttons.add(
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: () => _removeTrack(playlistTrack.trackId),
          tooltip: 'Remove from playlist',
        ),
      );
    }
    
    return buttons;
  }

  Color _getPointsColor(int points) {
    if (points > 5) return Colors.green;
    if (points > 0) return Colors.orange;
    return Colors.grey;
  }

  Widget _buildTrackImage(Track track) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: track.imageUrl?.isNotEmpty == true
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(track.imageUrl!, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note, color: Colors.white, size: 24),
              ),
            )
          : const Icon(Icons.music_note, color: Colors.white, size: 24),
    );
  }

  Widget _buildVotingSection(int index, PlaylistTrack playlistTrack) {
    if (_votingProvider == null) {
      return const SizedBox.shrink();
    }

    return Consumer<VotingProvider>(
      builder: (context, votingProvider, _) {
        final currentPoints = playlistTrack.points;
        final hasUserVoted = votingProvider.hasUserVotedByIndex(index);
        final canVote = votingProvider.canVote && !hasUserVoted;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getPointsColor(currentPoints).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getPointsColor(currentPoints).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: canVote ? () => _voteForTrack(index) : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    hasUserVoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: hasUserVoted 
                      ? Colors.green 
                      : (canVote ? _getPointsColor(currentPoints) : Colors.grey),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '+$currentPoints',
                style: TextStyle(color: _getPointsColor(currentPoints), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPointsStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  String _getTotalPoints() {
    final total = _tracks.fold<int>(0, (sum, track) => sum + track.points);
    return total.toString();
  }

  String _getTopTrackPoints() {
    if (_tracks.isEmpty) return '0';
    final maxPoints = _tracks.map((t) => t.points).reduce((a, b) => a > b ? a : b);
    return maxPoints.toString();
  }

  String _getVotedTracksCount() {
    final votedCount = _tracks.where((track) => track.points != 0).length;
    return votedCount.toString();
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
                _buildThemedPlaylistHeader(context, themeProvider),
                const SizedBox(height: 16), _buildThemedPlaylistStats(context),
                const SizedBox(height: 16), _buildThemedPlaylistActions(context),
                const SizedBox(height: 16), _buildThemedTracksSection(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemedPlaylistHeader(BuildContext context, DynamicThemeProvider themeProvider) {
    return ThemeUtils.buildThemedHeaderCard(
      context: context,
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [ThemeUtils.getPrimary(context).withOpacity(0.8), ThemeUtils.getPrimary(context).withOpacity(0.4)],
              ),
              boxShadow: [
                BoxShadow(
                  color: ThemeUtils.getPrimary(context).withOpacity(0.3), 
                  blurRadius: 20, 
                  offset: const Offset(0, 8)
                ),
              ],
            ),
            child: _playlist!.imageUrl?.isNotEmpty == true
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _playlist!.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      Icon(Icons.library_music, size: 60, color: ThemeUtils.getOnSurface(context)),
                  ),
                )
              : Icon(Icons.library_music, size: 60, color: ThemeUtils.getOnSurface(context)),
          ),
          const SizedBox(height: 20),
          Text(
            _playlist!.name,
            style: ThemeUtils.getHeadingStyle(context).copyWith(fontSize: 28),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_playlist!.description.isNotEmpty) ...[
            Text(
              _playlist!.description,
              style: ThemeUtils.getCaptionStyle(context).copyWith(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Created by ${_playlist!.creator}',
                style: ThemeUtils.getCaptionStyle(context),
              ),
              const SizedBox(width: 12),
              _buildThemedVisibilityChip(context, _playlist!.isPublic),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh, color: Colors.blue, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Pull down to refresh • Auto-refresh every 30s',
                  style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemedVisibilityChip(BuildContext context, bool isPublic) {
    final chipColor = isPublic ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.public : Icons.lock,
            size: 14,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            isPublic ? 'Public' : 'Private',
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemedPlaylistStats(BuildContext context) {
    final totalDuration = _tracks.length * 3;
    return Card(
      color: ThemeUtils.getSurface(context),
      elevation: 4,
      shadowColor: ThemeUtils.getPrimary(context).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildThemedStatItem(
              context,
              icon: Icons.queue_music,
              label: 'Tracks',
              value: '${_tracks.length}',
            ),
            _buildThemedStatItem(
              context,
              icon: Icons.access_time,
              label: 'Duration',
              value: '${totalDuration}m',
            ),
            _buildThemedStatItem(
              context,
              icon: Icons.favorite,
              label: 'Likes',
              value: '0',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemedStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: ThemeUtils.getPrimary(context), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: ThemeUtils.getSubheadingStyle(context),
        ),
        Text(
          label,
          style: ThemeUtils.getCaptionStyle(context).copyWith(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildThemedPlaylistActions(BuildContext context) {
    return Card(
      color: ThemeUtils.getSurface(context),
      elevation: 4,
      shadowColor: ThemeUtils.getPrimary(context).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _playPlaylist,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play All'),
                style: ThemeUtils.getPrimaryButtonStyle(context).copyWith(
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 12)
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shufflePlaylist,
                icon: const Icon(Icons.shuffle),
                label: const Text('Shuffle'),
                style: ThemeUtils.getSecondaryButtonStyle(context).copyWith(
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 12)
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemedTracksSection(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, _) {
        final sortedTracks = musicProvider.sortedPlaylistTracks;
        return Card(
          color: ThemeUtils.getSurface(context),
          elevation: 4,
          shadowColor: ThemeUtils.getPrimary(context).withOpacity(0.1),
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
                        Text(
                          'Tracks',
                          style: ThemeUtils.getSubheadingStyle(context),
                        ),
                      ],
                    ),
                    Text(
                      '${sortedTracks.length} tracks',
                      style: ThemeUtils.getCaptionStyle(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (sortedTracks.isEmpty) 
                  _buildThemedEmptyTracksState(context)
                else 
                  _buildThemedTracksList(context, sortedTracks),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemedEmptyTracksState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.music_note, size: 64, color: ThemeUtils.getOnSurface(context).withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No tracks yet',
              style: ThemeUtils.getSubheadingStyle(context),
            ),
            const SizedBox(height: 8),
            Text(
              _isOwner ? 'Add some tracks to get started!' : 'This playlist is empty',
              style: ThemeUtils.getCaptionStyle(context),
              textAlign: TextAlign.center,
            ),
            if (_isOwner) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => navigateTo(AppRoutes.trackSearch, arguments: widget.playlistId),
                icon: const Icon(Icons.add),
                label: const Text('Add Tracks'),
                style: ThemeUtils.getPrimaryButtonStyle(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThemedTracksList(BuildContext context, List<PlaylistTrack> tracks) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final playlistTrack = tracks[index];
        final track = playlistTrack.track;
        if (track != null) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: ThemeUtils.getSurface(context).withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ThemeUtils.getPrimary(context).withOpacity(0.1)
              ),
            ),
            child: ListTile(
              leading: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ThemeUtils.getPrimary(context).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: track.imageUrl?.isNotEmpty == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          track.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.music_note, color: ThemeUtils.getOnSurface(context), size: 24),
                        ),
                      )
                    : Icon(Icons.music_note, color: ThemeUtils.getOnSurface(context), size: 24),
              ),
              title: Text(
                track.name,
                style: ThemeUtils.getBodyStyle(context).copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                track.artist,
                style: ThemeUtils.getCaptionStyle(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.play_arrow, color: ThemeUtils.getPrimary(context)),
                    onPressed: () => _playTrackAt(index),
                  ),
                  if (_isOwner)
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: ThemeUtils.getError(context)),
                      onPressed: () => _removeTrack(track.id),
                    ),
                ],
              ),
              onTap: () => _playTrackAt(index),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Future<void> _refreshAfterVoting() async {
    if (!mounted) return;
    
    try {
      final musicProvider = getProvider<MusicProvider>();
      final votingProvider = getProvider<VotingProvider>();
      
      await musicProvider.fetchPlaylistTracks(widget.playlistId, auth.token!);
      if (mounted) {
        setState(() => _tracks = musicProvider.playlistTracks);
        votingProvider.initializeTrackPoints(_tracks);
      }
    } catch (e, stackTrace) {
      print('ERROR refreshing after voting: $e');
      print('Stack trace: $stackTrace');
    }
  }

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
      icon: const Icon(Icons.add), label: const Text('Add Songs'),
    );
  }

  Widget _buildPlaylistHeader() {
    return AppTheme.buildHeaderCard(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary.withOpacity(0.8), 
                  AppTheme.primary.withOpacity(0.4)
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3), 
                  blurRadius: 20, 
                  offset: const Offset(0, 8)
                ),
              ],
            ),
            child: _playlist!.imageUrl?.isNotEmpty == true
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _playlist!.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.library_music, size: 60, color: Colors.white),
                  ),
                )
              : const Icon(Icons.library_music, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            _playlist!.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_playlist!.description.isNotEmpty) ...[
            Text(
              _playlist!.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Created by ${_playlist!.creator}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              _buildVisibilityChip(_playlist!.isPublic),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityChip(bool isPublic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isPublic ? Colors.green : Colors.orange).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPublic ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.public : Icons.lock,
            size: 14,
            color: isPublic ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isPublic ? 'Public' : 'Private',
            style: TextStyle(
              color: isPublic ? Colors.green : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistStats() {
    final totalDuration = _tracks.length * 3; 
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.queue_music,
              label: 'Tracks',
              value: '${_tracks.length}',
            ),
            _buildStatItem(
              icon: Icons.access_time,
              label: 'Duration',
              value: '${totalDuration}m',
            ),
            _buildStatItem(
              icon: Icons.favorite,
              label: 'Likes',
              value: '0', 
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistActions() {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _playPlaylist,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shufflePlaylist,
                icon: const Icon(Icons.shuffle),
                label: const Text('Shuffle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white), padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTracksSection() {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, _) {
        final sortedTracks = musicProvider.sortedPlaylistTracks;
        final currentSort = musicProvider.currentSortOption;
        
        try {
          return Card(
            color: AppTheme.surface,
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
                          Icon(Icons.queue_music, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Tracks',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '${sortedTracks.length} tracks',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          SortButton(
                            currentSort: currentSort,
                            onPressed: _showSortOptions,
                            showLabel: false,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (currentSort.field != TrackSortField.position) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
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
                              if (mounted) {
                                showInfo('Restored to custom order');
                              }
                            },
                            child: Icon(Icons.close, size: 14, color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (sortedTracks.isEmpty) 
                    _buildEmptyTracksState()
                  else 
                    _buildTracksList(sortedTracks, currentSort),
                ],
              ),
            ),
          );
        } catch (e, stackTrace) {
          print('ERROR building tracks section: $e');
          print('Stack trace: $stackTrace');
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
                    'Error: $e',
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
      },
    );
  }

  Widget _buildEmptyTracksState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.music_note, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No tracks yet',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: Colors.white
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isOwner ? 'Add some tracks to get started!' : 'This playlist is empty',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (_isOwner) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => navigateTo(AppRoutes.trackSearch, arguments: widget.playlistId),
                icon: const Icon(Icons.add),
                label: const Text('Add Tracks'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary, 
                  foregroundColor: Colors.black
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrackActions(int index, PlaylistTrack playlistTrack) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.play_arrow, color: AppTheme.primary), 
          onPressed: () => _playTrackAt(index)
        ),
        if (_isOwner)
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () => _removeTrack(playlistTrack.trackId),
          ),
        const Icon(Icons.drag_handle, color: Colors.grey),
      ],
    );
  }

  void _onReorderTracks(int oldIndex, int newIndex) {
    if (!mounted) return;
    print('Reordering tracks: oldIndex=$oldIndex, newIndex=$newIndex');
    
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
      print('ERROR reordering tracks: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        showError('Failed to reorder tracks: $e');
      }
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
        setState(() {
          _tracks = musicProvider.playlistTracks;
        });
        if (_votingProvider != null) _votingProvider!.initializeTrackPoints(_tracks);
      }
    } catch (e, stackTrace) {
      print('ERROR updating track order: $e');
      print('Stack trace: $stackTrace');
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

  Future<void> _startBatchTrackDetailsFetch() async {
    if (!mounted) return;
    
    final tracksNeedingDetails = <int>[];
    for (int i = 0; i < _tracks.length; i++) {
      final track = _tracks[i].track;
      if (track?.deezerTrackId != null && 
          (track?.artist.isEmpty == true || track?.album.isEmpty == true)) tracksNeedingDetails.add(i);
    }
    
    print('Found ${tracksNeedingDetails.length} tracks needing details');
    for (int index in tracksNeedingDetails) {
      if (!mounted) break;
      final playlistTrack = _tracks[index];
      await _fetchTrackDetailsIfNeeded(playlistTrack, index);
      if (mounted && index < tracksNeedingDetails.length - 1) await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> _playPlaylist() async {
    if (_tracks.isEmpty) {
      showInfo('No tracks to play');
      return;
    }
    await _playTrackAt(0);
    showInfo('Playing "${_playlist!.name}"');
  }

  void _shufflePlaylist() {
    if (_tracks.isEmpty) {
      showInfo('No tracks to shuffle');
      return;
    }
    showInfo('Shuffling "${_playlist!.name}"');
  }

  Future<void> _playTrackAt(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    
    final track = _tracks[index].track;
    if (track?.previewUrl != null) {
      final playerService = getProvider<MusicPlayerService>();
      await playerService.playTrack(track!, track.previewUrl!);
      showSuccess('Playing "${track.name}"');
    } else showError('No preview available for this track');
  }

  Future<void> _removeTrack(String trackId) async {
    if (!_isOwner) return;
    
    final confirmed = await showConfirmDialog('Remove Track', 'Remove this track from the playlist?');
    if (confirmed) {
      await runAsyncAction(
        () async {
          final musicProvider = getProvider<MusicProvider>();
          await musicProvider.removeTrackFromPlaylist(playlistId: widget.playlistId, trackId: trackId, token: auth.token!);
          await musicProvider.fetchPlaylistTracks(widget.playlistId, auth.token!);
          setState(() => _tracks = musicProvider.playlistTracks);
        },
        successMessage: 'Track removed from playlist',
        errorMessage: 'Failed to remove track',
      );
    }
  }

  void _sharePlaylist() {
    if (_playlist != null && mounted) navigateTo(AppRoutes.playlistSharing, arguments: _playlist);
  }
}
