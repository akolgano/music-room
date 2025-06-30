// lib/widgets/voting_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/core.dart';
import '../models/voting_models.dart';
import '../providers/voting_provider.dart';
import '../providers/auth_provider.dart';

class VoteButton extends StatelessWidget {
  final VoteType voteType;
  final bool isSelected;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final double size;

  const VoteButton({
    Key? key, 
    required this.voteType, 
    required this.isSelected,
    this.onPressed,
    this.isEnabled = true,
    this.size = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = isSelected 
        ? (voteType == VoteType.upvote ? Colors.green : Colors.grey)
        : (isEnabled ? Colors.grey : Colors.grey.withOpacity(0.5));
    
    final icon = voteType == VoteType.upvote 
        ? (isSelected ? Icons.thumb_up : Icons.thumb_up_outlined)
        : Icons.thumb_down_off_alt; 

    return InkWell(
      onTap: voteType == VoteType.upvote && isEnabled ? onPressed : null,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        padding: EdgeInsets.all(size * 0.2),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}

enum VoteType { upvote, downvote }

class VoteCounter extends StatelessWidget {
  final VoteStats stats;
  final bool showDetailed;
  final double fontSize;

  const VoteCounter({
    Key? key,
    required this.stats,
    this.showDetailed = false,
    this.fontSize = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (showDetailed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.thumb_up, color: Colors.green, size: fontSize + 2),
              const SizedBox(width: 4),
              Text(
                '${stats.upvotes}',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Downvotes not supported',
            style: TextStyle(
              color: Colors.grey,
              fontSize: fontSize - 2,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: stats.scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stats.scoreColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up, 
            color: stats.scoreColor,
            size: fontSize + 2,
          ),
          const SizedBox(width: 4),
          Text(
            '+${stats.upvotes}', 
            style: TextStyle(
              color: stats.scoreColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class TrackVotingControls extends StatelessWidget {
  final String playlistId;
  final String trackId;
  final int? trackIndex;
  final VoteStats? stats;
  final bool isCompact;
  final VoidCallback? onVoteSubmitted;

  const TrackVotingControls({
    Key? key,
    required this.playlistId,
    required this.trackId,
    this.trackIndex,
    this.stats,
    this.isCompact = false,
    this.onVoteSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<VotingProvider, AuthProvider>(
      builder: (context, votingProvider, authProvider, _) {
        final canVote = votingProvider.canVote;

        int? effectiveIndex = trackIndex;
        if (effectiveIndex == null && trackId.startsWith('track_')) {
          effectiveIndex = int.tryParse(trackId.split('_').last);
        }

        final userVote = effectiveIndex != null 
            ? votingProvider.getUserVoteByIndex(effectiveIndex)
            : votingProvider.getUserVote(trackId);

        final trackStats = stats ?? (effectiveIndex != null 
            ? votingProvider.getTrackVotesByIndex(effectiveIndex)
            : votingProvider.getTrackVotes(trackId));

        final currentPoints = effectiveIndex != null ? votingProvider.getTrackPoints(effectiveIndex) : 0;

        final effectiveStats = trackStats ?? VoteStats(
          totalVotes: 0,
          upvotes: 0,
          downvotes: 0,
          userHasVoted: userVote != null,
          userVoteValue: userVote,
          voteScore: currentPoints.toDouble(),
        );

        if (isCompact) {
          return _buildCompactControls(
            context, votingProvider, authProvider, canVote, userVote, effectiveStats, effectiveIndex, currentPoints
          );
        }

        return _buildFullControls(
          context, votingProvider, authProvider, canVote, userVote, effectiveStats, effectiveIndex, currentPoints
        );
      },
    );
  }

  Widget _buildCompactControls(
    BuildContext context,
    VotingProvider votingProvider,
    AuthProvider authProvider,
    bool canVote,
    int? userVote,
    VoteStats trackStats,
    int? trackIndex,
    int currentPoints,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        VoteButton(
          voteType: VoteType.upvote,
          isSelected: userVote == 1,
          isEnabled: canVote && userVote == null,
          size: 16,
          onPressed: canVote && userVote == null 
              ? () => _handleVote(votingProvider, authProvider, trackIndex, 1) 
              : null,
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getPointsColor(currentPoints).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getPointsColor(currentPoints).withOpacity(0.5)),
          ),
          child: Text(
            '+$currentPoints', 
            style: TextStyle(
              color: _getPointsColor(currentPoints),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildFullControls(
    BuildContext context,
    VotingProvider votingProvider,
    AuthProvider authProvider,
    bool canVote,
    int? userVote,
    VoteStats trackStats,
    int? trackIndex,
    int currentPoints,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getPointsColor(currentPoints).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getPointsColor(currentPoints).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  color: _getPointsColor(currentPoints),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '+$currentPoints points', 
                  style: TextStyle(
                    color: _getPointsColor(currentPoints),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              VoteButton(
                voteType: VoteType.upvote,
                isSelected: userVote == 1,
                isEnabled: canVote && userVote == null,
                onPressed: canVote && userVote == null 
                    ? () => _handleVote(votingProvider, authProvider, trackIndex, 1) 
                    : null,
              ),
              Text(
                userVote != null ? 'You voted' : 'Vote for this track',
                style: TextStyle(
                  color: userVote != null ? Colors.green : Colors.white70,
                  fontSize: 12,
                ),
              ),
              Icon(
                Icons.info_outline,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
          if (!canVote || userVote != null) ...[
            const SizedBox(height: 8),
            Text(
              userVote != null ? 'You have voted' : votingProvider.getVotingStatusMessage(),
              style: TextStyle(
                color: userVote != null ? Colors.green : Colors.orange,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Color _getPointsColor(int points) {
    if (points > 0) return Colors.green;
    return Colors.grey; 
  }

  void _handleVote(VotingProvider votingProvider, AuthProvider authProvider, int? trackIndex, int voteValue) async {
    if (trackIndex != null && voteValue > 0) { 
      votingProvider.setUserVote(trackIndex, voteValue);
      final success = await votingProvider.upvoteTrackByIndex(playlistId, trackIndex, authProvider.token!);
      if (success && onVoteSubmitted != null) onVoteSubmitted!();
      if (!success) {
        print('Vote failed, should revert UI state');
      }
    }
  }
}

class VotingRestrictionsCard extends StatelessWidget {
  final VotingRestrictions restrictions;

  const VotingRestrictionsCard({Key? key, required this.restrictions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final permission = restrictions.permission;
    Color cardColor;
    IconData cardIcon;
    String title;

    switch (permission) {
      case VotingPermission.allowed:
        cardColor = Colors.green;
        cardIcon = Icons.how_to_vote;
        title = 'Voting Enabled (Upvotes Only)'; 
        break;
      case VotingPermission.notInvited:
        cardColor = Colors.orange;
        cardIcon = Icons.block;
        title = 'Invitation Required';
        break;
      case VotingPermission.outsideTimeWindow:
        cardColor = Colors.blue;
        cardIcon = Icons.access_time;
        title = 'Time Restricted';
        break;
      case VotingPermission.outsideLocation:
        cardColor = Colors.purple;
        cardIcon = Icons.location_on;
        title = 'Location Restricted';
        break;
      case VotingPermission.noPermission:
        cardColor = Colors.red;
        cardIcon = Icons.no_accounts;
        title = 'Voting Disabled';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(cardIcon, color: cardColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: cardColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            restrictions.restrictionMessage,
            style: TextStyle(
              color: cardColor,
              fontSize: 14,
            ),
          ),
          if (restrictions.licenseType == 'location_time') ...[
            const SizedBox(height: 8),
            _buildTimeLocationDetails(cardColor),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeLocationDetails(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (restrictions.voteStartTime != null && restrictions.voteEndTime != null) ...[
          Row(
            children: [
              Icon(Icons.schedule, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                'Voting hours: ${_formatTime(restrictions.voteStartTime!)} - ${_formatTime(restrictions.voteEndTime!)}',
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        if (restrictions.allowedRadiusMeters != null) ...[
          Row(
            children: [
              Icon(Icons.location_on, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                'Range: ${restrictions.allowedRadiusMeters}m from location',
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class PlaylistVotingBanner extends StatelessWidget {
  final String playlistId;

  const PlaylistVotingBanner({
    Key? key,
    required this.playlistId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<VotingProvider>(
      builder: (context, votingProvider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.how_to_vote, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Upvoting Available', 
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class VotingStatsCard extends StatelessWidget {
  final Map<String, VoteStats> trackVotes;

  const VotingStatsCard({
    Key? key,
    required this.trackVotes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (trackVotes.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalVotes = trackVotes.values.fold(0, (sum, stats) => sum + stats.totalVotes);
    final topTrack = trackVotes.entries
        .where((entry) => entry.value.totalVotes > 0)
        .fold<MapEntry<String, VoteStats>?>(null, (prev, current) {
      if (prev == null) return current;
      return current.value.voteScore > prev.value.voteScore ? current : prev;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.poll, color: AppTheme.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Voting Statistics (Upvotes Only)', 
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Upvotes', totalVotes.toString(), Icons.thumb_up), 
              _buildStatItem('Tracks', trackVotes.length.toString(), Icons.music_note),
              if (topTrack != null) 
                _buildStatItem('Top Score', topTrack.value.voteScore.toStringAsFixed(1), Icons.star),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
