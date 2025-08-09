import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/widgets/votes_widgets.dart';
import 'package:music_room/models/voting_models.dart';

void main() {
  group('Voting Widgets Tests', () {
    Widget createTestWidget(Widget child) {
      return MaterialApp(home: Scaffold(body: child));
    }

    group('TrackVotingControls', () {
      testWidgets('should display voting controls', (WidgetTester tester) async {
        const controls = TrackVotingControls(
          playlistId: 'playlist1',
          trackId: 'track1',
          trackIndex: 0,
          stats: VoteStats(
            totalVotes: 5,
            upvotes: 3,
            downvotes: 2,
            userHasVoted: false,
            voteScore: 1.0,
          ),
        );

        await tester.pumpWidget(createTestWidget(controls));

        expect(find.byType(TrackVotingControls), findsOneWidget);
      });

      testWidgets('should show compact controls when isCompact is true', (WidgetTester tester) async {
        const controls = TrackVotingControls(
          playlistId: 'playlist1',
          trackId: 'track1',
          trackIndex: 0,
          isCompact: true,
          stats: VoteStats(
            totalVotes: 5,
            upvotes: 3,
            downvotes: 2,
            userHasVoted: false,
            voteScore: 1.0,
          ),
        );

        await tester.pumpWidget(createTestWidget(controls));

        expect(find.byType(TrackVotingControls), findsOneWidget);
      });

      testWidgets('should display user voted state', (WidgetTester tester) async {
        const controls = TrackVotingControls(
          playlistId: 'playlist1',
          trackId: 'track1',
          trackIndex: 0,
          stats: VoteStats(
            totalVotes: 1,
            upvotes: 1,
            downvotes: 0,
            userHasVoted: true,
            voteScore: 1.0,
          ),
        );

        await tester.pumpWidget(createTestWidget(controls));

        expect(find.byType(TrackVotingControls), findsOneWidget);
      });

      testWidgets('should handle vote controls rendering', (WidgetTester tester) async {
        const controls = TrackVotingControls(
          playlistId: 'playlist1',
          trackId: 'track_0',
          trackIndex: 0,
          stats: VoteStats(
            totalVotes: 0,
            upvotes: 0,
            downvotes: 0,
            userHasVoted: false,
            voteScore: 0.0,
          ),
        );

        await tester.pumpWidget(createTestWidget(controls));
        
        final votingControls = find.byType(TrackVotingControls);
        expect(votingControls, findsOneWidget);
      });
    });

    group('VoteStats', () {
      test('should store vote data correctly', () {
        const stats = VoteStats(
          totalVotes: 100,
          upvotes: 75,
          downvotes: 25,
          userHasVoted: true,
          voteScore: 50.0,
        );

        expect(stats.totalVotes, 100);
        expect(stats.upvotes, 75);
        expect(stats.downvotes, 25);
        expect(stats.userHasVoted, true);
        expect(stats.voteScore, 50.0);
      });

      test('should handle zero votes', () {
        const stats = VoteStats(
          totalVotes: 0,
          upvotes: 0,
          downvotes: 0,
          userHasVoted: false,
          voteScore: 0.0,
        );

        expect(stats.totalVotes, 0);
        expect(stats.userHasVoted, false);
        expect(stats.voteScore, 0.0);
      });

      test('should indicate user voted state correctly', () {
        const votedStats = VoteStats(
          totalVotes: 10,
          upvotes: 8,
          downvotes: 2,
          userHasVoted: true,
          voteScore: 6.0,
        );

        const notVotedStats = VoteStats(
          totalVotes: 10,
          upvotes: 8,
          downvotes: 2,
          userHasVoted: false,
          voteScore: 6.0,
        );

        expect(votedStats.userHasVoted, true);
        expect(notVotedStats.userHasVoted, false);
      });
    });
  });
}