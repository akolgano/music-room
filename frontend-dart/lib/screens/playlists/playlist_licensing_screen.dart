import '../../core/app_logger.dart';
import 'package:flutter/material.dart';
import '../../providers/friend_provider.dart';
import '../../core/theme_utils.dart';
import '../../core/service_locator.dart'; 
import '../../widgets/app_widgets.dart';
import '../../models/api_models.dart';
import '../../services/api_service.dart';
import '../base_screen.dart';

class PlaylistLicensingScreen extends StatefulWidget {
  final String playlistId;
  final String playlistName;

  const PlaylistLicensingScreen({super.key, 
    required this.playlistId, 
    required this.playlistName
  });

  @override
  State<PlaylistLicensingScreen> createState() => _PlaylistLicensingScreenState();
}

class _PlaylistLicensingScreenState extends BaseScreen<PlaylistLicensingScreen> {
  late final ApiService _apiService;
  
  String _licenseType = 'open';
  List<String> _invitedUsers = [];
  List<String> _availableFriends = [];
  TimeOfDay? _voteStartTime;
  TimeOfDay? _voteEndTime;
  double? _latitude;
  double? _longitude;
  int? _allowedRadiusMeters = 100;
  bool _isLoading = false;
  
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _radiusController = TextEditingController();

  @override
  String get screenTitle => 'Playlist Access Control';

  @override
  void initState() {
    super.initState();
    
    _apiService = getIt<ApiService>();
    
    _latitudeController.text = _latitude?.toString() ?? '';
    _longitudeController.text = _longitude?.toString() ?? '';
    _radiusController.text = _allowedRadiusMeters?.toString() ?? '100';
    
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  Widget buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          _buildPlaylistInfo(),
          const SizedBox(height: 16),
          _buildLicenseTypeSelector(),
          const SizedBox(height: 16),
          if (_licenseType == 'invite_only') _buildInviteOnlyOptions(),
          if (_licenseType == 'location_time') _buildLocationTimeOptions(),
          const SizedBox(height: 24),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildPlaylistInfo() {
    return AppTheme.buildHeaderCard(
      child: Column(
        children: [
          const Icon(Icons.security, size: 60, color: AppTheme.primary),
          const SizedBox(height: 16),
          Text(
            widget.playlistName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Control who can access and vote on this playlist',
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseTypeSelector() {
    return AppTheme.buildFormCard(
      title: 'Access Control Type',
      titleIcon: Icons.settings,
      child: Column(
        children: [
          _buildLicenseOption('open',
            'Public Access',
            'Anyone can view and vote on this playlist',
            Icons.public,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildLicenseOption(
            'invite_only',
            'Invite Only',
            'Only invited users can access this playlist',
            Icons.person_add,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildLicenseOption(
            'location_time',
            'Location & Time Restricted',
            'Access restricted by location and time',
            Icons.location_on,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseOption(
    String value,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _licenseType == value;
    return GestureDetector(
      onTap: () => setState(() => _licenseType = value),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteOnlyOptions() {
    return AppTheme.buildFormCard(
      title: 'Invited Users',
      titleIcon: Icons.people,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select friends to invite to this playlist:',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          if (_availableFriends.isEmpty)
            AppWidgets.emptyState(
              icon: Icons.people_outline,
              title: 'No friends available',
              subtitle: 'Add friends first to invite them',
            )
          else
            ..._availableFriends.map((friendId) => CheckboxListTile(
              value: _invitedUsers.contains(friendId),
              onChanged: (value) => _toggleFriendInvite(friendId, value ?? false),
              title: Text(
                'Friend #$friendId',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'User ID: $friendId',
                style: const TextStyle(color: Colors.grey),
              ),
              secondary: CircleAvatar(
                backgroundColor: ThemeUtils.getColorFromString(friendId),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              activeColor: AppTheme.primary,
            )),
          if (_invitedUsers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${_invitedUsers.length} users invited',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationTimeOptions() {
    return Column(
      children: [
        AppTheme.buildFormCard(
          title: 'Voting Time Window',
          titleIcon: Icons.access_time,
          child: Column(
            children: [
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
              const SizedBox(height: 8),
              const Text(
                'Users can only vote within this time window',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppTheme.buildFormCard(
          title: 'Location Restrictions',
          titleIcon: Icons.location_on,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppWidgets.textField(
                      context: context,
                      controller: _latitudeController,
                      labelText: 'Latitude',
                      prefixIcon: Icons.my_location,
                      onChanged: (value) => _latitude = double.tryParse(value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppWidgets.textField(
                      context: context,
                      controller: _longitudeController,
                      labelText: 'Longitude',
                      prefixIcon: Icons.location_on,
                      onChanged: (value) => _longitude = double.tryParse(value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppWidgets.textField(
                context: context,
                controller: _radiusController,
                labelText: 'Allowed Radius (meters)',
                prefixIcon: Icons.radio_button_unchecked,
                onChanged: (value) => _allowedRadiusMeters = int.tryParse(value),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use Current Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surface,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Users must be within this radius to vote',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectTime(onTimeSelected),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  selectedTime?.format(context) ?? 'Select Time',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: AppWidgets.primaryButton(
        context: context,
        text: _isLoading ? 'Saving...' : 'Save Access Control',
        onPressed: _isLoading ? null : _saveSettings,
        isLoading: _isLoading,
        icon: Icons.save,
      ),
    );
  }

  Future<void> _loadData() async {
    await runAsyncAction(
      () async {
        AppLogger.debug('Loading playlist licensing data for ${widget.playlistId}', 'PlaylistLicensingScreen');
        final friendProvider = getProvider<FriendProvider>();
        await friendProvider.fetchFriends(auth.token!);
        setState(() {
          _availableFriends = friendProvider.friends;
        });

        try {
          final license = await _apiService.getPlaylistLicense(
            widget.playlistId,
            auth.token!,
          );
          AppLogger.debug('Loaded existing license settings: ${license.licenseType}', 'PlaylistLicensingScreen');
          setState(() {
            _licenseType = license.licenseType;
            _invitedUsers = license.invitedUsers;
            if (license.voteStartTime != null) {
              final parts = license.voteStartTime!.split(':');
              _voteStartTime = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            }
            if (license.voteEndTime != null) {
              final parts = license.voteEndTime!.split(':');
              _voteEndTime = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            }
            _latitude = license.latitude;
            _longitude = license.longitude;
            _allowedRadiusMeters = license.allowedRadiusMeters;
            
            _latitudeController.text = _latitude?.toString() ?? '';
            _longitudeController.text = _longitude?.toString() ?? '';
            _radiusController.text = _allowedRadiusMeters?.toString() ?? '100';
          });
        } catch (e) {
          AppLogger.debug('No existing license found, using defaults: $e', 'PlaylistLicensingScreen');
        }
      },
      errorMessage: 'Failed to load playlist settings',
    );
  }

  void _toggleFriendInvite(String friendId, bool invite) {
    setState(() {
      if (invite) {
        _invitedUsers.add(friendId);
      } else {
        _invitedUsers.remove(friendId);
      }
    });
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
    setState(() {
      _latitude = 1.364917; 
      _longitude = 103.822872;
      _latitudeController.text = _latitude.toString();
      _longitudeController.text = _longitude.toString();
    });
    showInfo('Location set to current position');
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    try {
      AppLogger.debug('Saving playlist license settings: $_licenseType', 'PlaylistLicensingScreen');
      
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

      final request = PlaylistLicenseRequest(
        licenseType: _licenseType,
        invitedUsers: _licenseType != 'open' ? _invitedUsers : null,
        voteStartTime: _licenseType == 'location_time' ? voteStartTimeStr : null,
        voteEndTime: _licenseType == 'location_time' ? voteEndTimeStr : null,
        latitude: _licenseType == 'location_time' ? _latitude : null,
        longitude: _licenseType == 'location_time' ? _longitude : null,
        allowedRadiusMeters: _licenseType == 'location_time' ? _allowedRadiusMeters : null,
      );

      await _apiService.updatePlaylistLicense(widget.playlistId, auth.token!, request);
      
      showSuccess('Playlist access control updated successfully!');
      navigateBack();
    } catch (e) {
      showError('Failed to update playlist settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();
    super.dispose();
  }
}
