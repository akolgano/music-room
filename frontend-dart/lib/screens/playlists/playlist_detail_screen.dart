// lib/screens/playlists/playlist_detail_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'playlist_licensing_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
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
import '../../services/websocket_service.dart';
import '../base_screen.dart';
import '../../providers/voting_provider.dart';
import '../../widgets/voting_widgets.dart';
import '../../models/voting_models.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  const PlaylistDetailScreen({Key? key, required this.playlistId}) : super(key: key);
  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends BaseScreen<PlaylistDetailScreen> {
  final _webSocketService = WebSocketService();
  late final ApiService _apiService;
  final Set<String> _fetchingTrackDetails = {};
  final Set<Completer<void>> _pendingOperations = {};
  Playlist? _playlist;
  List<PlaylistTrack> _tracks = [];
  List<String> _notifications = [];
  bool _isOwner = false;
  VotingProvider? _votingProvider;

  @override
  String get screenTitle => _playlist?.name ?? 'Playlist Details';

  @override
  void initState() {
    super.initState();
    _apiService = getIt<ApiService>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _setupWebSocket();
  }

  @override
  void dispose() {
    _cancelPendingOperations();
    _webSocketService.disconnect();
    final votingProvider = getProvider<VotingProvider>(listen: false);
    votingProvider.clearVotingData();
    super.dispose();
  }

  void _cancelPendingOperations() {
    for (final completer in _pendingOperations) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _pendingOperations.clear();
    _fetchingTrackDetails.clear();
  }

  @override
  List<Widget> get actions => [
    if (_isOwner)
      IconButton(
        icon: const Icon(Icons.settings), 
        onPressed: _openPlaylistSettings, 
        tooltip: 'Playlist Settings'
      ),
    IconButton(
      icon: const Icon(Icons.share), 
      onPressed: _sharePlaylist, 
      tooltip: 'Share Playlist'
    ),
    IconButton(
      icon: const Icon(Icons.refresh), 
      onPressed: _loadData, 
      tooltip: 'Refresh'
    ),
  ];

  void _openPlaylistSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistLicensingScreen(
          playlistId: widget.playlistId, 
          playlistName: _playlist?.name ?? 'Playlist'
        ),
      ),
    ).then((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    try {
      print('Loading playlist data with ID: ${widget.playlistId}');
      final musicProvider = getProvider<MusicProvider>();
      final votingProvider = getProvider<VotingProvider>();
      final playlist = await musicProvider.getPlaylistDetails(widget.playlistId, auth.token!);
      if (!mounted) return;
      if (playlist != null) {
        setState(() {
          _playlist = playlist;
          _isOwner = _playlist!.creator == auth.username;
        });
        await Future.wait([
          musicProvider.fetchPlaylistTracks(widget.playlistId, auth.token!)
        ]);
        if (!mounted) return;
        votingProvider.setVotingPermission(true);
        setState(() => _tracks = musicProvider.playlistTracks);
        votingProvider.initializeTrackPoints(_tracks);
        _initializeVotingData(votingProvider); 
        _startBatchTrackDetailsFetch();
        if (_webSocketService.currentPlaylistId != widget.playlistId) {
          await _webSocketService.connectToPlaylist(widget.playlistId, auth.userId!, auth.token!);
        }
        print('Playlist data loaded successfully');
      } else {
        if (mounted) {
          showError('Failed to load playlist data');
        }
      }
    } catch (e, stackTrace) {
      print('ERROR loading playlist data: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        showError('Failed to load playlist details: $e');
      }
    }
  }

  void _initializeVotingData(VotingProvider votingProvider) {
    votingProvider.clearVotingData();
  }

  Future<void> _enableOpenVoting() async {
    await runAsyncAction(
      () async {
        print('Enabling open voting for playlist ${widget.playlistId}');
        final request = PlaylistLicenseRequest(
          licenseType: 'open', 
          invitedUsers: null, 
          voteStartTime: null,
          voteEndTime: null, 
          latitude: null, 
          longitude: null, 
          allowedRadiusMeters: null,
        );
        await _apiService.updatePlaylistLicense(widget.playlistId, 'Token ${auth.token!}', request);
        if (mounted) await _loadData();
      },
      successMessage: 'Voting enabled for all users!',
      errorMessage: 'Failed to enable voting',
    );
  }

  Future<void> _fetchTrackDetailsIfNeeded(PlaylistTrack playlistTrack) async {
    final deezerTrackId = playlistTrack.track?.deezerTrackId;
    if (deezerTrackId == null || 
        _fetchingTrackDetails.contains(deezerTrackId) || 
        !mounted) {
      return;
    }
    print('Fetching track details for Deezer ID: $deezerTrackId');
    _fetchingTrackDetails.add(deezerTrackId);
    final completer = Completer<void>();
    _pendingOperations.add(completer);
    try {
      final trackDetails = await _apiService.getDeezerTrack(deezerTrackId, auth.token!);
      if (!mounted || completer.isCompleted) {
        return;
      }
      if (trackDetails != null) {
        print('Successfully fetched track details: ${trackDetails.name}');
        setState(() {
          final trackIndex = _tracks.indexWhere((t) => t.trackId == playlistTrack.trackId);
          if (trackIndex != -1) {
            _tracks[trackIndex] = PlaylistTrack(
              trackId: playlistTrack.trackId, 
              name: playlistTrack.name, 
              position: playlistTrack.position, 
              points: playlistTrack.points, track: trackDetails
            );
          }
        });
        if (mounted) {
          final musicProvider = getProvider<MusicProvider>();
          final providerTracks = List<PlaylistTrack>.from(musicProvider.playlistTracks);
          final providerIndex = providerTracks.indexWhere((t) => t.trackId == playlistTrack.trackId);
          if (providerIndex != -1) {
            providerTracks[providerIndex] = PlaylistTrack(
              trackId: playlistTrack.trackId, 
              name: playlistTrack.name, 
              position: playlistTrack.position, 
              points: playlistTrack.points, track: trackDetails
            );
            musicProvider.playlistTracks.clear();
            musicProvider.playlistTracks.addAll(providerTracks);
            musicProvider.notifyListeners();
          }
        }
      }
    } catch (e, stackTrace) {
      print('ERROR fetching track details for $deezerTrackId: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        print('Failed to fetch track details for $deezerTrackId: $e');
      }
    } finally {
      if (mounted) {
        _fetchingTrackDetails.remove(deezerTrackId);
        _pendingOperations.remove(completer);
      }
      if (!completer.isCompleted) {
        completer.complete();
      }
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
              child: Text(
                'Error loading track at position $index',
                style: const TextStyle(color: Colors.red),
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
            print('ERROR building track item at index $index: $e');
            print('Stack trace: $stackTrace');
            
            return Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error loading track at position $index',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
        },
      );
    }
  }

  Widget _buildTrackItem(PlaylistTrack playlistTrack, int index, {Key? key}) {
    try {
      final track = playlistTrack.track;
      
      print('Building track item for index $index, trackId: ${playlistTrack.trackId}, key: $key');
      
      if (track?.deezerTrackId != null && playlistTrack.needsTrackDetails && mounted) {
        _fetchTrackDetailsIfNeeded(playlistTrack);
      }

      if (track?.deezerTrackId != null && 
          _fetchingTrackDetails.contains(track!.deezerTrackId) && 
          (track.artist.isEmpty || track.album.isEmpty)) {
        
        print('Showing loading state for track at index $index');
        
        return Container(
          key: key, 
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surface, 
            borderRadius: BorderRadius.circular(12)
          ),
          child: ListTile(
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3), 
                borderRadius: BorderRadius.circular(8)
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.music_note, color: Colors.white),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                  ),
                ],
              ),
            ),
            title: Text(
              track?.name ?? playlistTrack.name,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Loading track details...',
              style: TextStyle(color: Colors.grey),
            ),
            trailing: _buildTrackActions(index, playlistTrack),
          ),
        );
      }

      if (track != null) {
        print('Showing normal track card for index $index');
        
        return AppWidgets.playlistTrackCard(
          key: key, 
          playlistTrack: playlistTrack,
          onTap: () => _playTrackAt(index),
          onPlay: () => _playTrackAt(index),
          onRemove: _isOwner ? () => _removeTrack(track.id) : null,
          showVotingControls: true, 
          showPoints: true, 
          playlistId: widget.playlistId,
          trackIndex: index, 
        );
      }

      print('Showing error state for track at index $index');
      
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
              color: Colors.red.withOpacity(0.3), 
              borderRadius: BorderRadius.circular(8)
            ),
            child: const Icon(Icons.music_off, color: Colors.white),
          ),
          title: Text(playlistTrack.name, style: const TextStyle(color: Colors.white)),
          subtitle: const Text(
            'Track details unavailable',
            style: TextStyle(color: Colors.grey),
          ),
          trailing: _buildTrackActions(index, playlistTrack),
        ),
      );
    } catch (e, stackTrace) {
      print('ERROR in _buildTrackItem for index $index: $e');
      print('Stack trace: $stackTrace');
      
      return Container(
        key: key,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Error loading track at position $index',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Track ID: ${playlistTrack.trackId}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              'Error: $e',
              style: const TextStyle(color: Colors.red, fontSize: 10),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildVotingSection() {
    return Consumer<VotingProvider>(
      builder: (context, votingProvider, _) {
        final trackVotes = votingProvider.trackVotes;
        if (!votingProvider.canVote && _isOwner) {
          return Card(
            color: AppTheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.how_to_vote, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text('Voting Not Enabled',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Allow users to vote on tracks in this playlist to create collaborative rankings.',
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _enableOpenVoting,
                          icon: const Icon(Icons.public),
                          label: const Text('Enable Public Voting'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openPlaylistSettings,
                          icon: const Icon(Icons.settings),
                          label: const Text('Advanced Settings'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            if (votingProvider.canVote) 
              PlaylistVotingBanner(playlistId: widget.playlistId),
            if (_tracks.isNotEmpty) ...[
              Card(
                color: AppTheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.poll, color: AppTheme.primary, size: 20), 
                          SizedBox(width: 8),
                          Text(
                            'Track Ratings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPointsStat('Total Points', _getTotalPoints()),
                          _buildPointsStat('Top Track', _getTopTrackPoints()),
                          _buildPointsStat('Tracks Voted', _getVotedTracksCount()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (trackVotes.isNotEmpty) VotingStatsCard(trackVotes: trackVotes),
          ],
        );
      },
    );
  }

  Widget _buildPointsStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
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
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_notifications.isNotEmpty) _buildNotificationBar(),
            _buildPlaylistHeader(),
            const SizedBox(height: 16),
            _buildPlaylistStats(),
            const SizedBox(height: 16),
            _buildPlaylistActions(),
            const SizedBox(height: 16),
            _buildVotingSection(),
            const SizedBox(height: 16), 
            _buildTracksSection(),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshAfterVoting() async {
    if (!mounted) return;
    try {
      final musicProvider = getProvider<MusicProvider>();
      final votingProvider = getProvider<VotingProvider>();
      await musicProvider.fetchPlaylistTracks(widget.playlistId, auth.token!);
      if (mounted) {
        setState(() {
          _tracks = musicProvider.playlistTracks;
        });
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
      onPressed: () => navigateTo(AppRoutes.trackSearch, arguments: widget.playlistId),
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.add),
      label: const Text('Add Songs'),
    );
  }

  Widget _buildNotificationBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_notifications.last, style: const TextStyle(color: Colors.blue))
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.blue, size: 20),
            onPressed: () {
              if (mounted) {
                setState(() => _notifications.clear());
              }
            },
          ),
        ],
      ),
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
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                      const Row(
                        children: [
                          Icon(Icons.queue_music, color: AppTheme.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Tracks',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
                            child: const Icon(Icons.close, size: 14, color: AppTheme.primary),
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
          showInfo(isCustomOrder 
            ? 'Tracks restored to custom order' 
            : 'Tracks sorted by ${sortOption.displayName}'
          );
        }
      },
    );
  }

  void _setupWebSocket() {
    _webSocketService.notificationsStream.listen((notification) {
      if (mounted) {
        setState(() {
          _notifications.add(notification);
          if (_notifications.length > 3) _notifications.removeAt(0);
        });
      }
    });
  }

  Future<void> _startBatchTrackDetailsFetch() async {
    if (!mounted) return;
    final tracksNeedingDetails = _tracks.where((pt) => pt.needsTrackDetails).toList();
    if (tracksNeedingDetails.isEmpty) return;
    for (int i = 0; i < tracksNeedingDetails.length; i++) {
      if (!mounted) break; 
      final playlistTrack = tracksNeedingDetails[i];
      _fetchTrackDetailsIfNeeded(playlistTrack);
      if (i < tracksNeedingDetails.length - 1 && mounted) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  Future<void> _playPlaylist() async {
    if (_tracks.isEmpty) {
      if (mounted) showInfo('No tracks to play');
      return;
    }
    await _playTrackAt(0);
    if (mounted) showInfo('Playing "${_playlist!.name}"');
  }

  Future<void> _shufflePlaylist() async {
    if (_tracks.isEmpty) {
      if (mounted) showInfo('No tracks to shuffle');
      return;
    }
    if (mounted) showInfo('Shuffling "${_playlist!.name}"');
  }

  Future<void> _playTrackAt(int index) async {
    if (index < 0 || index >= _tracks.length || !mounted) return;
    final playlistTrack = _tracks[index];
    final track = playlistTrack.track;
    try {
      String? previewUrl;
      Track trackToPlay;
      if (track != null) {
        trackToPlay = track;
        previewUrl = track.previewUrl;
        if (previewUrl == null && track.deezerTrackId != null) {
          final fullTrackDetails = await _apiService.getDeezerTrack(track.deezerTrackId!, auth.token!);
          if (fullTrackDetails?.previewUrl != null) previewUrl = fullTrackDetails!.previewUrl;
        }
      } else {
        trackToPlay = Track(id: playlistTrack.trackId, name: playlistTrack.name, artist: 'Unknown Artist', album: '', url: '');
      }
      if (!mounted) return;
      if (previewUrl != null && previewUrl.isNotEmpty) {
        final playerService = getProvider<MusicPlayerService>();
        await playerService.playTrack(trackToPlay, previewUrl);
        showSuccess('Playing "${playlistTrack.name}"');
      } else {
        showError('No preview available for "${playlistTrack.name}"');
      }
    } catch (e, stackTrace) {
      print('ERROR playing track at index $index: $e');
      print('Stack trace: $stackTrace');
      if (mounted) showError('Failed to play track: $e');
    }
  }

  Future<void> _removeTrack(String trackId) async {
    if (!_isOwner || !mounted) return;
    final confirmed = await showConfirmDialog(
      'Remove Track', 
      'Remove this track from the playlist?'
    );
    if (confirmed && mounted) {
      await runAsyncAction(
        () async {
          final musicProvider = getProvider<MusicProvider>();
          await musicProvider.removeTrackFromPlaylist(playlistId: widget.playlistId, trackId: trackId, token: auth.token!);
          if (mounted) await _loadData(); 
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
