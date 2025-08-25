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
  DateTime? _voteStartTime;
  DateTime? _voteEndTime;
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

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildLocationTimeFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Text(
            'Location Settings',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (_latitude != null && _longitude != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.15),
                    AppTheme.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.location_on, color: AppTheme.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Event Location Coordinates',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          setState(() {
                            _latitude = null;
                            _longitude = null;
                            _locationController.clear();
                          });
                          showSuccess('Location cleared');
                        },
                        tooltip: 'Clear location',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'LATITUDE',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _latitude!.toStringAsFixed(6),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white24,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'LONGITUDE',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _longitude!.toStringAsFixed(6),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ElevatedButton.icon(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('Detect Current Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Time Settings',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Vote Start Time'),
            subtitle: Text(_voteStartTime != null 
              ? _formatTime(_voteStartTime!)
              : 'Not set'),
            onTap: () => _selectVotingTime(true),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Vote End Time'),
            subtitle: Text(_voteEndTime != null 
              ? _formatTime(_voteEndTime!)
              : 'Not set'),
            onTap: () => _selectVotingTime(false),
          ),
          if (_voteStartTime != null && _voteEndTime != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Voting window repeats daily at these times (server timezone)',
                        style: TextStyle(color: Colors.blue[300], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
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

          if (_isEvent) {
            try {
              final apiService = ApiService();
              final licenseResponse = await apiService.getPlaylistLicense(widget.playlistId!, auth.token!);
              
              if (kDebugMode) {
                debugPrint('========================================');
                debugPrint('DEBUG: FETCHED LICENSE FROM BACKEND');
                debugPrint('License Type from backend: ${licenseResponse.licenseType}');
                debugPrint('Latitude from backend: ${licenseResponse.latitude}');
                debugPrint('Longitude from backend: ${licenseResponse.longitude}');
                debugPrint('Vote Start Time from backend: ${licenseResponse.voteStartTime}');
                debugPrint('Vote End Time from backend: ${licenseResponse.voteEndTime}');
                debugPrint('========================================');
              }
              
              setState(() {
                if (licenseResponse.licenseType != null) {
                  _licenseType = licenseResponse.licenseType!;
                }
                
                if (licenseResponse.latitude != null && licenseResponse.longitude != null) {
                  _latitude = licenseResponse.latitude;
                  _longitude = licenseResponse.longitude;
                  _locationController.text = 'Location Set (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})';
                }
                
                if (licenseResponse.voteStartTime != null) {
                  final startParts = licenseResponse.voteStartTime!.split(':');
                  if (startParts.length >= 2) {
                    final now = DateTime.now();
                    _voteStartTime = DateTime(
                      now.year, now.month, now.day,
                      int.parse(startParts[0]),
                      int.parse(startParts[1]),
                    );
                  }
                }
                
                if (licenseResponse.voteEndTime != null) {
                  final endParts = licenseResponse.voteEndTime!.split(':');
                  if (endParts.length >= 2) {
                    final now = DateTime.now();
                    _voteEndTime = DateTime(
                      now.year, now.month, now.day,
                      int.parse(endParts[0]),
                      int.parse(endParts[1]),
                    );
                  }
                }
              });
              
              if (kDebugMode) {
                debugPrint('========================================');
                debugPrint('DEBUG: LOADED VOTING SETTINGS');
                debugPrint('Location: $_latitude, $_longitude');
                debugPrint('Start Time UTC from backend: ${licenseResponse.voteStartTime}');
                debugPrint('Start Time Local: $_voteStartTime');
                debugPrint('End Time UTC from backend: ${licenseResponse.voteEndTime}');
                debugPrint('End Time Local: $_voteEndTime');
                debugPrint('Current Time Local: ${DateTime.now()}');
                debugPrint('========================================');
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint('Failed to load voting settings: $e');
              }
            }
          }

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

      if (_isEvent && _licenseType == 'location_time' && 
          (_latitude != null || _longitude != null || _voteStartTime != null || _voteEndTime != null)) {
        
        if ((_latitude != null || _longitude != null) && (_voteStartTime == null || _voteEndTime == null)) {
          showError('When setting location, both start and end times are required');
          return;
        }
        if ((_voteStartTime != null || _voteEndTime != null) && (_latitude == null || _longitude == null)) {
          showError('When setting time window, location is required');
          return;
        }
        
        String? voteStartTimeStr;
        String? voteEndTimeStr;
        
        if (_voteStartTime != null) {
          voteStartTimeStr = '${_voteStartTime!.hour.toString().padLeft(2, '0')}:'
              '${_voteStartTime!.minute.toString().padLeft(2, '0')}:00';
        }
        if (_voteEndTime != null) {
          voteEndTimeStr = '${_voteEndTime!.hour.toString().padLeft(2, '0')}:'
              '${_voteEndTime!.minute.toString().padLeft(2, '0')}:00';
        }
        
        final apiService = getIt<ApiService>();
        final licenseRequest = PlaylistLicenseRequest(
          licenseType: _licenseType,
          voteStartTime: voteStartTimeStr,
          voteEndTime: voteEndTimeStr,
          latitude: _latitude,
          longitude: _longitude,
          allowedRadiusMeters: _licenseType == 'location_time' ? 100 : null,
        );
        
        await apiService.updatePlaylistLicense(playlistId!, auth.token!, licenseRequest);
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
        
        if (_licenseType == 'location_time' && (_latitude != null || _longitude != null || _voteStartTime != null || _voteEndTime != null)) {
          if ((_latitude != null || _longitude != null) && (_voteStartTime == null || _voteEndTime == null)) {
            showError('When setting location, both start and end times are required');
            return;
          }
          if ((_voteStartTime != null || _voteEndTime != null) && (_latitude == null || _longitude == null)) {
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
        
        if (kDebugMode) {
          debugPrint('========================================');
          debugPrint('DEBUG: SENDING LICENSE UPDATE TO BACKEND');
          debugPrint('License Type: $_licenseType');
          debugPrint('Latitude: $_latitude');
          debugPrint('Longitude: $_longitude');
          debugPrint('Vote Start Time: $_voteStartTime');
          debugPrint('Vote Start Time (Sent): $voteStartTimeStr');
          debugPrint('Vote End Time: $_voteEndTime');
          debugPrint('Vote End Time (Sent): $voteEndTimeStr');
          debugPrint('Current Time (Local): ${DateTime.now()}');
          debugPrint('Current Time (UTC): ${DateTime.now().toUtc()}');
          debugPrint('Allowed Radius: ${_licenseType == 'location_time' ? 100 : null}');
          debugPrint('========================================');
        }
        
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









  Future<void> _selectVotingTime(bool isStartTime) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStartTime 
        ? (_voteStartTime != null ? TimeOfDay.fromDateTime(_voteStartTime!) : TimeOfDay.now())
        : (_voteEndTime != null ? TimeOfDay.fromDateTime(_voteEndTime!) : TimeOfDay.now()),
    );
    
    if (time != null && mounted) {
      final now = DateTime.now();
      final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      
      setState(() {
        if (isStartTime) {
          _voteStartTime = dateTime;
        } else {
          _voteEndTime = dateTime;
        }
      });
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
      
      showSuccess('Location detected successfully!');
    } catch (e) {
      showError('Failed to get current location: ${e.toString()}');
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

