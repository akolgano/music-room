// lib/screens/playlists/playlist_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/device_provider.dart';
import '../../models/models.dart';
import '../../core/consolidated_core.dart';
import '../../widgets/widgets.dart';
import '../../services/websocket_service.dart';
import '../base_screen.dart';

class PlaylistEditorScreen extends StatefulWidget {
  final String? playlistId;
  const PlaylistEditorScreen({Key? key, this.playlistId}) : super(key: key);
  
  @override
  State<PlaylistEditorScreen> createState() => _PlaylistEditorScreenState();
}

class _PlaylistEditorScreenState extends BaseScreen<PlaylistEditorScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _webSocketService = WebSocketService();
  
  bool _isPublic = false;
  bool _isLoading = false;
  Playlist? _playlist;
  List<PlaylistTrack> _tracks = [];
  List<String> _notifications = [];

  bool get _isEditMode => widget.playlistId?.isNotEmpty == true && widget.playlistId != 'null';

  @override
  String get screenTitle => _isEditMode ? 'Edit Playlist' : 'Create Playlist';

  @override
  List<Widget> get actions => [
    if (_isEditMode) IconButton(icon: const Icon(Icons.share), onPressed: _sharePlaylist),
    IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
  ];

  @override
  Widget? get floatingActionButton => _isEditMode 
    ? FloatingActionButton.extended(
        onPressed: () => navigateTo(AppRoutes.trackSearch, arguments: widget.playlistId),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Songs'),
      )
    : null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
      _setupWebSocket();
    }
  }

  @override
  Widget buildContent() {
    if (_isLoading) return buildLoadingState(message: 'Loading...');

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_notifications.isNotEmpty) _buildNotificationBar(),
            if (!_isEditMode) _buildCreateForm(),
            if (_isEditMode) ...[
              _buildPlaylistHeader(),
              const SizedBox(height: 16),
              _buildEditForm(),
              const SizedBox(height: 16),
              _buildTracksSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBar() => Container(
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
        Expanded(child: Text(_notifications.last, style: const TextStyle(color: Colors.blue))),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.blue, size: 20),
          onPressed: () => setState(() => _notifications.clear()),
        ),
      ],
    ),
  );

  Widget _buildPlaylistHeader() => _playlist == null ? const SizedBox.shrink() : 
    AppTheme.buildHeaderCard(
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withOpacity(0.2),
            ),
            child: const Icon(Icons.library_music, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(_playlist!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          Text('${_tracks.length} tracks • Created by ${_playlist!.creator}', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          _buildVisibilityChip(_playlist!.isPublic),
        ],
      ),
    );

  Widget _buildVisibilityChip(bool isPublic) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: (isPublic ? Colors.green : Colors.orange).withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      isPublic ? 'Public' : 'Private',
      style: TextStyle(color: isPublic ? Colors.green : Colors.orange, fontSize: 12, fontWeight: FontWeight.w500),
    ),
  );

  Widget _buildForm({required String title, required VoidCallback onSubmit, required String buttonText}) =>
    AppTheme.buildFormCard(
      title: title,
      titleIcon: _isEditMode ? Icons.edit : Icons.add,
      child: Column(
        children: [
          AppWidgets.textField(
            controller: _nameController,
            labelText: 'Playlist Name',
            prefixIcon: Icons.title,
            validator: AppValidators.playlistName,
          ),
          const SizedBox(height: 16),
          AppWidgets.textField(
            controller: _descriptionController,
            labelText: 'Description (optional)',
            prefixIcon: Icons.description,
            maxLines: 3,
            validator: AppValidators.description,
          ),
          const SizedBox(height: 16),
          AppWidgets.switchTile(
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value),
            title: 'Public Playlist',
            subtitle: _isPublic ? 'Anyone can view this playlist' : 'Only you can view this playlist',
            icon: _isPublic ? Icons.public : Icons.lock,
          ),
          const SizedBox(height: 24),
          AppWidgets.primaryButton(
            text: buttonText,
            icon: Icons.save,
            onPressed: onSubmit,
            isLoading: _isLoading,
          ),
        ],
      ),
    );

  Widget _buildCreateForm() => _buildForm(
    title: 'Create New Playlist',
    onSubmit: _createPlaylist,
    buttonText: 'Create',
  );

  Widget _buildEditForm() => _buildForm(
    title: 'Playlist Details',
    onSubmit: _saveChanges,
    buttonText: 'Save Changes',
  );

  Widget _buildTracksSection() => Card(
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
                  Text('Tracks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              Text('${_tracks.length} tracks', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          _tracks.isEmpty 
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.music_note, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No tracks yet', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            : ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tracks.length,
                onReorder: _reorderTracks,
                itemBuilder: (context, index) {
                  final track = _tracks[index].track;
                  return track == null 
                    ? ListTile(
                        key: ValueKey(_tracks[index].trackId),
                        title: Text(_tracks[index].name, style: const TextStyle(color: Colors.white)),
                        subtitle: const Text('Track unavailable', style: TextStyle(color: Colors.grey)),
                      )
                    : AppWidgets.trackCard(
                        key: ValueKey(track.id),
                        track: track,
                        onTap: () => _playTrack(track),
                        onRemove: () => _removeTrack(track.id),
                        showAddButton: false,
                      );
                },
              ),
        ],
      ),
    ),
  );

  void _setupWebSocket() {
    if (!_isEditMode) return;
    _webSocketService.notificationsStream.listen((notification) {
      if (mounted) setState(() {
        _notifications.add(notification);
        if (_notifications.length > 3) _notifications.removeAt(0);
      });
    });
  }

  Future<void> _loadData() async {
    if (!_isEditMode) return;
    setState(() => _isLoading = true);
    
    try {
      final musicProvider = getProvider<MusicProvider>();
      _playlist = await musicProvider.getPlaylistDetails(widget.playlistId!, auth.token!);
      
      if (_playlist != null) {
        _nameController.text = _playlist!.name;
        _descriptionController.text = _playlist!.description;
        _isPublic = _playlist!.isPublic;
        
        await musicProvider.fetchPlaylistTracks(widget.playlistId!, auth.token!);
        _tracks = musicProvider.playlistTracks;
      }
    } catch (e) {
      showError('Failed to load playlist: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createPlaylist() async {
    setState(() => _isLoading = true);
    try {
      final musicProvider = getProvider<MusicProvider>();
      final deviceProvider = getProvider<DeviceProvider>();
      
      final playlistId = await musicProvider.createPlaylist(
        _nameController.text,
        _descriptionController.text,
        _isPublic,
        auth.token!,
        deviceProvider.deviceUuid,
      );
      
      if (playlistId != null) {
        showSuccess('Playlist created successfully!');
        Navigator.pushReplacementNamed(context, AppRoutes.playlistEditor, arguments: playlistId);
      }
    } catch (e) {
      showError('Failed to create playlist: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_isEditMode) return;
    setState(() => _isLoading = true);
    
    try {
      final musicProvider = getProvider<MusicProvider>();
      await musicProvider.updatePlaylistDetails(
        playlistId: widget.playlistId!,
        name: _nameController.text,
        description: _descriptionController.text,
        isPublic: _isPublic,
        token: auth.token!,
      );
      
      showSuccess('Playlist updated successfully!');
      await _loadData();
    } catch (e) {
      showError('Failed to update playlist: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _reorderTracks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    setState(() {
      final track = _tracks.removeAt(oldIndex);
      _tracks.insert(newIndex, track);
    });
  }

  Future<void> _removeTrack(String trackId) async {
    final confirmed = await showConfirmDialog('Remove Track', 'Remove this track from the playlist?');
    if (confirmed) {
      try {
        final musicProvider = getProvider<MusicProvider>();
        await musicProvider.removeTrackFromPlaylist(
          playlistId: widget.playlistId!,
          trackId: trackId,
          token: auth.token!,
        );
        showSuccess('Track removed');
      } catch (e) {
        showError('Failed to remove track: $e');
      }
    }
  }

  Future<void> _playTrack(Track track) async {
    showInfo('Playing "${track.name}"');
  }

  void _sharePlaylist() {
    if (_playlist != null) {
      navigateTo(AppRoutes.playlistSharing, arguments: _playlist);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    if (_isEditMode) _webSocketService.disconnect();
    super.dispose();
  }
}
