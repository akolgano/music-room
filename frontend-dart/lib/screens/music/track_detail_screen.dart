// lib/screens/music/track_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/dynamic_theme_provider.dart';
import '../../services/music_player_service.dart';
import '../../models/models.dart';
import '../../core/core.dart';
import '../../widgets/widgets.dart';
import '../base_screen.dart';

class TrackDetailScreen extends StatefulWidget {
  final String? trackId;
  final Track? track;
  final String? playlistId; 
  
  const TrackDetailScreen({Key? key, this.trackId, this.track, this.playlistId}) : super(key: key);
  
  @override
  State<TrackDetailScreen> createState() => _TrackDetailScreenState();
}

class _TrackDetailScreenState extends BaseScreen<TrackDetailScreen> {
  Track? _track;
  bool _isInPlaylist = false;
  List<Playlist> _userPlaylists = [];
  bool _isAddingToBackend = false;

  @override
  String get screenTitle => _track?.name ?? 'Track Details';

  @override
  List<Widget> get actions => [
    if (_track != null) ...[
      IconButton(icon: const Icon(Icons.share), onPressed: _shareTrack, tooltip: 'Share Track'),
      PopupMenuButton<String>(
        onSelected: _handleMenuAction,
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'add_to_playlist',
            child: Row(children: [Icon(Icons.playlist_add, size: 16), SizedBox(width: 8), Text('Add to Playlist')]),
          ),
          if (_track!.deezerTrackId != null)
            const PopupMenuItem(
              value: 'add_to_library',
              child: Row(
                children: [Icon(Icons.library_add, size: 16), SizedBox(width: 8), Text('Add to Library')],
              ),
            ),
          const PopupMenuItem(
            value: 'add_to_backend',
            child: Row(
              children: [Icon(Icons.cloud_upload, size: 16), SizedBox(width: 8), Text('Add to Backend Database')],
            ),
          ),
        ],
      ),
    ],
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  Widget buildContent() {
    if (_track == null) return buildLoadingState(message: 'Loading track details...');

    return Consumer<DynamicThemeProvider>(
      builder: (context, themeProvider, _) {
        return RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_isAddingToBackend) _buildBackendAddingIndicator(),
                _buildTrackHeader(themeProvider),
                const SizedBox(height: 24),
                _buildTrackActions(),
                const SizedBox(height: 24),
                _buildTrackInfo(),
                const SizedBox(height: 24),
                _buildPlaylistActions(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackendAddingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Adding track to backend database...',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackHeader(DynamicThemeProvider themeProvider) {
    return AppTheme.buildHeaderCard(
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: themeProvider.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _track!.imageUrl?.isNotEmpty == true
                ? CachedNetworkImage(
                    imageUrl: _track!.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: themeProvider.surfaceColor,
                      child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: themeProvider.surfaceColor,
                      child: const Icon(Icons.music_note, size: 80, color: Colors.white),
                    ),
                  )
                : Container(
                    color: themeProvider.surfaceColor,
                    child: const Icon(Icons.music_note, size: 80, color: Colors.white),
                  ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _track!.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _track!.artist,
            style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
          if (_track!.album.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _track!.album,
              style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackActions() {
    return Consumer<MusicPlayerService>(
      builder: (context, playerService, _) {
        final isCurrentTrack = playerService.currentTrack?.id == _track!.id;
        final isPlaying = isCurrentTrack && playerService.isPlaying;
        
        return Card(
          color: AppTheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: isPlaying ? Icons.pause : Icons.play_arrow,
                      label: isPlaying ? 'Pause' : 'Play',
                      onPressed: _playPauseTrack,
                      isPrimary: true,
                    ),
                    _buildActionButton(
                      icon: Icons.playlist_add,
                      label: 'Add to Playlist',
                      onPressed: _showAddToPlaylistDialog,
                    ),
                    if (_track!.deezerTrackId != null)
                      _buildActionButton(
                        icon: Icons.library_add,
                        label: 'Add to Library',
                        onPressed: _addToLibrary,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_track!.deezerTrackId != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isAddingToBackend ? null : _addToBackendDatabase,
                      icon: _isAddingToBackend 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.cloud_upload),
                      label: Text(_isAddingToBackend ? 'Adding to Database...' : 'Add to Backend Database'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
                if (isCurrentTrack && playerService.duration.inSeconds > 0) ...[
                  const SizedBox(height: 20),
                  _buildProgressBar(playerService),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isPrimary ? AppTheme.primary : AppTheme.surfaceVariant,
            shape: BoxShape.circle,
            boxShadow: [
              if (isPrimary)
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: isPrimary ? Colors.black : Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressBar(MusicPlayerService playerService) {
    return Column(
      children: [
        Slider(
          value: playerService.position.inSeconds.toDouble(),
          max: playerService.duration.inSeconds.toDouble(),
          onChanged: (value) {
            playerService.seek(Duration(seconds: value.toInt()));
          },
          activeColor: AppTheme.primary,
          inactiveColor: Colors.grey,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateTimeUtils.formatDuration(playerService.position),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                DateTimeUtils.formatDuration(playerService.duration),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackInfo() {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Track Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Artist', _track!.artist),
            if (_track!.album.isNotEmpty) _buildInfoRow('Album', _track!.album),
            _buildInfoRow('Track ID', _track!.id),
            if (_track!.deezerTrackId != null)
              _buildInfoRow('Deezer ID', _track!.deezerTrackId!),
            if (_track!.previewUrl != null)
              _buildInfoRow('Preview', 'Available', 
                trailing: const Icon(Icons.play_circle, color: Colors.green, size: 16)),
            if (_track!.url.isNotEmpty)
              _buildInfoRow('Source URL', 'Available', 
                trailing: const Icon(Icons.link, color: AppTheme.primary, size: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildPlaylistActions() {
    if (widget.playlistId == null) return const SizedBox.shrink();
    
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.playlist_play, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Playlist Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isInPlaylist) ...[
              AppWidgets.infoBanner(
                title: 'In Playlist',
                message: 'This track is already in the current playlist',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _removeFromPlaylist,
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Remove from Playlist'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addToCurrentPlaylist,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add to Current Playlist'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadData() async {
    await runAsyncAction(
      () async {
        if (widget.track != null) {
          _track = widget.track;
        } else if (widget.trackId != null) {
          final musicProvider = getProvider<MusicProvider>();
          if (widget.trackId!.startsWith('deezer_')) {
            _track = await musicProvider.getDeezerTrack(widget.trackId!);
          } else {
            _track = musicProvider.getTrackById(widget.trackId!);
          }
        }

        if (_track != null && widget.playlistId != null) {
          final musicProvider = getProvider<MusicProvider>();
          await musicProvider.fetchPlaylistTracks(widget.playlistId!, auth.token!);
          _isInPlaylist = musicProvider.isTrackInPlaylist(_track!.id);
        }

        final musicProvider = getProvider<MusicProvider>();
        await musicProvider.fetchUserPlaylists(auth.token!);
        _userPlaylists = musicProvider.playlists;

        final themeProvider = getProvider<DynamicThemeProvider>();
        if (_track?.imageUrl != null) {
          themeProvider.extractAndApplyDominantColor(_track!.imageUrl);
        }
      },
      errorMessage: 'Failed to load track details',
    );
  }

  Future<void> _playPauseTrack() async {
    if (_track == null) return;

    try {
      final playerService = getProvider<MusicPlayerService>();
      
      if (playerService.currentTrack?.id == _track!.id) {
        await playerService.togglePlay();
        return;
      }

      String? previewUrl = _track!.previewUrl;
      if (previewUrl == null && _track!.deezerTrackId != null) {
        final musicProvider = getProvider<MusicProvider>();
        previewUrl = await musicProvider.getDeezerTrackPreviewUrl(_track!.deezerTrackId!);
      }

      if (previewUrl != null && previewUrl.isNotEmpty) {
        await playerService.playTrack(_track!, previewUrl);
        showSuccess('Playing "${_track!.name}"');
      } else {
        showError('No preview available for this track');
      }
    } catch (e) {
      showError('Failed to play track: $e');
    }
  }

  Future<void> _addToBackendDatabase() async {
    if (_track?.deezerTrackId == null) {
      showError('Cannot add non-Deezer track to backend database');
      return;
    }

    setState(() => _isAddingToBackend = true);

    try {
      print('Adding track ${_track!.name} (ID: ${_track!.deezerTrackId}) to backend database...');
      
      final musicProvider = getProvider<MusicProvider>();
      await musicProvider.addSingleTrackFromDeezerToTracks(_track!.deezerTrackId!, auth.token!);
      
      showSuccess('✓ Added "${_track!.name}" to backend database!');
      print('Successfully added ${_track!.name} to backend database');
    } catch (e) {
      showError('Failed to add track to backend database: $e');
      print('Error adding ${_track!.name} to backend database: $e');
    } finally {
      setState(() => _isAddingToBackend = false);
    }
  }

  Future<void> _addToLibrary() async {
    if (_track?.deezerTrackId == null) {
      showError('Cannot add non-Deezer track to library');
      return;
    }

    await runAsyncAction(
      () async {
        final musicProvider = getProvider<MusicProvider>();
        await musicProvider.addTrackFromDeezer(_track!.deezerTrackId!, auth.token!);
      },
      successMessage: 'Added "${_track!.name}" to your library!',
      errorMessage: 'Failed to add track to library',
    );
  }

  Future<void> _addToCurrentPlaylist() async {
    if (widget.playlistId == null || _track == null) return;

    await runAsyncAction(
      () async {
        final musicProvider = getProvider<MusicProvider>();
        final deviceProvider = getProvider<DeviceProvider>();
        
        print('Adding track ${_track!.name} to current playlist...');
        
        final result = await musicProvider.addTrackToPlaylist(widget.playlistId!, _track!.id, auth.token!);

        if (result.success) {
          _isInPlaylist = true;
          print('Successfully added ${_track!.name} to playlist');
        } else {
          throw Exception(result.message);
        }
      },
      successMessage: 'Added "${_track!.name}" to playlist!',
      errorMessage: 'Failed to add track to playlist',
    );
  }

  Future<void> _removeFromPlaylist() async {
    if (widget.playlistId == null || _track == null) return;

    final confirmed = await showConfirmDialog(
      'Remove Track',
      'Remove "${_track!.name}" from this playlist?',
    );

    if (confirmed) {
      await runAsyncAction(
        () async {
          final musicProvider = getProvider<MusicProvider>();
          await musicProvider.removeTrackFromPlaylist(playlistId: widget.playlistId!, trackId: _track!.id, token: auth.token!);
          _isInPlaylist = false;
        },
        successMessage: 'Removed "${_track!.name}" from playlist',
        errorMessage: 'Failed to remove track from playlist',
      );
    }
  }

  void _showAddToPlaylistDialog() {
    if (_userPlaylists.isEmpty) {
      showError('No playlists available. Create a playlist first.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _userPlaylists.length,
            itemBuilder: (context, index) {
              final playlist = _userPlaylists[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.library_music, color: AppTheme.primary),
                ),
                title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text('${playlist.tracks.length} tracks', style: const TextStyle(color: Colors.grey)),
                onTap: () {
                  Navigator.pop(context);
                  _addToPlaylist(playlist.id);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Future<void> _addToPlaylist(String playlistId) async {
    if (_track == null) return;

    await runAsyncAction(
      () async {
        final musicProvider = getProvider<MusicProvider>();
        final deviceProvider = getProvider<DeviceProvider>();
        print('Adding track ${_track!.name} to playlist $playlistId...');
        final result = await musicProvider.addTrackToPlaylist(playlistId, _track!.id, auth.token!);
        if (!result.success) throw Exception(result.message);
        print('Successfully added ${_track!.name} to playlist');
      },
      successMessage: 'Added "${_track!.name}" to playlist!',
      errorMessage: 'Failed to add track to playlist',
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'add_to_playlist':
        _showAddToPlaylistDialog();
        break;
      case 'add_to_library':
        _addToLibrary();
        break;
      case 'add_to_backend':
        _addToBackendDatabase();
        break;
    }
  }

  void _shareTrack() {
    if (_track != null) showInfo('Sharing "${_track!.name}" by ${_track!.artist}');
  }
}
