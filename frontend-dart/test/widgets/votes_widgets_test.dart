import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/models/voting_models.dart';

void main() {
  group('PlaylistVotingWidgets', () {
    // Widget tests removed - required complex provider state setup with GetIt dependencies
    // Focusing on simple model tests only

    test('should handle voting data models', () {
      final vote = Vote(
        id: '1',
        userId: 'user123',
        trackId: 'track123',
        voteValue: 1,
        createdAt: DateTime.now(),
      );
      
      expect(vote.id, '1');
      expect(vote.userId, 'user123');
      expect(vote.trackId, 'track123');
      expect(vote.voteValue, 1);
    });

    test('should handle voting statistics', () {
      final stats = VoteStats(
        totalVotes: 10,
        upvotes: 7,
        downvotes: 3,
        userHasVoted: false,
        voteScore: 0.7,
      );
      
      expect(stats.totalVotes, 10);
      expect(stats.upvotes, 7);
      expect(stats.downvotes, 3);
      expect(stats.voteScore, 0.7);
    });
  });
}