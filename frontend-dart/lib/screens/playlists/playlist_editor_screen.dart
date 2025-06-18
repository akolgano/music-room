// lib/screens/playlists/playlist_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/device_provider.dart';
import '../../models/models.dart';
import '../../core/consolidated_core.dart';
import '../../widgets/widgets.dart';
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
  
  bool _isPublic = false;
  bool _isLoading = false;
  Playlist? _playlist;

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
    if (_isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaylistData());
    }
  }

  @override
  Widget buildContent() {
    if (_isLoading && _isEditMode) {
      return buildLoadingState(message: 'Loading playlist...');
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
            subtitle: _isPublic 
              ? 'Anyone can view this playlist' 
              : 'Only you can view this playlist',
            icon: _isPublic ? Icons.public : Icons.lock,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (_isEditMode) ...[
                Expanded(
                  child: AppWidgets.secondaryButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                    icon: Icons.cancel,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: AppWidgets.primaryButton(
                  text: _isEditMode ? 'Save Changes' : 'Create Playlist',
                  icon: _isEditMode ? Icons.save : Icons.add,
                  onPressed: _isEditMode ? _saveChanges : _createPlaylist,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadPlaylistData() async {
    if (!_isEditMode) return;
    
    setState(() => _isLoading = true);
    
    try {
      final musicProvider = getProvider<MusicProvider>();
      _playlist = await musicProvider.getPlaylistDetails(widget.playlistId!, auth.token!);
      
      if (_playlist != null) {
        _nameController.text = _playlist!.name;
        _descriptionController.text = _playlist!.description;
        _isPublic = _playlist!.isPublic;
      }
    } catch (e) {
      showError('Failed to load playlist: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createPlaylist() async {
    if (_nameController.text.trim().isEmpty) {
      showError('Please enter a playlist name');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final musicProvider = getProvider<MusicProvider>();
      final deviceProvider = getProvider<DeviceProvider>();
      
      final playlistId = await musicProvider.createPlaylist(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
        _isPublic,
        auth.token!,
        deviceProvider.deviceUuid,
      );
      
      if (playlistId != null && playlistId.isNotEmpty) {
        showSuccess('Playlist created successfully!');
        Navigator.pushReplacementNamed(
          context, 
          AppRoutes.playlistDetail, 
          arguments: playlistId
        );
      } else {
        showError('Failed to create playlist: Invalid playlist ID received');
      }
    } catch (e) {
      showError('Failed to create playlist: ${e.toString()}');
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
      final musicProvider = getProvider<MusicProvider>();
      await musicProvider.updatePlaylistDetails(
        playlistId: widget.playlistId!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        isPublic: _isPublic,
        token: auth.token!,
      );
      
      showSuccess('Playlist updated successfully!');
      Navigator.pushReplacementNamed(
        context, 
        AppRoutes.playlistDetail, 
        arguments: widget.playlistId
      );
    } catch (e) {
      showError('Failed to update playlist: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
