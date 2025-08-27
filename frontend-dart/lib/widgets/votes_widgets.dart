import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/music_models.dart';
import '../models/voting_models.dart';
import '../widgets/app_widgets.dart';
import '../core/theme_core.dart';
import '../core/responsive_core.dart';
import '../core/navigation_core.dart';
import '../core/provider_core.dart';
import '../providers/voting_providers.dart';
import '../providers/auth_providers.dart';

class PlaylistVotingWidgets {
  static Widget _buildMusicNotePlaceholder() => Container(
    width: 48, height: 48,
    decoration: BoxDecoration(
      color: AppTheme.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Icon(Icons.music_note, color: AppTheme.primary, size: 24),
  );

  static List<Widget> buildVotingModeHeader({
    required BuildContext context,
    required bool isOwner,
    required bool isPublicVoting,
    required String votingLicenseType,
    required DateTime? votingStartTime,
    required DateTime? votingEndTime,
    required PlaylistVotingInfo? votingInfo,
    required ValueChanged<bool> onPublicVotingChanged,
    required ValueChanged<String> onLicenseTypeChanged,
    required Future<void> Function() onApplyVotingSettings,
    required Future<void> Function(bool) onSelectVotingDateTime,
    String? playlistId,
    double? latitude,
    double? longitude,
    Future<void> Function()? onDetectLocation,
    VoidCallback? onClearLocation,
  }) {
    return [
      _buildVotingModeInfoBanner(context, isOwner, playlistId: playlistId),
      SizedBox(height: MusicAppResponsive.getSpacing(context)),
      if (votingInfo != null) _buildVotingStats(context, votingInfo),
    ];
  }

  static Widget _buildVotingModeInfoBanner(BuildContext context, bool isOwner, {String? playlistId}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.1),
            AppTheme.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.how_to_vote, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voting Mode Active',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOwner 
                        ? 'Users can vote for their favorite track. Go to Edit Playlist to configure voting settings.'
                        : 'Vote for your favorite track below to boost its ranking!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isOwner && playlistId != null) 
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.playlistEditor, arguments: playlistId);
              },
              icon: const Icon(Icons.settings),
              label: const Text('Configure Voting Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.keyboard_arrow_down, color: AppTheme.primary),
                Text(
                  'Scroll down to see tracks and vote',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: AppTheme.primary),
              ],
            ),
        ],
      ),
    );
  }


  static Widget _buildVotingLicenseSettings({
    required BuildContext context,
    required String votingLicenseType,
    required DateTime? votingStartTime,
    required DateTime? votingEndTime,
    required ValueChanged<bool> onPublicVotingChanged,
    required ValueChanged<String> onLicenseTypeChanged,
    required Future<void> Function(bool) onSelectVotingDateTime,
    double? latitude,
    double? longitude,
    Future<void> Function()? onDetectLocation,
    VoidCallback? onClearLocation,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voting Permissions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        RadioGroup<String>(
          groupValue: votingLicenseType,
          onChanged: (v) => v != null ? onLicenseTypeChanged(v) : null,
          child: Column(
            children: [
              ('open', 'Open Voting', 'Anyone can vote'),
              ('location_time', 'Location & Time Restricted', 'Vote only at specific location and time'),
            ].map((e) => ListTile(
              title: Text(e.$2),
              subtitle: Text(e.$3),
              leading: Radio<String>(
                value: e.$1,
              ),
              onTap: () => onLicenseTypeChanged(e.$1),
            )).toList(),
          ),
        ),
        if (votingLicenseType == 'location_time') _buildLocationTimeSettings(
          context: context,
          votingStartTime: votingStartTime,
          votingEndTime: votingEndTime,
          onSelectVotingDateTime: onSelectVotingDateTime,
          latitude: latitude,
          longitude: longitude,
          onDetectLocation: onDetectLocation,
          onClearLocation: onClearLocation,
        ),
      ],
    );
  }

  static Widget _buildLocationTimeSettings({
    required BuildContext context,
    required DateTime? votingStartTime,
    required DateTime? votingEndTime,
    required Future<void> Function(bool) onSelectVotingDateTime,
    double? latitude,
    double? longitude,
    Future<void> Function()? onDetectLocation,
    VoidCallback? onClearLocation,
  }) {
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
          if (latitude != null && longitude != null)
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
                      if (onClearLocation != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: onClearLocation,
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
                                latitude.toStringAsFixed(6),
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
                                longitude.toStringAsFixed(6),
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
          if (onDetectLocation != null)
            ElevatedButton.icon(
              onPressed: onDetectLocation,
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
            title: const Text('Start Time'),
            subtitle: Text(votingStartTime?.toString() ?? 'Not set'),
            onTap: () => onSelectVotingDateTime(true),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('End Time'),
            subtitle: Text(votingEndTime?.toString() ?? 'Not set'),
            onTap: () => onSelectVotingDateTime(false),
          ),
        ],
      ),
    );
  }

  static Widget _buildVotingStats(BuildContext context, PlaylistVotingInfo votingInfo) {
    final canVote = votingInfo.canVote;
    final restrictionMessage = votingInfo.restrictions.restrictionMessage;

    return Container(
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: canVote ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: canVote ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            canVote ? Icons.check_circle : Icons.warning,
            color: canVote ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 6),
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

  static Widget buildVotingTracksSection({
    required BuildContext context,
    required List<PlaylistTrack> tracks,
    required String playlistId,
    required VoidCallback onLoadData,
    required VoidCallback onSuggestTrackForVoting,
    required PlaylistVotingInfo? votingInfo,
    String? playlistOwnerId,
    bool isEvent = false,
  }) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 6,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1),
                    AppTheme.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.how_to_vote, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vote for Your Favorite Track',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${tracks.length} track${tracks.length == 1 ? '' : 's'} available • Tap to vote',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (tracks.isEmpty) 
              _buildEmptyVotingState(context)
            else 
              _buildVotingTracksList(
                context: context,
                tracks: tracks,
                playlistId: playlistId,
                onLoadData: onLoadData,
                playlistOwnerId: playlistOwnerId,
                isEvent: isEvent,
              ),
            const SizedBox(height: 12),
            _buildAddTrackForVotingButton(
              context: context,
              onSuggestTrackForVoting: onSuggestTrackForVoting,
              votingInfo: votingInfo,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildEmptyVotingState(BuildContext context) => Center(
    child: Column(children: [
      Icon(Icons.music_note, size: 48, color: Colors.grey[400]),
      const SizedBox(height: 12),
      Text('No tracks to vote on', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600])),
      const SizedBox(height: 6),
      Text('Add tracks to start collaborative voting!', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
    ]),
  );

  static Widget _buildVotingTracksList({
    required BuildContext context,
    required List<PlaylistTrack> tracks,
    required String playlistId,
    required VoidCallback onLoadData,
    String? playlistOwnerId,
    bool isEvent = false,
  }) => ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: tracks.length,
    itemBuilder: (context, index) => _buildVotingTrackItem(
      context: context,
      playlistTrack: tracks[index],
      index: index,
      playlistId: playlistId,
      onLoadData: onLoadData,
      playlistOwnerId: playlistOwnerId,
      isEvent: isEvent,
    ),
  );

  static Widget _buildVotingTrackItem({
    required BuildContext context,
    required PlaylistTrack playlistTrack,
    required int index,
    required String playlistId,
    required VoidCallback onLoadData,
    String? playlistOwnerId,
    bool isEvent = false,
  }) {
    final track = playlistTrack.track;
    if (track == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MusicAppResponsive.isSmallScreen(context) ? 4 : 8,
          vertical: 6,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: track.imageUrl != null 
                ? Image.network(
                    track.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildMusicNotePlaceholder(),
                  )
                : _buildMusicNotePlaceholder(),
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 3),
                  Text(
                    track.artist,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (track.album.isNotEmpty) ...[
                    const SizedBox(height: 1),
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
            const SizedBox(width: 8),
            Consumer<VotingProvider>(
              builder: (context, votingProvider, child) {
                final canVote = !votingProvider.hasUserVotedForPlaylist;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: canVote 
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: canVote 
                          ? AppTheme.primary.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canVote) Text(
                        'VOTE',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      if (canVote) const SizedBox(width: 4),
                      TrackVotingControls(
                        playlistId: playlistId,
                        trackId: track.id,
                        trackIndex: index,
                        isCompact: true,
                        isInVotingMode: true, // This is used in voting mode section
                        stats: VoteStats(
                          totalVotes: playlistTrack.points.toInt(),
                          upvotes: playlistTrack.points.toInt(),
                          downvotes: 0,
                          userHasVoted: votingProvider.hasUserVotedForPlaylist,
                          voteScore: playlistTrack.points.toDouble(),
                        ),
                        onVoteSubmitted: onLoadData,
                        playlistOwnerId: playlistOwnerId,
                        isEvent: isEvent,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildAddTrackForVotingButton({
    required BuildContext context,
    required VoidCallback onSuggestTrackForVoting,
    required PlaylistVotingInfo? votingInfo,
  }) => AppWidgets.primaryButton(
    context: context,
    text: 'Suggest Track for Voting',
    icon: Icons.add,
    onPressed: (votingInfo?.canVote ?? true) ? onSuggestTrackForVoting : null,
    isLoading: false,
  );
}

class TrackVotingControls extends StatelessWidget {
  final String playlistId, trackId;
  final int trackIndex;
  final bool isCompact, isEvent, isInVotingMode;
  final VoteStats stats;
  final VoidCallback? onVoteSubmitted;
  final String? playlistOwnerId;
  const TrackVotingControls({
    super.key,
    required this.playlistId,
    required this.trackId,
    required this.trackIndex,
    this.isCompact = false,
    required this.stats,
    this.onVoteSubmitted,
    this.playlistOwnerId,
    this.isEvent = false,
    this.isInVotingMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwner = playlistOwnerId != null && authProvider.userId == playlistOwnerId;
    
    // Non-owners can only vote when in explicit voting mode (green thumbs up)
    // Owners can always see voting controls but with grey thumbs up when not in voting mode
    final canVote = stats.userHasVoted ? false : (isOwner || isInVotingMode);
    final thumbColor = stats.userHasVoted ? Colors.grey : (isInVotingMode ? AppTheme.primary : Colors.grey);
    
    final icon = Icon(Icons.thumb_up, color: thumbColor, size: isCompact ? 18 : null);
    final button = IconButton(
      icon: icon,
      onPressed: canVote ? () => _handleVote(context) : null,
      padding: isCompact ? const EdgeInsets.all(4) : null,
      constraints: isCompact ? const BoxConstraints(minWidth: 30, minHeight: 30) : null,
    );
    final text = Text('${stats.totalVotes}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.bold));
    return Row(mainAxisSize: MainAxisSize.min, children: [button, const SizedBox(width: 2), text]);
  }

  Future<void> _handleVote(BuildContext context) async {
    if (stats.userHasVoted) {
      AppWidgets.showSnackBar(context, 'You have already voted on this playlist', backgroundColor: Colors.orange);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = playlistOwnerId != null && authProvider.userId == playlistOwnerId;
    
    // Additional check: non-owners can only vote in explicit voting mode
    if (!isOwner && !isInVotingMode) {
      AppWidgets.showSnackBar(context, 'Voting is only available in voting mode', backgroundColor: Colors.orange);
      return;
    }

    final votingProvider = Provider.of<VotingProvider>(context, listen: false);
    final token = authProvider.token;
    
    if (token == null) {
      AppWidgets.showSnackBar(context, 'You must be logged in to vote', backgroundColor: Colors.red);
      return;
    }

    if (votingProvider.hasUserVotedForPlaylist) {
      AppWidgets.showSnackBar(context, 'You have already voted on this playlist', backgroundColor: Colors.orange);
      return;
    }

    AppLogger.debug('About to vote - user authenticated: ${authProvider.isLoggedIn}', 'TrackVotingControls');
    final success = await votingProvider.voteForTrackByIndex(
      playlistId: playlistId,
      trackIndex: trackIndex,
      token: token,
      playlistOwnerId: playlistOwnerId,
      currentUserId: authProvider.userId,
      currentUsername: authProvider.username,
    );

    if (success && onVoteSubmitted != null) {
      onVoteSubmitted!();
    } else if (!success && votingProvider.hasError) {
      if (context.mounted) {
        AppWidgets.showSnackBar(context, votingProvider.errorMessage!, backgroundColor: Colors.red);
      }
    }
  }
}

class _CollapsibleVotingSettings extends StatefulWidget {
  final bool isPublicVoting;
  final String votingLicenseType;
  final DateTime? votingStartTime, votingEndTime;
  final ValueChanged<bool> onPublicVotingChanged;
  final ValueChanged<String> onLicenseTypeChanged;
  final Future<void> Function() onApplyVotingSettings;
  final Future<void> Function(bool) onSelectVotingDateTime;
  
  const _CollapsibleVotingSettings({
    required this.isPublicVoting,
    required this.votingLicenseType,
    required this.votingStartTime,
    required this.votingEndTime,
    required this.onPublicVotingChanged,
    required this.onLicenseTypeChanged,
    required this.onApplyVotingSettings,
    required this.onSelectVotingDateTime,
  });

  @override
  State<_CollapsibleVotingSettings> createState() => _CollapsibleVotingSettingsState();
}

class _CollapsibleVotingSettingsState extends State<_CollapsibleVotingSettings> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.settings,
              color: AppTheme.primary,
            ),
            title: Text(
              'Voting Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              _isExpanded ? 'Tap to hide settings' : 'Tap to configure voting rules',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            trailing: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: AppTheme.primary),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  PlaylistVotingWidgets._buildVotingLicenseSettings(
                    context: context,
                    votingLicenseType: widget.votingLicenseType,
                    votingStartTime: widget.votingStartTime,
                    votingEndTime: widget.votingEndTime,
                    onPublicVotingChanged: widget.onPublicVotingChanged,
                    onLicenseTypeChanged: widget.onLicenseTypeChanged,
                    onSelectVotingDateTime: widget.onSelectVotingDateTime,
                  ),
                  const SizedBox(height: 12),
                  AppWidgets.primaryButton(
                    context: context,
                    text: 'Apply Voting Settings',
                    icon: Icons.check,
                    onPressed: widget.onApplyVotingSettings,
                    isLoading: false,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}