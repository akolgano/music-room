import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/music_models.dart';
import '../models/voting_models.dart';
import '../widgets/app_widgets.dart';
import '../core/theme_core.dart';
import '../core/responsive_core.dart';
import '../providers/voting_providers.dart';
import '../providers/auth_providers.dart';

class PlaylistVotingWidgets {
  static Widget _buildMusicNotePlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.music_note,
        color: AppTheme.primary,
        size: 24,
      ),
    );
  }

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
  }) {
    return [
      AppWidgets.infoBanner(
        title: 'Voting Mode Active',
        message: 'Vote for one track to boost its ranking! ${isOwner ? 'Configure voting settings below.' : 'Choose your favorite track.'}',
        icon: Icons.how_to_vote,
      ),
      SizedBox(height: MusicAppResponsive.getSpacing(context)),
      if (isOwner) _buildVotingSettings(
        context: context,
        isPublicVoting: isPublicVoting,
        votingLicenseType: votingLicenseType,
        votingStartTime: votingStartTime,
        votingEndTime: votingEndTime,
        onPublicVotingChanged: onPublicVotingChanged,
        onLicenseTypeChanged: onLicenseTypeChanged,
        onApplyVotingSettings: onApplyVotingSettings,
        onSelectVotingDateTime: onSelectVotingDateTime,
      ),
      if (votingInfo != null) _buildVotingStats(context, votingInfo),
    ];
  }

  static Widget _buildVotingSettings({
    required BuildContext context,
    required bool isPublicVoting,
    required String votingLicenseType,
    required DateTime? votingStartTime,
    required DateTime? votingEndTime,
    required ValueChanged<bool> onPublicVotingChanged,
    required ValueChanged<String> onLicenseTypeChanged,
    required Future<void> Function() onApplyVotingSettings,
    required Future<void> Function(bool) onSelectVotingDateTime,
  }) {
    return AppTheme.buildFormCard(
      title: 'Voting Configuration',
      titleIcon: Icons.settings,
      child: Column(
        children: [
          AppWidgets.switchTile(
            value: isPublicVoting,
            onChanged: onPublicVotingChanged,
            title: 'Public Voting',
            subtitle: isPublicVoting 
              ? 'Anyone can find and vote on this playlist' 
              : 'Only invited users can vote',
            icon: isPublicVoting ? Icons.public : Icons.lock,
          ),
          const SizedBox(height: 12),
          _buildVotingLicenseSettings(
            context: context,
            votingLicenseType: votingLicenseType,
            votingStartTime: votingStartTime,
            votingEndTime: votingEndTime,
            onPublicVotingChanged: onPublicVotingChanged,
        onLicenseTypeChanged: onLicenseTypeChanged,
            onSelectVotingDateTime: onSelectVotingDateTime,
          ),
          const SizedBox(height: 12),
          AppWidgets.primaryButton(
            context: context,
            text: 'Apply Voting Settings',
            icon: Icons.check,
            onPressed: onApplyVotingSettings,
            isLoading: false,
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
        RadioListTile<String>(
          title: const Text('Open Voting'),
          subtitle: const Text('Anyone can vote'),
          value: 'open',
          groupValue: votingLicenseType,
          onChanged: (value) => value != null ? onLicenseTypeChanged(value) : null,
        ),
        RadioListTile<String>(
          title: const Text('Invite Only'),
          subtitle: const Text('Only invited users can vote'),
          value: 'invite_only',
          groupValue: votingLicenseType,
          onChanged: (value) => value != null ? onLicenseTypeChanged(value) : null,
        ),
        RadioListTile<String>(
          title: const Text('Location & Time Restricted'),
          subtitle: const Text('Vote only at specific location and time'),
          value: 'location_time',
          groupValue: votingLicenseType,
          onChanged: (value) => value != null ? onLicenseTypeChanged(value) : null,
        ),
        if (votingLicenseType == 'location_time') _buildVotingTimeSettings(
          context: context,
          votingStartTime: votingStartTime,
          votingEndTime: votingEndTime,
          onSelectVotingDateTime: onSelectVotingDateTime,
        ),
      ],
    );
  }

  static Widget _buildVotingTimeSettings({
    required BuildContext context,
    required DateTime? votingStartTime,
    required DateTime? votingEndTime,
    required Future<void> Function(bool) onSelectVotingDateTime,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        children: [
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
  }) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 4,
      shadowColor: ThemeUtils.getPrimary(context).withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.how_to_vote, color: ThemeUtils.getPrimary(context), size: 20),
                const SizedBox(width: 6),
                Text('Track Voting', style: ThemeUtils.getSubheadingStyle(context)),
                const Spacer(),
                Text(
                  '${tracks.length} tracks',
                  style: ThemeUtils.getCaptionStyle(context),
                ),
              ],
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

  static Widget _buildEmptyVotingState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.music_note,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No tracks to vote on',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add tracks to start collaborative voting!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildVotingTracksList({
    required BuildContext context,
    required List<PlaylistTrack> tracks,
    required String playlistId,
    required VoidCallback onLoadData,
  }) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tracks.length,
      itemBuilder: (context, index) => _buildVotingTrackItem(
        context: context,
        playlistTrack: tracks[index],
        index: index,
        playlistId: playlistId,
        onLoadData: onLoadData,
      ),
    );
  }

  static Widget _buildVotingTrackItem({
    required BuildContext context,
    required PlaylistTrack playlistTrack,
    required int index,
    required String playlistId,
    required VoidCallback onLoadData,
  }) {
    final track = playlistTrack.track;
    if (track == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
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
              builder: (context, votingProvider, child) => TrackVotingControls(
                playlistId: playlistId,
                trackId: track.id,
                trackIndex: index,
                isCompact: true,
                stats: VoteStats(
                  totalVotes: playlistTrack.points.toInt(),
                  upvotes: playlistTrack.points.toInt(),
                  downvotes: 0,
                  userHasVoted: votingProvider.hasUserVotedForPlaylist,
                  voteScore: playlistTrack.points.toDouble(),
                ),
                onVoteSubmitted: onLoadData,
              ),
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
  }) {
    final canSuggest = votingInfo?.canVote ?? true;
    
    return AppWidgets.primaryButton(
      context: context,
      text: 'Suggest Track for Voting',
      icon: Icons.add,
      onPressed: canSuggest ? onSuggestTrackForVoting : null,
      isLoading: false,
    );
  }
}

class TrackVotingControls extends StatelessWidget {
  final String playlistId;
  final String trackId;
  final int trackIndex;
  final bool isCompact;
  final VoteStats stats;
  final VoidCallback? onVoteSubmitted;

  const TrackVotingControls({
    super.key,
    required this.playlistId,
    required this.trackId,
    required this.trackIndex,
    this.isCompact = false,
    required this.stats,
    this.onVoteSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.thumb_up,
              color: stats.userHasVoted ? Colors.grey : AppTheme.primary,
              size: 18,
            ),
            onPressed: stats.userHasVoted ? null : () => _handleVote(context),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
          Text(
            '${stats.totalVotes}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        IconButton(
          icon: Icon(
            Icons.thumb_up,
            color: stats.userHasVoted ? Colors.grey : AppTheme.primary,
          ),
          onPressed: stats.userHasVoted ? null : () => _handleVote(context),
        ),
        Text(
          '${stats.totalVotes}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _handleVote(BuildContext context) async {
    if (stats.userHasVoted) {
      AppWidgets.showSnackBar(context, 'You have already voted on this playlist', backgroundColor: Colors.orange);
      return;
    }

    final votingProvider = Provider.of<VotingProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    if (token == null) {
      AppWidgets.showSnackBar(context, 'You must be logged in to vote', backgroundColor: Colors.red);
      return;
    }

    if (votingProvider.hasUserVotedForPlaylist) {
      AppWidgets.showSnackBar(context, 'You have already voted on this playlist', backgroundColor: Colors.orange);
      return;
    }

    final success = await votingProvider.voteForTrackByIndex(
      playlistId: playlistId,
      trackIndex: trackIndex,
      token: token,
    );

    if (success && onVoteSubmitted != null) {
      onVoteSubmitted!();
    } else if (!success && votingProvider.hasError) {
      AppWidgets.showSnackBar(context, votingProvider.errorMessage!, backgroundColor: Colors.red);
    }
  }
}