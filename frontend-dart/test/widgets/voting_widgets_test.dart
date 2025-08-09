import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_room/widgets/voting_widgets.dart';
import 'package:music_room/models/voting_models.dart';
import 'package:music_room/providers/voting_provider.dart';
import 'package:music_room/providers/auth_provider.dart';

class FakeVotingProvider extends ChangeNotifier implements VotingProvider {
  bool _canVote = true;
  final Map<String, int> _userVotes = {};
  final Map<String, VoteStats> _trackVotes = {};
  final Map<String, int> _trackPoints = {};
  
  @override
  bool get canVote => _canVote;
  
  void setCanVote(bool value) {
    _canVote = value;
    notifyListeners();
  }
  
  int? getUserVote(String trackId) => _userVotes[trackId];
  
  int? getUserVoteByIndex(int index) => _userVotes['track_$index'];
  
  @override
  VoteStats? getTrackVotes(String trackId) => _trackVotes[trackId];
  
  @override
  VoteStats? getTrackVotesByIndex(int index) => _trackVotes['track_$index'];
  
  @override
  int getTrackPoints(int index) => _trackPoints['track_$index'] ?? 0;
  
  int getTrackPointsById(String trackId) => _trackPoints[trackId] ?? 0;
  
  void setUserVote(int trackIndex, int vote) {
    _userVotes['track_$trackIndex'] = vote;
    notifyListeners();
  }
  
  Future<bool> upvoteTrackByIndex(String playlistId, int trackIndex, String token) async {
    _trackPoints['track_$trackIndex'] = (_trackPoints['track_$trackIndex'] ?? 0) + 1;
    notifyListeners();
    return true;
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  String? _token = 'test_token';
  
  @override
  String? get token => _token;
  
  void setToken(String? token) {
    _token = token;
    notifyListeners();
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('Voting Widgets Tests', () {
    late FakeVotingProvider fakeVotingProvider;
    late FakeAuthProvider fakeAuthProvider;

    setUp(() {
      fakeVotingProvider = FakeVotingProvider();
      fakeAuthProvider = FakeAuthProvider();
    });

    Widget createTestWidget(Widget widget) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<VotingProvider>.value(value: fakeVotingProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: fakeAuthProvider),
          ],
          child: Scaffold(body: widget),
        ),
      );
    }

    group('VoteButton', () {
      testWidgets('should display upvote icon when selected', (WidgetTester tester) async {
        const voteButton = VoteButton(
          voteType: VoteType.upvote,
          isSelected: true,
        );

        await tester.pumpWidget(createTestWidget(voteButton));

        expect(find.byIcon(Icons.thumb_up), findsOneWidget);
        expect(find.byIcon(Icons.thumb_up_outlined), findsNothing);
      });

      testWidgets('should display outlined upvote icon when not selected', (WidgetTester tester) async {
        const voteButton = VoteButton(
          voteType: VoteType.upvote,
          isSelected: false,
        );

        await tester.pumpWidget(createTestWidget(voteButton));

        expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
        expect(find.byIcon(Icons.thumb_up), findsNothing);
      });

      testWidgets('should call onPressed when tapped and enabled', (WidgetTester tester) async {
        bool wasPressed = false;
        final voteButton = VoteButton(
          voteType: VoteType.upvote,
          isSelected: false,
          isEnabled: true,
          onPressed: () => wasPressed = true,
        );

        await tester.pumpWidget(createTestWidget(voteButton));
        await tester.tap(find.byType(InkWell));
        await tester.pump();

        expect(wasPressed, true);
      });

      testWidgets('should not call onPressed when disabled', (WidgetTester tester) async {
        bool wasPressed = false;
        final voteButton = VoteButton(
          voteType: VoteType.upvote,
          isSelected: false,
          isEnabled: false,
          onPressed: () => wasPressed = true,
        );

        await tester.pumpWidget(createTestWidget(voteButton));
        await tester.tap(find.byType(InkWell));
        await tester.pump();

        expect(wasPressed, false);
      });

      testWidgets('should display downvote icon for downvote type', (WidgetTester tester) async {
        const voteButton = VoteButton(
          voteType: VoteType.downvote,
          isSelected: false,
        );

        await tester.pumpWidget(createTestWidget(voteButton));

        expect(find.byIcon(Icons.thumb_down_off_alt), findsOneWidget);
      });

      testWidgets('should not respond to tap for downvote type', (WidgetTester tester) async {
        bool wasPressed = false;
        final voteButton = VoteButton(
          voteType: VoteType.downvote,
          isSelected: false,
          isEnabled: true,
          onPressed: () => wasPressed = true,
        );

        await tester.pumpWidget(createTestWidget(voteButton));
        await tester.tap(find.byType(InkWell));
        await tester.pump();

        expect(wasPressed, false);
      });
    });

    group('VoteCounter', () {
      testWidgets('should display upvotes count in detailed mode', (WidgetTester tester) async {
        const stats = VoteStats(
          totalVotes: 5,
          upvotes: 5,
          downvotes: 0,
          userHasVoted: false,
          voteScore: 5.0,
        );

        const voteCounter = VoteCounter(stats: stats, showDetailed: true);

        await tester.pumpWidget(createTestWidget(voteCounter));

        expect(find.text('5'), findsOneWidget);
        expect(find.text('Downvotes not supported'), findsOneWidget);
        expect(find.byIcon(Icons.thumb_up), findsOneWidget);
      });

      testWidgets('should display score in compact mode', (WidgetTester tester) async {
        const stats = VoteStats(
          totalVotes: 3,
          upvotes: 3,
          downvotes: 0,
          userHasVoted: false,
          voteScore: 3.0,
        );

        const voteCounter = VoteCounter(stats: stats, showDetailed: false);

        await tester.pumpWidget(createTestWidget(voteCounter));

        expect(find.text('+3'), findsOneWidget);
        expect(find.byIcon(Icons.trending_up), findsOneWidget);
      });
    });

    group('TrackVotingControls', () {
      testWidgets('should display voting controls when can vote', (WidgetTester tester) async {
        fakeVotingProvider.setCanVote(true);

        const controls = TrackVotingControls(
          playlistId: 'playlist1',
          trackId: 'track1',
        );

        await tester.pumpWidget(createTestWidget(controls));

        expect(find.byType(VoteButton), findsOneWidget);
      });

      testWidgets('should show compact controls when isCompact is true', (WidgetTester tester) async {
        fakeVotingProvider.setCanVote(true);

        const controls = TrackVotingControls(
          playlistId: 'playlist1',
          trackId: 'track1',
          isCompact: true,
        );

        await tester.pumpWidget(createTestWidget(controls));

        expect(find.byType(SizedBox), findsWidgets);
        expect(find.text('+0'), findsOneWidget);
      });

      testWidgets('should display user voted state', (WidgetTester tester) async {
        fakeVotingProvider.setCanVote(true);
        fakeVotingProvider._userVotes['track1'] = 1;
        fakeVotingProvider._trackPoints['track1'] = 1;

        const controls = TrackVotingControls(
          playlistId: 'playlist1',
          trackId: 'track1',
        );

        await tester.pumpWidget(createTestWidget(controls));

        expect(find.byType(VoteButton), findsOneWidget);
      });

      testWidgets('should handle vote action', (WidgetTester tester) async {
        fakeVotingProvider.setCanVote(true);

        const controls = TrackVotingControls(
          playlistId: 'playlist1',
          trackId: 'track_0',
          trackIndex: 0,
        );

        await tester.pumpWidget(createTestWidget(controls));
        
        await tester.tap(find.byType(VoteButton));
        await tester.pump();

        expect(fakeVotingProvider.getUserVoteByIndex(0), 1);
        expect(fakeVotingProvider.getTrackPointsById('track_0'), 1);
      });
    });

    group('PlaylistVotingBanner', () {
      testWidgets('should display voting banner', (WidgetTester tester) async {
        const banner = PlaylistVotingBanner(playlistId: 'playlist1');

        await tester.pumpWidget(createTestWidget(banner));

        expect(find.text('Upvoting Available'), findsOneWidget);
        expect(find.byIcon(Icons.how_to_vote), findsOneWidget);
      });
    });

    group('VotingStatsCard', () {
      testWidgets('should display empty state when no votes', (WidgetTester tester) async {
        const statsCard = VotingStatsCard(trackVotes: {});

        await tester.pumpWidget(createTestWidget(statsCard));

        expect(find.byType(SizedBox), findsWidgets);
      });

      testWidgets('should display voting statistics', (WidgetTester tester) async {
        final trackVotes = {
          'track1': const VoteStats(
            totalVotes: 3,
            upvotes: 3,
            downvotes: 0,
            userHasVoted: false,
            voteScore: 3.0,
          ),
          'track2': const VoteStats(
            totalVotes: 2,
            upvotes: 2,
            downvotes: 0,
            userHasVoted: false,
            voteScore: 2.0,
          ),
        };

        final statsCard = VotingStatsCard(trackVotes: trackVotes);

        await tester.pumpWidget(createTestWidget(statsCard));

        expect(find.text('Voting Statistics (Upvotes Only)'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3.0'), findsOneWidget);
        expect(find.byIcon(Icons.poll), findsOneWidget);
        expect(find.byIcon(Icons.thumb_up), findsOneWidget);
        expect(find.byIcon(Icons.music_note), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('should handle tracks with no votes', (WidgetTester tester) async {
        final trackVotes = {
          'track1': const VoteStats(
            totalVotes: 0,
            upvotes: 0,
            downvotes: 0,
            userHasVoted: false,
            voteScore: 0.0,
          ),
        };

        final statsCard = VotingStatsCard(trackVotes: trackVotes);

        await tester.pumpWidget(createTestWidget(statsCard));

        expect(find.text('0'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsNothing);
      });
    });

    group('VoteStats', () {
      test('should calculate score color correctly', () {
        const highScoreStats = VoteStats(
          totalVotes: 5,
          upvotes: 5,
          downvotes: 0,
          userHasVoted: false,
          voteScore: 0.8,
        );

        const mediumScoreStats = VoteStats(
          totalVotes: 3,
          upvotes: 3,
          downvotes: 0,
          userHasVoted: false,
          voteScore: 0.5,
        );

        const lowScoreStats = VoteStats(
          totalVotes: 1,
          upvotes: 1,
          downvotes: 0,
          userHasVoted: false,
          voteScore: 0.1,
        );

        expect(highScoreStats.scoreColor, Colors.green);
        expect(mediumScoreStats.scoreColor, Colors.orange);
        expect(lowScoreStats.scoreColor, Colors.red);
      });
    });
  });
}
