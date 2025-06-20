// lib/screens/playlists/playlist_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/device_provider.dart';
import '../../services/music_player_service.dart';
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

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  
  const PlaylistDetailScreen({Key? key, required this.playlistId}) : super(key: key);
  
  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends BaseScreen<PlaylistDetailScreen> {
  final _webSocketService = WebSocketService();
  
  Playlist? _playlist;
  List<PlaylistTrack> _tracks = [];
  List<String> _notifications = [];
  bool _isOwner = false;

  @override
  String get screenTitle => _playlist?.name ?? 'Playlist Details';

  @override
  List<Widget> get actions => [
    if (_isOwner) 
      IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => navigateTo(AppRoutes.playlistEditor, arguments: widget.playlistId),
        tooltip: 'Edit Playlist',
      ),
    IconButton(icon: const Icon(Icons.share), onPressed: _sharePlaylist, tooltip: 'Share Playlist'),
    IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData, tooltip: 'Refresh'),
  ];

  @override
  Widget? get floatingActionButton => _isOwner 
    ? FloatingActionButton.extended(
        onPressed: () => navigateTo(AppRoutes.trackSearch, arguments: widget.playlistId),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add Songs'),
      )
    : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    _setupWebSocket();
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
            _buildTracksSection(),
          ],
        ),
      ),
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
            child: Text(
              _notifications.last,
              style: const TextStyle(color: Colors.blue),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.blue, size: 20),
            onPressed: () => setState(() => _notifications.clear()),
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
                colors: [AppTheme.primary.withOpacity(0.8), AppTheme.primary.withOpacity(0.4)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            musicProvider.resetToCustomOrder();
                            showInfo('Restored to custom order');
                          },
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: AppTheme.primary,
                          ),
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
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isOwner 
                ? 'Add some tracks to get started!'
                : 'This playlist is empty',
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
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTracksList(List<PlaylistTrack> tracks, TrackSortOption currentSort) {
    final canReorder = currentSort.field == TrackSortField.position && _isOwner;
    
    if (canReorder) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tracks.length,
        onReorder: _onReorderTracks,
        itemBuilder: (context, index) {
          final playlistTrack = tracks[index];
          final track = playlistTrack.track;
          
          return _buildTrackItem(track, playlistTrack, index, key: ValueKey(playlistTrack.trackId));
        },
      );
    } else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final playlistTrack = tracks[index];
          final track = playlistTrack.track;
          
          return _buildTrackItem(track, playlistTrack, index);
        },
      );
    }
  }

  Widget _buildTrackItem(Track? track, PlaylistTrack playlistTrack, int index, {Key? key}) {
    if (track == null) {
      return ListTile(
        key: key,
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.music_off, color: Colors.white),
        ),
        title: Text(
          playlistTrack.name,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: const Text(
          'Track unavailable',
          style: TextStyle(color: Colors.grey),
        ),
        trailing: Text(
          '${index + 1}',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return AppWidgets.trackCard(
      key: key,
      track: track,
      onTap: () => _playTrackAt(index),
      onPlay: () => _playTrackAt(index),
      onRemove: _isOwner ? () => _removeTrack(track.id) : null,
      showAddButton: false,
    );
  }

  void _onReorderTracks(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final musicProvider = getProvider<MusicProvider>();
      final tracks = List<PlaylistTrack>.from(musicProvider.playlistTracks);
      final item = tracks.removeAt(oldIndex);
      tracks.insert(newIndex, item);
      
      for (int i = 0; i < tracks.length; i++) {
        tracks[i] = PlaylistTrack(
          trackId: tracks[i].trackId,
          name: tracks[i].name,
          position: i,
          track: tracks[i].track,
        );
      }
    });
    
    _updateTrackOrder(oldIndex, newIndex);
  }

  Future<void> _updateTrackOrder(int oldIndex, int newIndex) async {
    try {
      final musicProvider = getProvider<MusicProvider>();
      await musicProvider.moveTrackInPlaylist(playlistId: widget.playlistId, rangeStart: oldIndex, insertBefore: newIndex, token: auth.token!);
    } catch (e) {
      showError('Failed to update track order: $e');
      await _loadData(); 
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
        showInfo(isCustomOrder 
            ? 'Tracks restored to custom order'
            : 'Tracks sorted by ${sortOption.displayName}');
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

    _webSocketService.operationsStream.listen((operation) {
      if (mounted) _loadData();
    });
  }

  Future<void> _loadData() async {
    print('Loading playlist data for ID: ${widget.playlistId}');
    
    setState(() {});
    
    try {
      final musicProvider = getProvider<MusicProvider>();
      
      print('Fetching playlist details...'); 
      final playlist = await musicProvider.getPlaylistDetails(widget.playlistId, auth.token!);
      print('Playlist loaded: ${playlist?.name ?? 'null'}'); 
      
      if (playlist != null) {
        setState(() {
          _playlist = playlist;
          _isOwner = _playlist!.creator == auth.username;
        });
        
        print('Is owner: $_isOwner, Creator: ${_playlist!.creator}, Username: ${auth.username}'); 
        
        print('Fetching playlist tracks...'); 
        await musicProvider.fetchPlaylistTracks(widget.playlistId, auth.token!);
        
        setState(() {
          _tracks = musicProvider.playlistTracks;
        });
        
        print('Tracks loaded: ${_tracks.length}'); 
        
        if (_webSocketService.currentPlaylistId != widget.playlistId) {
          print('Connecting to WebSocket...'); 
          await _webSocketService.connectToPlaylist(widget.playlistId, auth.userId!, auth.token!);
        }
      } else {
        print('Playlist is null after loading!'); 
        showError('Failed to load playlist data');
      }
      
      print('Load data completed. Playlist: ${_playlist?.name}, Tracks: ${_tracks.length}'); 
    } catch (e) {
      print('Error loading data: $e');
      showError('Failed to load playlist details: $e');
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

  Future<void> _shufflePlaylist() async {
    if (_tracks.isEmpty) {
      showInfo('No tracks to shuffle');
      return;
    }
    showInfo('Shuffling "${_playlist!.name}"');
  }

  Future<void> _playTrackAt(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    
    final track = _tracks[index].track;
    if (track == null) {
      showError('Track is not available');
      return;
    }

    try {
      final playerService = getProvider<MusicPlayerService>();
      
      String? previewUrl = track.previewUrl;
      if (previewUrl == null && track.deezerTrackId != null) {
        final musicProvider = getProvider<MusicProvider>();
        previewUrl = await musicProvider.getDeezerTrackPreviewUrl(track.deezerTrackId!);
      }
      
      if (previewUrl != null && previewUrl.isNotEmpty) {
        await playerService.playTrack(track, previewUrl);
        showSuccess('Playing "${track.name}"');
      } else {
        showInfo('No preview available for "${track.name}"');
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
          await musicProvider.removeTrackFromPlaylist(playlistId: widget.playlistId, trackId: trackId, token: auth.token!);
          await _loadData(); 
        },
        successMessage: 'Track removed from playlist',
        errorMessage: 'Failed to remove track',
      );
    }
  }

  void _sharePlaylist() {
    if (_playlist != null) navigateTo(AppRoutes.playlistSharing, arguments: _playlist);
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    super.dispose();
  }
}
