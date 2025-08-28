import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:music_room/models/voting_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Vote Model Tests', () {
    late DateTime testDate;
    
    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0);
    });

    test('should create Vote instance with required parameters', () {
      final vote = Vote(
        id: '1',
        userId: 'user123',
        trackId: 'track789',
        voteValue: 1,
        createdAt: testDate,
      );
      
      expect(vote.id, '1');
      expect(vote.userId, 'user123');
      expect(vote.trackId, 'track789');
      expect(vote.voteValue, 1);
      expect(vote.createdAt, testDate);
    });

    test('should create Vote from JSON', () {
      final json = {
        'id': '2',
        'user_id': 'user456',
        'track_id': 'track321',
        'vote_value': -1,
        'created_at': '2024-01-01T12:00:00.000Z',
      };
      
      final vote = Vote.fromJson(json);
      
      expect(vote.id, '2');
      expect(vote.userId, 'user456');
      expect(vote.trackId, 'track321');
      expect(vote.voteValue, -1);
      expect(vote.createdAt.year, 2024);
    });

    test('should convert Vote to JSON', () {
      final vote = Vote(
        id: '3',
        userId: 'user789',
        trackId: 'track654',
        voteValue: 1,
        createdAt: testDate,
      );
      
      final json = vote.toJson();
      
      expect(json['id'], '3');
      expect(json['user_id'], 'user789');
      expect(json['track_id'], 'track654');
      expect(json['vote_value'], 1);
      expect(json['created_at'], testDate.toIso8601String());
    });

    test('should handle different vote values', () {
      final upvote = Vote(
        id: '4',
        userId: 'user1',
        trackId: 'track1',
        voteValue: 1,
        createdAt: testDate,
      );
      
      final downvote = Vote(
        id: '5',
        userId: 'user2',
        trackId: 'track2',
        voteValue: -1,
        createdAt: testDate,
      );
      
      final neutralVote = Vote(
        id: '6',
        userId: 'user3',
        trackId: 'track3',
        voteValue: 0,
        createdAt: testDate,
      );
      
      expect(upvote.voteValue, 1);
      expect(downvote.voteValue, -1);
      expect(neutralVote.voteValue, 0);
    });
  });

  group('VoteStats Model Tests', () {
    test('should create VoteStats instance with required parameters', () {
      final stats = VoteStats(
        totalVotes: 10,
        upvotes: 7,
        downvotes: 3,
        userHasVoted: true,
        userVoteValue: 1,
        voteScore: 0.7,
      );
      
      expect(stats.totalVotes, 10);
      expect(stats.upvotes, 7);
      expect(stats.downvotes, 3);
      expect(stats.userHasVoted, true);
      expect(stats.userVoteValue, 1);
      expect(stats.voteScore, 0.7);
    });

    test('should calculate net votes correctly', () {
      final stats = VoteStats(
        totalVotes: 20,
        upvotes: 15,
        downvotes: 5,
        userHasVoted: false,
        voteScore: 0.75,
      );
      
      expect(stats.netVotes, 10);
    });

    test('should display correct text for different vote counts', () {
      final noVotes = VoteStats(
        totalVotes: 0,
        upvotes: 0,
        downvotes: 0,
        userHasVoted: false,
        voteScore: 0.0,
      );
      
      final oneVote = VoteStats(
        totalVotes: 1,
        upvotes: 1,
        downvotes: 0,
        userHasVoted: true,
        userVoteValue: 1,
        voteScore: 1.0,
      );
      
      final multipleVotes = VoteStats(
        totalVotes: 42,
        upvotes: 30,
        downvotes: 12,
        userHasVoted: false,
        voteScore: 0.71,
      );
      
      expect(noVotes.displayText, 'No votes');
      expect(oneVote.displayText, '1 vote');
      expect(multipleVotes.displayText, '42 votes');
    });

    test('should determine correct score color based on vote score', () {
      final highScore = VoteStats(
        totalVotes: 100,
        upvotes: 80,
        downvotes: 20,
        userHasVoted: false,
        voteScore: 0.8,
      );
      
      final mediumScore = VoteStats(
        totalVotes: 100,
        upvotes: 50,
        downvotes: 50,
        userHasVoted: false,
        voteScore: 0.5,
      );
      
      final lowScore = VoteStats(
        totalVotes: 100,
        upvotes: 20,
        downvotes: 80,
        userHasVoted: false,
        voteScore: 0.2,
      );
      
      expect(highScore.scoreColor, Colors.green);
      expect(mediumScore.scoreColor, Colors.orange);
      expect(lowScore.scoreColor, Colors.red);
    });

    test('should create VoteStats from JSON', () {
      final json = {
        'total_votes': 25,
        'upvotes': 18,
        'downvotes': 7,
        'user_has_voted': true,
        'user_vote_value': -1,
        'vote_score': 0.72,
      };
      
      final stats = VoteStats.fromJson(json);
      
      expect(stats.totalVotes, 25);
      expect(stats.upvotes, 18);
      expect(stats.downvotes, 7);
      expect(stats.userHasVoted, true);
      expect(stats.userVoteValue, -1);
      expect(stats.voteScore, 0.72);
    });

    test('should handle missing optional fields in JSON', () {
      final json = {
        'total_votes': 5,
        'user_has_voted': false,
      };
      
      final stats = VoteStats.fromJson(json);
      
      expect(stats.totalVotes, 5);
      expect(stats.upvotes, 0);
      expect(stats.downvotes, 0);
      expect(stats.userHasVoted, false);
      expect(stats.userVoteValue, null);
      expect(stats.voteScore, 0.0);
    });

    test('should convert VoteStats to JSON', () {
      final stats = VoteStats(
        totalVotes: 15,
        upvotes: 10,
        downvotes: 5,
        userHasVoted: true,
        userVoteValue: 1,
        voteScore: 0.67,
      );
      
      final json = stats.toJson();
      
      expect(json['total_votes'], 15);
      expect(json['upvotes'], 10);
      expect(json['downvotes'], 5);
      expect(json['user_has_voted'], true);
      expect(json['user_vote_value'], 1);
      expect(json['vote_score'], 0.67);
    });
  });

  group('VotingRestrictions Model Tests', () {
    test('should create VotingRestrictions with all parameters', () {
      final restrictions = VotingRestrictions(
        licenseType: 'open',
        isInvited: true,
        isInTimeWindow: true,
        isInLocation: true,
        voteStartTime: DateTime(2024, 1, 1, 9, 0),
        voteEndTime: DateTime(2024, 1, 1, 17, 0),
        latitude: 40.7128,
        longitude: -74.0060,
        allowedRadiusMeters: 1000,
      );
      
      expect(restrictions.licenseType, 'open');
      expect(restrictions.isInvited, true);
      expect(restrictions.isInTimeWindow, true);
      expect(restrictions.isInLocation, true);
      expect(restrictions.voteStartTime, isNotNull);
      expect(restrictions.voteEndTime, isNotNull);
      expect(restrictions.latitude, 40.7128);
      expect(restrictions.longitude, -74.0060);
      expect(restrictions.allowedRadiusMeters, 1000);
    });

    test('should determine correct permission for open license', () {
      final restrictions = VotingRestrictions(
        licenseType: 'open',
        isInvited: true,
        isInTimeWindow: true,
        isInLocation: true,
      );
      
      expect(restrictions.permission, VotingPermission.allowed);
    });

    test('should determine correct permission for invite_only license', () {
      final invitedUser = VotingRestrictions(
        licenseType: 'invite_only',
        isInvited: true,
        isInTimeWindow: true,
        isInLocation: true,
      );
      
      final uninvitedUser = VotingRestrictions(
        licenseType: 'invite_only',
        isInvited: false,
        isInTimeWindow: true,
        isInLocation: true,
      );
      
      expect(invitedUser.permission, VotingPermission.allowed);
      expect(uninvitedUser.permission, VotingPermission.notInvited);
    });

    test('should determine correct permission for location_time license', () {
      final allowedUser = VotingRestrictions(
        licenseType: 'location_time',
        isInvited: true,
        isInTimeWindow: true,
        isInLocation: true,
      );
      
      final notInvited = VotingRestrictions(
        licenseType: 'location_time',
        isInvited: false,
        isInTimeWindow: true,
        isInLocation: true,
      );
      
      final outsideTime = VotingRestrictions(
        licenseType: 'location_time',
        isInvited: true,
        isInTimeWindow: false,
        isInLocation: true,
      );
      
      final outsideLocation = VotingRestrictions(
        licenseType: 'location_time',
        isInvited: true,
        isInTimeWindow: true,
        isInLocation: false,
      );
      
      expect(allowedUser.permission, VotingPermission.allowed);
      expect(notInvited.permission, VotingPermission.notInvited);
      expect(outsideTime.permission, VotingPermission.outsideTimeWindow);
      expect(outsideLocation.permission, VotingPermission.outsideLocation);
    });
  });
}