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
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 0 ? constraints.maxWidth : 80.0;
        
        return Container(
          width: maxWidth,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: InkWell(
                  onTap: canVote && userVote == null 
                      ? () => _handleVote(votingProvider, authProvider, trackIndex, 1) 
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Icon(
                    userVote == 1 ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: userVote == 1 
                        ? Colors.green 
                        : (canVote && userVote == null ? _getPointsColor(currentPoints) : Colors.grey),
                    size: 16,
                  ),
                ),
              ),
              
              const SizedBox(width: 4),
              
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPointsColor(currentPoints).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getPointsColor(currentPoints).withOpacity(0.5)),
                  ),
                  child: Text(
                    '+$currentPoints', 
                    style: TextStyle(
                      color: _getPointsColor(currentPoints),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
      constraints: const BoxConstraints(maxWidth: 200), 
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                Flexible(
                  child: Text(
                    '+$currentPoints points', 
                    style: TextStyle(
                      color: _getPointsColor(currentPoints),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
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
              Flexible(
                child: Text(
                  userVote != null ? 'You voted' : 'Vote for this track',
                  style: TextStyle(
                    color: userVote != null ? Colors.green : Colors.white70,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              Icon(
                Icons.info_outline,
                color: Colors.grey,
                size: 16,
              ),
            ],
          ),
          if (!canVote || userVote != null) ...[
            const SizedBox(height: 8),
            Text(
              userVote != null ? 'You have voted' : votingProvider.getVotingStatusMessage(),
              style: TextStyle(color: userVote != null ? Colors.green : Colors.orange, fontSize: 9),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
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
      if (!success) print('Vote failed, should revert UI state');
    }
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
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
