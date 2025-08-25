import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../providers/music_providers.dart';
import '../../providers/profile_providers.dart';
import '../../core/locator_core.dart';
import '../../services/api_services.dart';
import '../../models/music_models.dart';
import '../../models/api_models.dart';
import '../../core/theme_core.dart';
import '../../core/provider_core.dart';
import '../../core/navigation_core.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/location_widgets.dart';
import '../base_screens.dart';
import 'collaborative_playlists.dart';

class PlaylistEditorScreen extends StatefulWidget {
  final String? playlistId;

  const PlaylistEditorScreen({super.key, this.playlistId});

  @override
  State<PlaylistEditorScreen> createState() => _PlaylistEditorScreenState();
}

class _PlaylistEditorScreenState extends BaseScreen<PlaylistEditorScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isPublic = true;
  bool _isEvent = false;
  bool _isLoading = false;
  String _licenseType = 'open';
  TimeOfDay? _voteStartTime;
  TimeOfDay? _voteEndTime;
  double? _latitude;
  double? _longitude;
  
  Playlist? _playlist;
  bool _showCollaborationFeatures = false;

  bool get _isEditMode => widget.playlistId?.isNotEmpty == true && widget.playlistId != 'null';
 
  
  bool get _isOwner {
    if (_playlist == null) return true;
    return _playlist!.creator == auth.username;
  } 

  @override
  String get screenTitle => _isEditMode ? 'Edit Playlist' : 'Create Playlist';

  @override
  List<Widget> get actions => [
    if (_isEditMode) ...[
      IconButton(
        icon: Icon(_showCollaborationFeatures ? Icons.edit : Icons.people),
        onPressed: () => setState(() => _showCollaborationFeatures = !_showCollaborationFeatures),
        tooltip: _showCollaborationFeatures ? 'Show Settings' : 'Show Collaboration',
      ),
      IconButton(
        icon: const Icon(Icons.group),
        onPressed: () {},
        tooltip: 'Active Collaborators',
      ),
      TextButton(
        onPressed: () => navigateTo(AppRoutes.playlistDetail, arguments: widget.playlistId),
        child: const Text('View Details', style: TextStyle(color: AppTheme.primary)),
      ),
    ],
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
    if (_isLoading) {
      return buildLoadingState(message: _isEditMode ? 'Loading playlist...' : 'Creating playlist...');
    }

    if (_isEditMode && _showCollaborationFeatures && _playlist != null) {
      return PlaylistCollaborativeEditor(
        playlistId: widget.playlistId!,
        playlist: _playlist!,
        onTracksUpdated: (tracks) {},
        onError: showError,
        onSuccess: showSuccess,
        onInfo: showInfo,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
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
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter playlist name' : null,
            onFieldSubmitted: kIsWeb ? (_) => (_isEditMode ? _saveChanges() : _createPlaylist()) : null,
          ),
          const SizedBox(height: 16),
          AppWidgets.textField(
            context: context,
            controller: _descriptionController,
            labelText: 'Description (optional)',
            prefixIcon: Icons.description,
            maxLines: 3,
            validator: (value) => value != null && value.length > 500 ? 'Description must be less than 500 characters' : null,
          ),
          const SizedBox(height: 16),
          AppWidgets.switchTile(
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value),
            title: 'Public Playlist',
            subtitle: _isPublic 
              ? 'Anyone can view this playlist (no edit permissions)' 
              : 'Only you and invited users can view this playlist',
            icon: _isPublic ? Icons.public : Icons.lock,
          ),
          const SizedBox(height: 16),
          AppWidgets.switchTile(
            value: _isEvent,
            onChanged: (value) => setState(() => _isEvent = value),
            title: 'Event',
            subtitle: _isEvent 
              ? (_isPublic 
                  ? 'Public event - anyone can vote' 
                  : 'Private event - only invited users can vote')
              : 'Regular playlist - no voting available',
            icon: _isEvent ? Icons.event : Icons.playlist_play,
          ),
          const SizedBox(height: 16),
          if (_isEvent && _isOwner) _buildEventVotingSettings(),
          if (_isEvent && _isOwner) const SizedBox(height: 24),
          if (!_isEvent && _isPublic) const SizedBox(height: 8),
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

  Widget _buildEventVotingSettings() {
    return AppTheme.buildFormCard(
      title: 'Voting Permissions',
      titleIcon: Icons.how_to_vote,
      child: RadioGroup<String>(
        groupValue: _licenseType,
        onChanged: (value) => setState(() => _licenseType = value!),
        child: Column(
          children: [
            ListTile(
              title: const Text('Open Voting'),
              subtitle: Text(_isPublic 
                ? 'Anyone can vote on this event'
                : 'All invited users can vote on this event'),
              leading: Radio<String>(
                value: 'open',
              ),
              onTap: () => setState(() => _licenseType = 'open'),
            ),
            ListTile(
              title: const Text('Location & Time Restricted'),
              subtitle: Text(_isPublic
                ? 'Vote only at specific location and time'
                : 'Invited users can vote only at specific location and time'),
              leading: Radio<String>(
                value: 'location_time',
              ),
              onTap: () => setState(() => _licenseType = 'location_time'),
            ),
            if (_licenseType == 'location_time') ...[
              const SizedBox(height: 16),
              _buildLocationTimeFields(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTimeFields() {
    return Column(
      children: [
        const Divider(height: 1),
        const SizedBox(height: 16),
        const Text(
          'Location Settings (Optional)',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Leave blank to allow voting from anywhere. If filled, all fields are required.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 16),
        LocationAutocompleteField(
          initialValue: _locationController.text,
          labelText: 'Event Location',
          hintText: 'Enter location or use profile location',
          onLocationSelected: (location) {
            setState(() {
              _locationController.text = location;
            });
          },
          showAutoDetectButton: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _useProfileLocation,
                icon: const Icon(Icons.person_pin, size: 18),
                label: const Text('Use Profile Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('Current Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Time Window (Optional)',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTimeSelector(
                'Start Time',
                _voteStartTime,
                (time) => setState(() => _voteStartTime = time),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimeSelector(
                'End Time',
                _voteEndTime,
                (time) => setState(() => _voteEndTime = time),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSelector(
    String label,
    TimeOfDay? selectedTime,
    Function(TimeOfDay) onTimeSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectTime(onTimeSelected),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  selectedTime?.format(context) ?? 'Not Set',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }








  Future<void> _loadPlaylistData() async {
    if (!_isEditMode) return;

    await runAsyncAction(
      () async {
        final musicProvider = getProvider<MusicProvider>();
        _playlist = await musicProvider.getPlaylistDetails(widget.playlistId!, auth.token!);
        
        if (_playlist != null) {
          if (_playlist!.creator != auth.username) {
            showError('You do not have permission to edit this playlist');
            navigateTo(AppRoutes.playlistDetail, arguments: widget.playlistId);
            return;
          }
          
          if (kDebugMode) {
            debugPrint('========================================');
            debugPrint('DEBUG: PLAYLIST EDITOR - LOADING DATA');
            debugPrint('Playlist ID: ${widget.playlistId}');
            debugPrint('Playlist Name: ${_playlist!.name}');
            debugPrint('isEvent from API: ${_playlist!.isEvent}');
            debugPrint('========================================');
          }
          
          setState(() {
            _nameController.text = _playlist!.name;
            _descriptionController.text = _playlist!.description;
            _isPublic = _playlist!.isPublic;
            _isEvent = _playlist!.isEvent;
            _licenseType = _playlist!.licenseType;
          });

          await musicProvider.fetchPlaylistTracks(widget.playlistId!, auth.token!);
          
          setState(() {});
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
        _licenseType,
        _isEvent,
      );

      if (playlistId?.isEmpty ?? true) {
        throw Exception('Invalid playlist ID received');
      }

      showSuccess('Playlist created successfully!');
      navigateTo(AppRoutes.playlistDetail, arguments: playlistId);
    } catch (e) {
      AppLogger.error('Failed to create playlist', e, null, 'PlaylistEditorScreen');
      showError('Failed to create playlist: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_isEditMode) return;
    
    if (_playlist != null && _playlist!.creator != auth.username) {
      showError('You do not have permission to edit this playlist');
      navigateTo(AppRoutes.playlistDetail, arguments: widget.playlistId);
      return;
    }
    
    if (_nameController.text.trim().isEmpty) {
      showError('Please enter a playlist name');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final apiService = getIt<ApiService>();
      
      final hasNameOrDescriptionChanged = _playlist != null && 
          (_playlist!.name != _nameController.text.trim() || 
           _playlist!.description != _descriptionController.text.trim());
      final hasEventChanged = _playlist != null && _playlist!.isEvent != _isEvent;
      final hasVisibilityChanged = _playlist != null && _playlist!.isPublic != _isPublic;
      final hasLicenseTypeChanged = _playlist != null && _playlist!.licenseType != _licenseType;
      
      if (kDebugMode) {
        debugPrint('========================================');
        debugPrint('DEBUG: SAVING PLAYLIST CHANGES');
        debugPrint('Playlist ID: ${widget.playlistId}');
        debugPrint('Current isEvent: ${_playlist!.isEvent}');
        debugPrint('New isEvent: $_isEvent');
        debugPrint('hasEventChanged: $hasEventChanged');
        debugPrint('========================================');
      }
      
      if (hasVisibilityChanged) {
        final visibilityRequest = VisibilityRequest(public: _isPublic);
        await apiService.changePlaylistVisibility(widget.playlistId!, auth.token!, visibilityRequest);
      }
      
      if (hasNameOrDescriptionChanged || hasEventChanged) {
        final musicProvider = getProvider<MusicProvider>();
        await musicProvider.updatePlaylistDetails(
          widget.playlistId!,
          auth.token!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          isEvent: _isEvent,
        );
      }
      
      if (hasLicenseTypeChanged || (_isEvent && _licenseType == 'location_time')) {
        String? voteStartTimeStr;
        String? voteEndTimeStr;
        
        if (_licenseType == 'location_time' && (_locationController.text.isNotEmpty || _voteStartTime != null || _voteEndTime != null)) {
          if (_locationController.text.isNotEmpty && (_voteStartTime == null || _voteEndTime == null)) {
            showError('When setting location, both start and end times are required');
            return;
          }
          if ((_voteStartTime != null || _voteEndTime != null) && _locationController.text.isEmpty) {
            showError('When setting time window, location is required');
            return;
          }
          
          if (_voteStartTime != null) {
            voteStartTimeStr = '${_voteStartTime!.hour.toString().padLeft(2, '0')}:'
                '${_voteStartTime!.minute.toString().padLeft(2, '0')}:00';
          }
          if (_voteEndTime != null) {
            voteEndTimeStr = '${_voteEndTime!.hour.toString().padLeft(2, '0')}:'
                '${_voteEndTime!.minute.toString().padLeft(2, '0')}:00';
          }
        }
        
        final licenseRequest = PlaylistLicenseRequest(
          licenseType: _licenseType,
          voteStartTime: voteStartTimeStr,
          voteEndTime: voteEndTimeStr,
          latitude: _latitude,
          longitude: _longitude,
          allowedRadiusMeters: _licenseType == 'location_time' ? 100 : null,
        );
        await apiService.updatePlaylistLicense(widget.playlistId!, auth.token!, licenseRequest);
      }
      
      final musicProvider = getProvider<MusicProvider>();
      
      musicProvider.updatePlaylistInCache(
        widget.playlistId!,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        isPublic: _isPublic,
        isEvent: _isEvent,
        licenseType: _licenseType,
      );
      
      await musicProvider.fetchAllPlaylists(auth.token!);
      
      showSuccess('Playlist updated successfully!');
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.playlistDetail, arguments: widget.playlistId);
      }
    } catch (e) {
      AppLogger.error('Failed to update playlist', e, null, 'PlaylistEditorScreen');
      showError('Failed to update playlist: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }









  Future<void> _selectTime(Function(TimeOfDay) onTimeSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              surface: AppTheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          showError('Location permissions are denied');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        showError('Location permissions are permanently denied. Please enable location access in settings.');
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        showError('Location services are disabled. Please enable location services.');
        return;
      }

      showInfo('Getting your current location...');
      
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationController.text = 'Current Location (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})';
      });
      
      showSuccess('Location set to current position');
    } catch (e) {
      showError('Failed to get current location: ${e.toString()}');
    }
  }

  Future<void> _useProfileLocation() async {
    try {
      final profileProvider = getProvider<ProfileProvider>();
      final profileLocation = profileProvider.location;
      
      if (profileLocation == null || profileLocation.isEmpty) {
        showError('No location set in your profile');
        return;
      }
      
      setState(() {
        _locationController.text = profileLocation;
      });
      
      showSuccess('Using profile location: $profileLocation');
    } catch (e) {
      showError('Failed to get profile location');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}

