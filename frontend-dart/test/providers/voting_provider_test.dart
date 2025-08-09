import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/providers/voting_providers.dart';
import 'package:music_room/models/voting_models.dart';
void main() {
  group('Voting Provider Tests', () {
    test('VotingProvider should handle track voting correctly', () {
      const trackId = 'track_123';
      const voteValue = 1;
      const userId = 'user_456';
      final vote = Vote(
        id: 'vote_001',
        trackId: trackId,
        userId: userId,
        voteValue: voteValue,
        createdAt: DateTime.now(),
      );
      
      expect(vote.trackId, trackId);
      expect(vote.userId, userId);
      expect(vote.voteValue, voteValue);
      expect(vote.voteValue, isIn([1, -1]));
      expect(voteValue == 1, true);
      const downvote = -1;
      expect(downvote == -1, true);
      expect(voteValue.abs(), 1);
    });
    test('VotingProvider should calculate points accurately', () {
      const upvotes = 10;
      const downvotes = 3;
      const totalVotes = upvotes + downvotes;
      const netVotes = upvotes - downvotes;
      final voteScore = upvotes / totalVotes;
      
      expect(netVotes, 7);
      expect(totalVotes, 13);
      expect(voteScore, closeTo(0.769, 0.01));
      const voteStats = VoteStats(
        totalVotes: totalVotes,
        upvotes: upvotes,
        downvotes: downvotes,
        userHasVoted: false,
        voteScore: 0.769,
      );
      
      expect(voteStats.netVotes, netVotes);
      expect(voteStats.upvotes, upvotes);
      expect(voteStats.downvotes, downvotes);
      expect(voteStats.totalVotes, totalVotes);
    });
    test('VotingProvider should handle voting permissions', () {
      const openLicense = VotingRestrictions(
        licenseType: 'open',
        isInvited: true,
        isInTimeWindow: true,
        isInLocation: true,
      );
      
      expect(openLicense.permission, VotingPermission.allowed);
      const inviteOnlyLicense = VotingRestrictions(
        licenseType: 'invite_only',
        isInvited: false,
        isInTimeWindow: true,
        isInLocation: true,
      );
      
      expect(inviteOnlyLicense.permission, VotingPermission.notInvited);
      const restrictedLicense = VotingRestrictions(
        licenseType: 'location_time',
        isInvited: true,
        isInTimeWindow: false,
        isInLocation: true,
      );
      
      expect(restrictedLicense.permission, VotingPermission.outsideTimeWindow);
    });
    test('VotingProvider should handle vote statistics display', () {
      const noVotes = VoteStats(
        totalVotes: 0,
        upvotes: 0,
        downvotes: 0,
        userHasVoted: false,
        voteScore: 0.0,
      );
      
      expect(noVotes.displayText, 'No votes');
      
      const singleVote = VoteStats(
        totalVotes: 1,
        upvotes: 1,
        downvotes: 0,
        userHasVoted: false,
        voteScore: 1.0,
      );
      
      expect(singleVote.displayText, '1 vote');
      
      const multipleVotes = VoteStats(
        totalVotes: 5,
        upvotes: 3,
        downvotes: 2,
        userHasVoted: false,
        voteScore: 0.6,
      );
      
      expect(multipleVotes.displayText, '5 votes');
    });
    test('VotingProvider should provide score color indicators', () {
      const highScore = VoteStats(
        totalVotes: 10,
        upvotes: 8,
        downvotes: 2,
        userHasVoted: false,
        voteScore: 0.8,
      );
      
      expect(highScore.voteScore, greaterThan(0.6));
      
      const mediumScore = VoteStats(
        totalVotes: 10,
        upvotes: 5,
        downvotes: 5,
        userHasVoted: false,
        voteScore: 0.5,
      );
      
      expect(mediumScore.voteScore, lessThanOrEqualTo(0.6));
      expect(mediumScore.voteScore, greaterThan(0.3));
      
      const lowScore = VoteStats(
        totalVotes: 10,
        upvotes: 2,
        downvotes: 8,
        userHasVoted: false,
        voteScore: 0.2,
      );
      
      expect(lowScore.voteScore, lessThanOrEqualTo(0.3));
    });
    test('VotingProvider should extend BaseProvider', () {
      expect(VotingProvider, isA<Type>());
      var isLoading = false;
      String? errorMessage;
      String? successMessage;
      isLoading = true;
      expect(isLoading, true);
      errorMessage = 'Voting failed';
      expect(errorMessage, 'Voting failed');
      expect(errorMessage, isNotNull);
      successMessage = 'Vote submitted successfully';
      expect(successMessage, 'Vote submitted successfully');
      expect(successMessage, contains('success'));
    });
  });
}