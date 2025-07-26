import 'package:flutter/material.dart';
import '../../models/music_models.dart';
import '../../models/voting_models.dart';
import '../../core/theme_utils.dart';
import '../../core/constants.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/voting_widgets.dart';
import '../base_screen.dart';

class MusicTrackVoteScreen extends StatefulWidget {
  final String? eventId;
  final bool isCreatingEvent;

  const MusicTrackVoteScreen({
    super.key, 
    this.eventId,
    this.isCreatingEvent = false,
  });

  @override
  State<MusicTrackVoteScreen> createState() => _MusicTrackVoteScreenState();
}

class _MusicTrackVoteScreenState extends BaseScreen<MusicTrackVoteScreen> {
  final _eventNameController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  bool _isPublicEvent = true;
  bool _isLoading = false;
  String _licenseType = 'open';
  DateTime? _startTime;
  DateTime? _endTime;
  
  VotingEvent? _currentEvent;
  List<TrackWithVotes> _votingTracks = [];
  PlaylistVotingInfo? _votingInfo;
  
  bool get _isEventHost => _currentEvent?.createdBy == auth.userId;
  bool get _canManageEvent => widget.isCreatingEvent || _isEventHost;

  @override
  String get screenTitle => widget.isCreatingEvent 
    ? 'Create Voting Event' 
    : _currentEvent?.name ?? 'Track Voting';

  @override
  List<Widget> get actions => [
    if (_canManageEvent && _currentEvent != null)
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: _showEventSettings,
      ),
    if (_currentEvent != null)
      IconButton(
        icon: const Icon(Icons.share),
        onPressed: _shareEvent,
      ),
  ];

  @override
  void initState() {
    super.initState();
    if (!widget.isCreatingEvent && widget.eventId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEventData());
    }
  }

  @override
  Widget buildContent() {
    if (widget.isCreatingEvent) {
      return _buildEventCreationForm();
    }

    if (_isLoading) {
      return buildLoadingState(message: 'Loading voting event...');
    }

    if (_currentEvent == null) {
      return _buildEventNotFound();
    }

    return _buildVotingInterface();
  }

  Widget _buildEventCreationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AppWidgets.infoBanner(
            title: 'Create Voting Event',
            message: 'Create a collaborative music voting session! Invite friends to suggest tracks and vote on favorites together.',
            icon: Icons.how_to_vote,
          ),
          const SizedBox(height: 16),
          _buildEventForm(),
        ],
      ),
    );
  }

  Widget _buildEventForm() {
    return AppTheme.buildFormCard(
      title: 'Event Details',
      titleIcon: Icons.event,
      child: Column(
        children: [
          AppWidgets.textField(
            context: context,
            controller: _eventNameController,
            labelText: 'Event Name',
            prefixIcon: Icons.title,
            validator: (value) => value?.isEmpty == true ? 'Please enter an event name' : null,
          ),
          const SizedBox(height: 16),
          AppWidgets.textField(
            context: context,
            controller: _eventDescriptionController,
            labelText: 'Description (optional)',
            prefixIcon: Icons.description,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildVisibilitySettings(),
          const SizedBox(height: 16),
          _buildLicenseSettings(),
          const SizedBox(height: 24),
          AppWidgets.primaryButton(
            context: context,
            text: 'Create Event',
            icon: Icons.add,
            onPressed: _isLoading ? null : _createEvent,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilitySettings() {
    return AppTheme.buildFormCard(
      title: 'Visibility',
      titleIcon: Icons.visibility,
      child: Column(
        children: [
          AppWidgets.switchTile(
            value: _isPublicEvent,
            onChanged: (value) => setState(() => _isPublicEvent = value),
            title: 'Public Event',
            subtitle: _isPublicEvent 
              ? 'Anyone can find and join this event' 
              : 'Only invited users can join',
            icon: _isPublicEvent ? Icons.public : Icons.lock,
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseSettings() {
    return AppTheme.buildFormCard(
      title: 'Voting Permissions',
      titleIcon: Icons.security,
      child: Column(
        children: [
          RadioListTile<String>(
            title: const Text('Open Voting'),
            subtitle: const Text('Anyone can vote'),
            value: 'open',
            groupValue: _licenseType,
            onChanged: (value) => setState(() => _licenseType = value!),
          ),
          RadioListTile<String>(
            title: const Text('Invite Only'),
            subtitle: const Text('Only invited users can vote'),
            value: 'invite_only',
            groupValue: _licenseType,
            onChanged: (value) => setState(() => _licenseType = value!),
          ),
          RadioListTile<String>(
            title: const Text('Location & Time Restricted'),
            subtitle: const Text('Vote only at specific location and time'),
            value: 'location_time',
            groupValue: _licenseType,
            onChanged: (value) => setState(() => _licenseType = value!),
          ),
          if (_licenseType == 'location_time') _buildTimeSettings(),
        ],
      ),
    );
  }

  Widget _buildTimeSettings() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Start Time'),
            subtitle: Text(_startTime?.toString() ?? 'Not set'),
            onTap: () => _selectDateTime(true),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('End Time'),
            subtitle: Text(_endTime?.toString() ?? 'Not set'),
            onTap: () => _selectDateTime(false),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingInterface() {
    return Column(
      children: [
        _buildEventHeader(),
        _buildVotingStats(),
        Expanded(child: _buildTracksList()),
        _buildAddTrackButton(),
      ],
    );
  }

  Widget _buildEventHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primary.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _currentEvent!.isPublic ? Icons.public : Icons.lock,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentEvent!.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (_currentEvent!.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _currentEvent!.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Host: ${_currentEvent!.createdBy}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Icon(Icons.people, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${_votingTracks.length} tracks',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVotingStats() {
    if (_votingInfo == null) return const SizedBox.shrink();
    
    final canVote = _votingInfo!.canVote;
    final restrictionMessage = _votingInfo!.restrictions.restrictionMessage;

    return Container(
      padding: const EdgeInsets.all(16),
      color: canVote ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(
            canVote ? Icons.check_circle : Icons.warning,
            color: canVote ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              restrictionMessage,
              style: TextStyle(
                color: canVote ? Colors.green[700] : Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTracksList() {
    if (_votingTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
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
              'Be the first to suggest a track!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _votingTracks.length,
      itemBuilder: (context, index) => _buildTrackVoteCard(_votingTracks[index]),
    );
  }

  Widget _buildTrackVoteCard(TrackWithVotes trackWithVotes) {
    final track = trackWithVotes.track;
    final voteStats = trackWithVotes.voteStats;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: track.imageUrl != null 
                    ? Image.network(
                        track.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildDefaultAlbumArt(),
                      )
                    : _buildDefaultAlbumArt(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track.artist,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (track.album.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          track.album,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TrackVotingControls(
              playlistId: _currentEvent!.id,
              trackId: track.id,
              stats: voteStats,
              onVoteSubmitted: () => _loadEventData(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAlbumArt() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.music_note,
        color: AppTheme.primary,
        size: 30,
      ),
    );
  }

  Widget _buildAddTrackButton() {
    final canSuggest = _votingInfo?.canVote ?? false;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: AppWidgets.primaryButton(
        context: context,
        text: 'Suggest Track',
        icon: Icons.add,
        onPressed: canSuggest ? _suggestTrack : null,
        isLoading: false,
      ),
    );
  }

  Widget _buildEventNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Event Not Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The voting event you\'re looking for doesn\'t exist or has been removed.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          AppWidgets.primaryButton(
            context: context,
            text: 'Go Back',
            icon: Icons.arrow_back,
            onPressed: () => Navigator.pop(context),
            isLoading: false,
          ),
        ],
      ),
    );
  }

  Future<void> _loadEventData() async {
    await runAsyncAction(
      () async {
        // TODO: Implement voting event loading
        // For now, create mock data
        _currentEvent = VotingEvent(
          id: widget.eventId ?? 'mock_event',
          name: 'Sample Voting Event',
          description: 'This is a sample voting event',
          isPublic: true,
          createdBy: auth.userId ?? 'unknown',
          createdAt: DateTime.now(),
          licenseType: 'open',
        );
        
        _votingInfo = PlaylistVotingInfo(
          playlistId: _currentEvent!.id,
          restrictions: VotingRestrictions(
            licenseType: 'open',
            isInvited: true,
            isInTimeWindow: true,
            isInLocation: true,
          ),
          trackVotes: {},
        );
        
        _votingTracks = [];
        
        setState(() {});
      },
      errorMessage: 'Failed to load voting event',
    );
  }

  Future<void> _createEvent() async {
    if (_eventNameController.text.trim().isEmpty) {
      showError('Please enter an event name');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // TODO: Implement voting event creation
      final eventId = 'event_${DateTime.now().millisecondsSinceEpoch}';
      
      showSuccess('Voting event created successfully!');
      navigateTo(AppRoutes.votingEvent, arguments: eventId);
    } catch (e) {
      showError('Failed to create event: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _suggestTrack() async {
    final selectedTrack = await Navigator.pushNamed(
      context, 
      AppRoutes.trackSearch,
      arguments: {'selectMode': true},
    ) as Track?;

    if (selectedTrack != null) {
      try {
        // TODO: Implement track suggestion functionality
        setState(() {
          _votingTracks.add(TrackWithVotes(
            track: selectedTrack,
            voteStats: VoteStats(
              totalVotes: 0,
              upvotes: 0,
              downvotes: 0,
              userHasVoted: false,
              voteScore: 0.0,
            ),
          ));
        });
        
        showSuccess('Track suggested successfully!');
      } catch (e) {
        showError('Failed to suggest track: $e');
      }
    }
  }

  Future<void> _selectDateTime(bool isStartTime) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isStartTime) {
            _startTime = dateTime;
          } else {
            _endTime = dateTime;
          }
        });
      }
    }
  }

  void _showEventSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Event Settings'),
        content: const Text('Event management features coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _shareEvent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Event'),
        content: Text('Event ID: ${_currentEvent?.id}\n\nShare this ID with others to let them join the voting!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    super.dispose();
  }
}

class TrackWithVotes {
  final Track track;
  final VoteStats voteStats;

  const TrackWithVotes({
    required this.track,
    required this.voteStats,
  });
}

class VotingEvent {
  final String id;
  final String name;
  final String description;
  final bool isPublic;
  final String createdBy;
  final DateTime createdAt;
  final String licenseType;

  const VotingEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.isPublic,
    required this.createdBy,
    required this.createdAt,
    required this.licenseType,
  });

  factory VotingEvent.fromJson(Map<String, dynamic> json) => VotingEvent(
    id: json['id'].toString(),
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    isPublic: json['is_public'] as bool,
    createdBy: json['created_by'].toString(),
    createdAt: DateTime.parse(json['created_at'] as String),
    licenseType: json['license_type'] as String,
  );
}
