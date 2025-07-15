// lib/screens/playlists/playlist_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../services/music_player_service.dart';
import '../../core/service_locator.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../core/core.dart';
import '../../widgets/widgets.dart';
import '../base_screen.dart';

class PlaylistEditorScreen extends StatefulWidget {
  final String? playlistId;

  const PlaylistEditorScreen({super.key, this.playlistId});

  @override
  State<PlaylistEditorScreen> createState() => _PlaylistEditorScreenState();
}

class _PlaylistEditorScreenState extends BaseScreen<PlaylistEditorScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = false;
  bool _isLoading = false;
  Playlist? _playlist;
  List<PlaylistTrack> _tracks = [];

  bool get _isEditMode => widget.playlistId?.isNotEmpty == true && widget.playlistId != 'null';

  @override
  String get screenTitle => _isEditMode ? 'Edit Playlist' : 'Create Playlist';

  @override
  List<Widget> get actions => [
    if (_isEditMode)
      TextButton(
        onPressed: () => navigateTo(AppRoutes.playlistDetail, arguments: widget.playlistId),
        child: const Text('View Details', style: TextStyle(color: AppTheme.primary)),
      ),
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaylistData());
  }

  @override
  Widget buildContent() {
    if (_isLoading) {
      return buildLoadingState(message: _isEditMode ? 'Loading playlist...' : 'Creating playlist...');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_isEditMode && _playlist != null) _buildPlaylistInfo(),
          const SizedBox(height: 16),
          _buildForm(),
        ],
      ),
    );
  }

  Widget _buildPlaylistInfo() {
    if (_playlist == null) return const SizedBox.shrink();

    return AppWidgets.infoBanner(
      title: 'Editing: ${_playlist!.name}',
      message: 'Make changes to your playlist information below',
      icon: Icons.edit,
    );
  }

  Widget _buildForm() {
    return AppTheme.buildFormCard(
      title: _isEditMode ? 'Playlist Settings' : 'Create New Playlist',
      titleIcon: _isEditMode ? Icons.edit : Icons.add,
      child: Column(
        children: [
          AppWidgets.textField(
            context: context,
            controller: _nameController,
            labelText: 'Playlist Name',
            prefixIcon: Icons.title,
            validator: AppValidators.playlistName,
          ),
          const SizedBox(height: 16),
          AppWidgets.textField(
            context: context,
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
            subtitle: _isPublic 
              ? 'Anyone can view this playlist' 
              : 'Only you can view this playlist',
            icon: _isPublic ? Icons.public : Icons.lock,
          ),
          const SizedBox(height: 24),
          AppWidgets.primaryButton(
            context: context,
            text: _isEditMode ? 'Save Changes' : 'Create Playlist',
            icon: _isEditMode ? Icons.save : Icons.add,
            onPressed: _isLoading ? null : (_isEditMode ? _saveChanges : _createPlaylist),
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Future<void> _loadPlaylistData() async {
    if (!_isEditMode) return;

    await runAsyncAction(
      () async {
        final musicProvider = getProvider<MusicProvider>();
        _playlist = await musicProvider.getPlaylistDetails(widget.playlistId!, auth.token!);
        
        if (_playlist != null) {
          setState(() {
            _nameController.text = _playlist!.name;
            _descriptionController.text = _playlist!.description;
            _isPublic = _playlist!.isPublic;
          });

          await musicProvider.fetchPlaylistTracks(widget.playlistId!, auth.token!);
          setState(() {
            _tracks = musicProvider.playlistTracks;
          });
        }
      },
      errorMessage: 'Failed to load playlist',
    );
  }

  Future<void> _createPlaylist() async {
    if (_nameController.text.trim().isEmpty) {
      showError('Please enter a playlist name');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final musicProvider = getProvider<MusicProvider>();
      final playlistId = await musicProvider.createPlaylist(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
        _isPublic,
        auth.token!,
        null, 
      );

      if (playlistId?.isEmpty ?? true) {
        throw Exception('Invalid playlist ID received');
      }

      showSuccess('Playlist created successfully!');
      navigateTo(AppRoutes.playlistDetail, arguments: playlistId);
    } catch (e) {
      showError('Failed to create playlist: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_isEditMode) return;
    if (_nameController.text.trim().isEmpty) {
      showError('Please enter a playlist name');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final apiService = getIt<ApiService>();
      
      if (_playlist != null && _playlist!.isPublic != _isPublic) {
        final visibilityRequest = VisibilityRequest(public: _isPublic);
        await apiService.changePlaylistVisibility(
          widget.playlistId!, 
          'Token ${auth.token!}', 
          visibilityRequest
        );
      }
      
      if (_playlist != null && 
          (_playlist!.name != _nameController.text.trim() || 
           _playlist!.description != _descriptionController.text.trim())) {
        showInfo('Note: Name and description changes are only saved locally. API enhancement needed for server persistence.');
      }
      
      final musicProvider = getProvider<MusicProvider>();
      await musicProvider.fetchUserPlaylists(auth.token!);
      
      showSuccess('Playlist visibility updated successfully!');
      Navigator.pushReplacementNamed(context, AppRoutes.playlistDetail, arguments: widget.playlistId);
    } catch (e) {
      showError('Failed to update playlist: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _reorderTracks(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final PlaylistTrack item = _tracks.removeAt(oldIndex);
      _tracks.insert(newIndex, item);
    });

    _updateTrackOrder(oldIndex, newIndex);
  }

  Future<void> _updateTrackOrder(int oldIndex, int newIndex) async {
    if (!_isEditMode) return;

    try {
      final musicProvider = getProvider<MusicProvider>();
      await musicProvider.moveTrackInPlaylist(
        playlistId: widget.playlistId!,
        rangeStart: oldIndex,
        insertBefore: newIndex,
        token: auth.token!,
      );
    } catch (e) {
      showError('Failed to update track order: $e');
      await _loadPlaylistData();
    }
  }

  Future<void> _playTrack(Track track) async {
    try {
      final playerService = getProvider<MusicPlayerService>();
      String? previewUrl = track.previewUrl;

      if (previewUrl == null && track.deezerTrackId != null) {
        final musicProvider = getProvider<MusicProvider>();
        final fullTrackDetails = await musicProvider.getDeezerTrack(track.deezerTrackId!, auth.token!);
        if (fullTrackDetails?.previewUrl != null) previewUrl = fullTrackDetails!.previewUrl;
      }

      if (previewUrl != null && previewUrl.isNotEmpty) {
        await playerService.playTrack(track, previewUrl);
        showSuccess('Playing "${track.name}"');
      } else showInfo('No preview available for "${track.name}"');
    } catch (e) {
      showError('Failed to play track: $e');
    }
  }

  Future<void> _removeTrack(String trackId) async {
    if (!_isEditMode) return;

    final confirmed = await showConfirmDialog(
      'Remove Track',
      'Remove this track from the playlist?',
    );

    if (confirmed) {
      await runAsyncAction(
        () async {
          final musicProvider = getProvider<MusicProvider>();
          await musicProvider.removeTrackFromPlaylist(playlistId: widget.playlistId!, trackId: trackId, token: auth.token!);
          await musicProvider.fetchPlaylistTracks(widget.playlistId!, auth.token!);
          setState(() => _tracks = musicProvider.playlistTracks);
        },
        successMessage: 'Track removed from playlist',
        errorMessage: 'Failed to remove track',
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
