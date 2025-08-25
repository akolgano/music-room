import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:async';
import '../../providers/music_providers.dart';
import '../../core/locator_core.dart';
import '../../providers/auth_providers.dart';
import 'package:provider/provider.dart';
import '../../services/websocket_services.dart';
import '../../models/music_models.dart';
import '../../core/theme_core.dart';
import '../../widgets/app_widgets.dart';

class PlaylistCollaborativeEditor extends StatefulWidget {
  final String playlistId;
  final Playlist playlist;
  final Function(List<Track>) onTracksUpdated;
  final Function(String) onError;
  final Function(String) onSuccess;
  final Function(String) onInfo;

  const PlaylistCollaborativeEditor({
    super.key,
    required this.playlistId,
    required this.playlist,
    required this.onTracksUpdated,
    required this.onError,
    required this.onSuccess,
    required this.onInfo,
  });

  @override
  State<PlaylistCollaborativeEditor> createState() => _PlaylistCollaborativeEditorState();
}

class _PlaylistCollaborativeEditorState extends State<PlaylistCollaborativeEditor> {
  List<Track> _playlistTracks = [];
  final List<CollaboratorInfo> _activeCollaborators = [];
  final List<RecentEdit> _recentEdits = [];
  
  StreamSubscription? _wsSubscription;

  bool get _canEdit => widget.playlist.canEdit(auth.username);

  AuthProvider get auth => Provider.of<AuthProvider>(context, listen: false);
  
  T getProvider<T>() => Provider.of<T>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _playlistTracks = List.from(widget.playlist.tracks);
    _initializeWebSocket();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildEditorHeader(),
        if (_activeCollaborators.isNotEmpty) _buildActiveCollaborators(),
        Expanded(child: _buildTracksList()),
        if (_canEdit) _buildEditorActions(),
      ],
    );
  }

  Widget _buildEditorHeader() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.playlist.isPublic ? Icons.public : Icons.lock,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.playlist.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!_canEdit)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'View Only',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (widget.playlist.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.playlist.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.music_note, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${_playlistTracks.length} tracks',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 16),
              Icon(Icons.people, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${_activeCollaborators.length + 1} collaborators',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCollaborators() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, color: Colors.green, size: 12),
          const SizedBox(width: 8),
          const Text(
            'Active now:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _activeCollaborators.length,
              itemBuilder: (context, index) {
                final collaborator = _activeCollaborators[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Chip(
                    avatar: CircleAvatar(
                      backgroundColor: collaborator.color,
                      child: Text(
                        collaborator.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    label: Text(collaborator.name),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTracksList() {
    if (_playlistTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.queue_music,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tracks yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _canEdit 
                ? 'Add the first track to get started!'
                : 'This playlist is empty',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(4),
      itemCount: _playlistTracks.length,
      itemBuilder: (context, index) {
        final track = _playlistTracks[index];
        return _buildTrackCard(track, index, key: ValueKey(track.id));
      },
    );
  }

  Widget _buildTrackCard(Track track, int index, {required Key key}) {
    final recentEdit = _recentEdits.where((edit) => edit.trackId == track.id).firstOrNull;
    final showEditIndicator = recentEdit != null && 
        DateTime.now().difference(recentEdit.timestamp).inSeconds < 5;

    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 6),
      elevation: showEditIndicator ? 4 : 1,
      color: showEditIndicator 
        ? Colors.blue.withValues(alpha: 0.1) 
        : null,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: track.imageUrl != null 
            ? Image.network(
                track.imageUrl!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultAlbumArt(),
              )
            : _buildDefaultAlbumArt(),
        ),
        title: Text(
          track.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(track.artist),
            if (showEditIndicator)
              Text(
                'Recently ${recentEdit.action} by ${recentEdit.userName}',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: _canEdit 
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (index > 0)
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up),
                    onPressed: () => _moveTrack(index, index - 1),
                    tooltip: 'Move up',
                  ),
                if (index < _playlistTracks.length - 1)
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: () => _moveTrack(index, index + 1),
                    tooltip: 'Move down',
                  ),
                PopupMenuButton<String>(
                  onSelected: (action) => _handleTrackAction(action, track, index),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'play',
                      child: ListTile(
                        leading: Icon(Icons.play_arrow),
                        title: Text('Play'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: ListTile(
                        leading: Icon(Icons.remove, color: Colors.red),
                        title: Text('Remove', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _playTrack(track),
            ),
      ),
    );
  }

  Widget _buildDefaultAlbumArt() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.music_note,
        color: AppTheme.primary,
        size: 25,
      ),
    );
  }

  Widget _buildEditorActions() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppWidgets.primaryButton(
              context: context,
              text: 'Add Track',
              icon: Icons.add,
              onPressed: _addTrackToPlaylist,
              isLoading: false,
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _clearPlaylist,
            icon: const Icon(Icons.clear_all, color: Colors.red),
            label: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeWebSocket() async {
    try {
      getIt<WebSocketService>();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('WebSocket connection failed: ${e.toString()}');
      }
    }
  }

  Future<void> _addTrackToPlaylist() async {
    final selectedTrack = await Navigator.pushNamed(
      context, 
      '/track-search',
      arguments: {'selectMode': true},
    ) as Track?;

    if (selectedTrack != null) {
      try {
        final musicProvider = getProvider<MusicProvider>();
        await musicProvider.addTrackToPlaylist(
          widget.playlistId, 
          selectedTrack.id, 
          auth.token!,
        );

        setState(() {
          _playlistTracks.add(selectedTrack);
          _recentEdits.add(RecentEdit(
            trackId: selectedTrack.id,
            action: 'added',
            userName: 'You',
            timestamp: DateTime.now(),
          ));
        });

        widget.onTracksUpdated(_playlistTracks);
        widget.onSuccess('Track added to playlist!');
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to add track: $e');
        }
        widget.onError('Failed to add track: ${e.toString()}');
      }
    }
  }

  Future<void> _moveTrack(int fromIndex, int toIndex) async {
    if (fromIndex == toIndex || fromIndex < 0 || toIndex < 0 || 
        fromIndex >= _playlistTracks.length || toIndex >= _playlistTracks.length) {
      return;
    }

    final track = _playlistTracks.removeAt(fromIndex);
    _playlistTracks.insert(toIndex, track);

    setState(() {});
    widget.onTracksUpdated(_playlistTracks);

    try {
      final musicProvider = getProvider<MusicProvider>();
      await musicProvider.moveTrackInPlaylist(
        playlistId: widget.playlistId, 
        rangeStart: fromIndex, 
        insertBefore: toIndex,
        token: auth.token!,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to save track order: $e');
      }
      widget.onError('Failed to save track order: ${e.toString()}');
      
      final restoredTrack = _playlistTracks.removeAt(toIndex);
      _playlistTracks.insert(fromIndex, restoredTrack);
      setState(() {});
      widget.onTracksUpdated(_playlistTracks);
    }
  }

  void _handleTrackAction(String action, Track track, int index) {
    switch (action) {
      case 'play':
        _playTrack(track);
        break;
      case 'remove':
        _removeTrack(track, index);
        break;
    }
  }

  void _playTrack(Track track) {
    widget.onInfo('Playing: ${track.name}');
  }

  Future<void> _removeTrack(Track track, int index) async {
    try {
      final musicProvider = getProvider<MusicProvider>();
      await musicProvider.removeTrackFromPlaylist(
        playlistId: widget.playlistId,
        trackId: track.id,
        token: auth.token!,
      );

      setState(() {
        _playlistTracks.removeAt(index);
        _recentEdits.add(RecentEdit(
          trackId: track.id,
          action: 'removed',
          userName: 'You',
          timestamp: DateTime.now(),
        ));
      });

      widget.onTracksUpdated(_playlistTracks);
      widget.onSuccess('Track removed from playlist!');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to remove track: $e');
      }
      widget.onError('Failed to remove track: ${e.toString()}');
    }
  }

  Future<void> _clearPlaylist() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Playlist'),
        content: const Text('Are you sure you want to remove all tracks from this playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        getProvider<MusicProvider>();
        setState(() {
          _playlistTracks.clear();
        });

        widget.onTracksUpdated(_playlistTracks);
        widget.onSuccess('Playlist cleared!');
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to clear playlist: $e');
        }
        widget.onError('Failed to clear playlist: ${e.toString()}');
      }
    }
  }

  void showCollaborators() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Collaborators'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _activeCollaborators.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.primary,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(auth.username ?? 'You'),
                  subtitle: const Text('Host'),
                  trailing: const Icon(Icons.star, color: Colors.orange),
                );
              }
              
              final collaborator = _activeCollaborators[index - 1];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: collaborator.color,
                  child: Text(
                    collaborator.initials,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(collaborator.name),
                subtitle: const Text('Collaborator'),
                trailing: const Icon(Icons.circle, color: Colors.green, size: 12),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }
}

class CollaboratorInfo {
  final String userId;
  final String name;
  final Color color;
  final DateTime joinedAt;
  
  String get initials => name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase();

  const CollaboratorInfo({
    required this.userId,
    required this.name,
    required this.color,
    required this.joinedAt,
  });

  factory CollaboratorInfo.fromJson(Map<String, dynamic> json) => CollaboratorInfo(
    userId: json['user_id'] as String,
    name: json['name'] as String,
    color: Color(json['color'] as int? ?? 0xFF2196F3),
    joinedAt: DateTime.parse(json['joined_at'] as String),
  );
}

class RecentEdit {
  final String trackId;
  final String action;
  final String userName;
  final DateTime timestamp;

  const RecentEdit({
    required this.trackId,
    required this.action,
    required this.userName,
    required this.timestamp,
  });
}

extension ListExtensions<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}