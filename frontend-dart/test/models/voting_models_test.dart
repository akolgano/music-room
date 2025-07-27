import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:music_room/models/voting_models.dart';

void main() {
  group('Voting Models Tests', () {
    test('VoteStats should track vote counts correctly', () {
      // print('Testing: VoteStats should track vote counts correctly');
      const voteStats = VoteStats(
        totalVotes: 7,
        upvotes: 5,
        downvotes: 2,
        userHasVoted: false,
        voteScore: 0.7,
      );
      
      expect(voteStats.totalVotes, 7);
      expect(voteStats.upvotes, 5);
      expect(voteStats.downvotes, 2);
      expect(voteStats.userHasVoted, false);
      expect(voteStats.voteScore, 0.7);
    });

    test('VoteStats should calculate net votes correctly', () {
      // print('Testing: VoteStats should calculate net votes correctly');
      const voteStats = VoteStats(
        totalVotes: 13,
        upvotes: 10,
        downvotes: 3,
        userHasVoted: true,
        userVoteValue: 1,
        voteScore: 0.8,
      );
      
      expect(voteStats.netVotes, 7);
      expect(voteStats.userVoteValue, 1);
    });

    test('VoteStats should handle zero votes', () {
      // print('Testing: VoteStats should handle zero votes');
      const voteStats = VoteStats(
        totalVotes: 0,
        upvotes: 0,
        downvotes: 0,
        userHasVoted: false,
        voteScore: 0.0,
      );
      
      expect(voteStats.netVotes, 0);
      expect(voteStats.totalVotes, 0);
      expect(voteStats.displayText, 'No votes');
    });

    test('VoteStats should create from JSON correctly', () {
      // print('Testing: VoteStats should create from JSON correctly');
      final json = {
        'total_votes': 10,
        'upvotes': 8,
        'downvotes': 2,
        'user_has_voted': true,
        'user_vote_value': 1,
        'vote_score': 0.8
      };
      
      final voteStats = VoteStats.fromJson(json);
      
      expect(voteStats.totalVotes, 10);
      expect(voteStats.upvotes, 8);
      expect(voteStats.downvotes, 2);
      expect(voteStats.userHasVoted, true);
      expect(voteStats.userVoteValue, 1);
      expect(voteStats.voteScore, 0.8);
    });

    test('VoteStats should handle display text correctly', () {
      // print('Testing: VoteStats should handle display text correctly');
      const oneVote = VoteStats(
        totalVotes: 1,
        upvotes: 1,
        downvotes: 0,
        userHasVoted: false,
        voteScore: 1.0,
      );
      
      const multipleVotes = VoteStats(
        totalVotes: 5,
        upvotes: 3,
        downvotes: 2,
        userHasVoted: false,
        voteScore: 0.6,
      );
      
      expect(oneVote.displayText, '1 vote');
      expect(multipleVotes.displayText, '5 votes');
    });

    test('VoteStats should provide correct score color', () {
      // print('Testing: VoteStats should provide correct score color');
      const highScore = VoteStats(
        totalVotes: 10,
        upvotes: 8,
        downvotes: 2,
        userHasVoted: false,
        voteScore: 0.8,
      );
      
      const mediumScore = VoteStats(
        totalVotes: 10,
        upvotes: 5,
        downvotes: 5,
        userHasVoted: false,
        voteScore: 0.5,
      );
      
      const lowScore = VoteStats(
        totalVotes: 10,
        upvotes: 2,
        downvotes: 8,
        userHasVoted: false,
        voteScore: 0.2,
      );
      
      expect(highScore.scoreColor, Colors.green);
      expect(mediumScore.scoreColor, Colors.orange);
      expect(lowScore.scoreColor, Colors.red);
    });

    test('Vote should serialize and deserialize correctly', () {
      // print('Testing: Vote should serialize and deserialize correctly');
      final vote = Vote(
        id: 'vote123',
        trackId: 'track456',
        userId: 'user789',
        voteValue: 1,
        createdAt: DateTime(2023, 5, 15, 10, 30),
      );
      
      final json = vote.toJson();
      final reconstructed = Vote.fromJson(json);
      
      expect(reconstructed.id, vote.id);
      expect(reconstructed.trackId, vote.trackId);
      expect(reconstructed.userId, vote.userId);
      expect(reconstructed.voteValue, vote.voteValue);
      expect(reconstructed.createdAt, vote.createdAt);
    });
  });
}