// lib/screens/music/playlist_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/playlist_license_provider.dart';
import '../../models/models.dart';
import '../../models/collaboration_models.dart';
import '../../core/app_core.dart';
import '../../widgets/common_widgets.dart';
import '../../services/websocket_service.dart';
import '../../services/api_service.dart';
import '../../services/music_player_service.dart';
import '../../utils/dialog_utils.dart';
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
  final WebSocketService _webSocketService = WebSocketService();
  final ApiService _apiService = ApiService();
  
  bool _isPublic = false;
  bool _isScreenLoading = false;
  bool _inviteOnlyMode = false;
  Playlist? _playlist;
  List<PlaylistTrack> _playlistTracks = [];
  List<PlaylistCollaborator> _collaborators = [];
  List<String> _notifications = [];
  bool _autoRefresh = true;
  bool get _isEditMode => widget.playlistId != null && widget.playlistId!.isNotEmpty && widget.playlistId != 'null';

  @override
  String get screenTitle => _isEditMode ? 'Edit Playlist' : 'Create Playlist';

  @override
  List<Widget> get actions => _buildAppBarActions();

  @override
  Widget? get floatingActionButton => _isEditMode ? _buildFloatingActionButton() : null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaylist());
    _setupWebSocketListeners();
  }

  @override
  Widget buildContent() {
    if (_isScreenLoading) return buildLoadingState(message: 'Loading playlist...');

    return Column(
      children: [
        if (_notifications.isNotEmpty) _buildNotificationBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshPlaylist,
            color: AppTheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isEditMode) _buildCreateForm(),
                  if (_isEditMode) ...[
                    _buildPlaylistInfoCard(),
                    const SizedBox(height: 16),
                    _buildCollaboratorsSection(),
                    const SizedBox(height: 16),
                    _buildPlaylistForm(),
                    const SizedBox(height: 16),
                    _buildTracksSection(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<PlaylistLicenseProvider>(
      builder: (context, licenseProvider, _) {
        final canEdit = licenseProvider.canCurrentUserEdit;
        
        if (!canEdit) return const SizedBox.shrink();
        
        return FloatingActionButton.extended(
          onPressed: _navigateToTrackSearch,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add),
          label: const Text('Add Songs'),
        );
      },
    );
  }

  Widget _buildCreateForm() {
    return AppTheme.buildFormCard(
      title: 'Create New Playlist',
      titleIcon: Icons.add,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormComponents.textField(
            controller: _nameController,
            labelText: 'Playlist Name',
            prefixIcon: Icons.title,
            validator: Validators.playlistName,
          ),
          const SizedBox(height: 16),
          FormComponents.textField(
            controller: _descriptionController,
            labelText: 'Description (optional)',
            prefixIcon: Icons.description,
            maxLines: 3,
            validator: Validators.description,
          ),
          const SizedBox(height: 16),
          _buildVisibilitySwitch(),
          const SizedBox(height: 24),
          FormComponents.button(
            text: 'Create',
            icon: Icons.save,
            onPressed: _createPlaylist,
            isLoading: _isScreenLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistForm() {
    return AppTheme.buildFormCard(
      title: 'Playlist Details',
      titleIcon: Icons.edit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormComponents.textField(
            controller: _nameController,
            labelText: 'Playlist Name',
            prefixIcon: Icons.title,
            validator: Validators.playlistName,
          ),
          const SizedBox(height: 16),
          FormComponents.textField(
            controller: _descriptionController,
            labelText: 'Description (optional)',
            prefixIcon: Icons.description,
            maxLines: 3,
            validator: Validators.description,
          ),
          const SizedBox(height: 16),
          _buildVisibilitySwitch(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FormComponents.button(
                  text: 'Save Changes',
                  icon: Icons.save,
                  onPressed: _savePlaylistChanges,
                  isLoading: _isScreenLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _setupWebSocketListeners() {
    if (_isEditMode) {
      _webSocketService.operationsStream.listen((PlaylistOperation operation) {
        if (mounted && operation.userId != auth.userId) {
          _handleRemoteOperation(operation);
        }
      });

      _webSocketService.collaboratorsStream.listen((List<PlaylistCollaborator> collaborators) {
        if (mounted && _autoRefresh) {
          setState(() => _collaborators = collaborators);
        }
      });

      _webSocketService.notificationsStream.listen((String notification) {
        if (mounted) {
          _showNotification(notification);
        }
      });
    }
  }

  void _handleRemoteOperation(PlaylistOperation operation) {
    if (!_autoRefresh) return;
    
    switch (operation.type) {
      case ConflictType.trackMove:
        _applyRemoteTrackMove(operation);
        break;
      case ConflictType.trackAdd:
        _loadPlaylistTracks();
        _showNotification('${operation.username} added a track');
        break;
      case ConflictType.trackRemove:
        final trackId = operation.data['track_id'] as String;
        setState(() {
          _playlistTracks.removeWhere((t) => t.trackId == trackId);
        });
        _showNotification('${operation.username} removed a track');
        break;
      default:
        break;
    }
  }

  void _navigateToTrackSearch() {
    Navigator.pushNamed(context, AppRoutes.trackSearch, arguments: widget.playlistId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    if (_isEditMode) _webSocketService.disconnect();
    super.dispose();
  }
}
