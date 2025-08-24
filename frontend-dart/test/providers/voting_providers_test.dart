import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:music_room/providers/voting_providers.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/providers/auth_providers.dart';
import 'package:music_room/models/voting_models.dart';
import 'package:music_room/models/api_models.dart';
import 'package:music_room/core/locator_core.dart';
import 'package:get_it/get_it.dart';

@GenerateMocks([ApiService, AuthProvider])
import 'voting_providers_test.mocks.dart';

void main() {
  group('VotingProvider Tests', () {
    late VotingProvider votingProvider;
    late MockApiService mockApiService;
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      GetIt.instance.reset();
      mockApiService = MockApiService();
      mockAuthProvider = MockAuthProvider();
      
      getIt.registerSingleton<ApiService>(mockApiService);
      getIt.registerSingleton<AuthProvider>(mockAuthProvider);
      
      when(mockAuthProvider.token).thenReturn('test_token');
      when(mockAuthProvider.currentUser).thenReturn(
        User(id: '1', username: 'testuser', email: 'test@example.com')
      );
      when(mockAuthProvider.authHeaders).thenReturn({
        'Content-Type': 'application/json',
        'Authorization': 'Token test_token'
      });
      
      votingProvider = VotingProvider();
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    test('should initialize with empty voting sessions', () {
      expect(votingProvider.votingSessions, isEmpty);
      expect(votingProvider.currentSession, isNull);
      expect(votingProvider.userVotes, isEmpty);
    });

    test('should create voting session successfully', () async {
      final session = VotingSession(
        id: '1',
        title: 'Test Session',
        description: 'Test Description',
        createdBy: '1',
        isActive: true,
        tracks: [],
      );
      
      when(mockApiService.createVotingSession(any, any)).thenAnswer((_) async => VotingSessionResponse(session: session));
      
      final result = await votingProvider.createVotingSession(
        title: 'Test Session',
        description: 'Test Description',
        tracks: [],
      );
      
      expect(result, isTrue);
      verify(mockApiService.createVotingSession('test_token', any)).called(1);
    });

    test('should handle create voting session error', () async {
      when(mockApiService.createVotingSession(any, any)).thenThrow(Exception('API Error'));
      
      final result = await votingProvider.createVotingSession(
        title: 'Test Session',
        description: 'Test Description',
        tracks: [],
      );
      
      expect(result, isFalse);
      expect(votingProvider.hasError, isTrue);
      verify(mockApiService.createVotingSession('test_token', any)).called(1);
    });

    test('should load voting sessions successfully', () async {
      final sessions = [
        VotingSession(id: '1', title: 'Session 1', description: 'Desc 1', createdBy: '1', isActive: true, tracks: []),
        VotingSession(id: '2', title: 'Session 2', description: 'Desc 2', createdBy: '2', isActive: false, tracks: []),
      ];
      
      when(mockApiService.getVotingSessions(any)).thenAnswer((_) async => VotingSessionsResponse(sessions: sessions));
      
      await votingProvider.loadVotingSessions();
      
      expect(votingProvider.votingSessions, hasLength(2));
      expect(votingProvider.votingSessions.first.title, 'Session 1');
      verify(mockApiService.getVotingSessions('test_token')).called(1);
    });

    test('should handle load voting sessions error', () async {
      when(mockApiService.getVotingSessions(any)).thenThrow(Exception('API Error'));
      
      await votingProvider.loadVotingSessions();
      
      expect(votingProvider.votingSessions, isEmpty);
      expect(votingProvider.hasError, isTrue);
      verify(mockApiService.getVotingSessions('test_token')).called(1);
    });

    test('should join voting session successfully', () async {
      final session = VotingSession(
        id: '1',
        title: 'Test Session',
        description: 'Test Description',
        createdBy: '2',
        isActive: true,
        tracks: [],
      );
      
      when(mockApiService.joinVotingSession(any, any)).thenAnswer((_) async => VotingSessionResponse(session: session));
      
      final result = await votingProvider.joinVotingSession('1');
      
      expect(result, isTrue);
      expect(votingProvider.currentSession, isNotNull);
      expect(votingProvider.currentSession?.id, '1');
      verify(mockApiService.joinVotingSession('test_token', '1')).called(1);
    });

    test('should handle join voting session error', () async {
      when(mockApiService.joinVotingSession(any, any)).thenThrow(Exception('Join failed'));
      
      final result = await votingProvider.joinVotingSession('1');
      
      expect(result, isFalse);
      expect(votingProvider.hasError, isTrue);
      verify(mockApiService.joinVotingSession('test_token', '1')).called(1);
    });

    test('should leave voting session successfully', () async {
      votingProvider.currentSession = VotingSession(
        id: '1',
        title: 'Test Session',
        description: 'Test Description',
        createdBy: '2',
        isActive: true,
        tracks: [],
      );
      
      when(mockApiService.leaveVotingSession(any, any)).thenAnswer((_) async => VotingSessionResponse(success: true));
      
      final result = await votingProvider.leaveVotingSession();
      
      expect(result, isTrue);
      expect(votingProvider.currentSession, isNull);
      verify(mockApiService.leaveVotingSession('test_token', '1')).called(1);
    });

    test('should handle leave voting session error', () async {
      votingProvider.currentSession = VotingSession(
        id: '1',
        title: 'Test Session',
        description: 'Test Description',
        createdBy: '2',
        isActive: true,
        tracks: [],
      );
      
      when(mockApiService.leaveVotingSession(any, any)).thenThrow(Exception('Leave failed'));
      
      final result = await votingProvider.leaveVotingSession();
      
      expect(result, isFalse);
      expect(votingProvider.hasError, isTrue);
      verify(mockApiService.leaveVotingSession('test_token', '1')).called(1);
    });

    test('should vote for track successfully', () async {
      final vote = Vote(
        id: '1',
        userId: '1',
        trackId: '101',
        sessionId: '1',
        voteType: VoteType.upvote,
        timestamp: DateTime.now(),
      );
      
      when(mockApiService.voteForTrack(any, any, any, any)).thenAnswer((_) async => VoteResponse(vote: vote, success: true));
      
      final result = await votingProvider.voteForTrack('1', '101', VoteType.upvote);
      
      expect(result, isTrue);
      expect(votingProvider.userVotes.containsKey('101'), isTrue);
      expect(votingProvider.userVotes['101']?.voteType, VoteType.upvote);
      verify(mockApiService.voteForTrack('test_token', '1', '101', VoteType.upvote)).called(1);
    });

    test('should handle vote for track error', () async {
      when(mockApiService.voteForTrack(any, any, any, any)).thenThrow(Exception('Vote failed'));
      
      final result = await votingProvider.voteForTrack('1', '101', VoteType.upvote);
      
      expect(result, isFalse);
      expect(votingProvider.hasError, isTrue);
      verify(mockApiService.voteForTrack('test_token', '1', '101', VoteType.upvote)).called(1);
    });

    test('should remove vote successfully', () async {
      votingProvider.userVotes['101'] = Vote(
        id: '1',
        userId: '1',
        trackId: '101',
        sessionId: '1',
        voteType: VoteType.upvote,
        timestamp: DateTime.now(),
      );
      
      when(mockApiService.removeVote(any, any, any)).thenAnswer((_) async => VoteResponse(success: true));
      
      final result = await votingProvider.removeVote('1', '101');
      
      expect(result, isTrue);
      expect(votingProvider.userVotes.containsKey('101'), isFalse);
      verify(mockApiService.removeVote('test_token', '1', '101')).called(1);
    });

    test('should handle remove vote error', () async {
      when(mockApiService.removeVote(any, any, any)).thenThrow(Exception('Remove vote failed'));
      
      final result = await votingProvider.removeVote('1', '101');
      
      expect(result, isFalse);
      expect(votingProvider.hasError, isTrue);
      verify(mockApiService.removeVote('test_token', '1', '101')).called(1);
    });

    test('should get voting results successfully', () async {
      final results = VotingResults(
        sessionId: '1',
        totalVotes: 25,
        trackResults: {
          '101': TrackVoteResult(trackId: '101', upvotes: 15, downvotes: 5, score: 10),
          '102': TrackVoteResult(trackId: '102', upvotes: 8, downvotes: 2, score: 6),
        },
      );
      
      when(mockApiService.getVotingResults(any, any)).thenAnswer((_) async => VotingResultsResponse(results: results));
      
      final result = await votingProvider.getVotingResults('1');
      
      expect(result, isNotNull);
      expect(result?.totalVotes, 25);
      expect(result?.trackResults['101']?.score, 10);
      verify(mockApiService.getVotingResults('test_token', '1')).called(1);
    });

    test('should handle get voting results error', () async {
      when(mockApiService.getVotingResults(any, any)).thenThrow(Exception('Results fetch failed'));
      
      final result = await votingProvider.getVotingResults('1');
      
      expect(result, isNull);
      expect(votingProvider.hasError, isTrue);
      verify(mockApiService.getVotingResults('test_token', '1')).called(1);
    });

    test('should end voting session successfully', () async {
      when(mockApiService.endVotingSession(any, any)).thenAnswer((_) async => VotingSessionResponse(success: true));
      
      final result = await votingProvider.endVotingSession('1');
      
      expect(result, isTrue);
      verify(mockApiService.endVotingSession('test_token', '1')).called(1);
    });

    test('should handle end voting session error', () async {
      when(mockApiService.endVotingSession(any, any)).thenThrow(Exception('End session failed'));
      
      final result = await votingProvider.endVotingSession('1');
      
      expect(result, isFalse);
      expect(votingProvider.hasError, isTrue);
      verify(mockApiService.endVotingSession('test_token', '1')).called(1);
    });

    test('should get user vote for track', () {
      final vote = Vote(
        id: '1',
        userId: '1',
        trackId: '101',
        sessionId: '1',
        voteType: VoteType.upvote,
        timestamp: DateTime.now(),
      );
      
      votingProvider.userVotes['101'] = vote;
      
      final userVote = votingProvider.getUserVoteForTrack('101');
      expect(userVote, equals(vote));
      
      final noVote = votingProvider.getUserVoteForTrack('999');
      expect(noVote, isNull);
    });

    test('should check if user has voted for track', () {
      votingProvider.userVotes['101'] = Vote(
        id: '1',
        userId: '1',
        trackId: '101',
        sessionId: '1',
        voteType: VoteType.upvote,
        timestamp: DateTime.now(),
      );
      
      expect(votingProvider.hasVotedForTrack('101'), isTrue);
      expect(votingProvider.hasVotedForTrack('999'), isFalse);
    });

    test('should get active sessions', () {
      votingProvider.votingSessions.addAll([
        VotingSession(id: '1', title: 'Active Session', description: 'Desc', createdBy: '1', isActive: true, tracks: []),
        VotingSession(id: '2', title: 'Inactive Session', description: 'Desc', createdBy: '1', isActive: false, tracks: []),
        VotingSession(id: '3', title: 'Another Active', description: 'Desc', createdBy: '2', isActive: true, tracks: []),
      ]);
      
      final activeSessions = votingProvider.getActiveSessions();
      expect(activeSessions, hasLength(2));
      expect(activeSessions.every((session) => session.isActive), isTrue);
    });

    test('should get sessions created by user', () {
      votingProvider.votingSessions.addAll([
        VotingSession(id: '1', title: 'My Session 1', description: 'Desc', createdBy: '1', isActive: true, tracks: []),
        VotingSession(id: '2', title: 'Other Session', description: 'Desc', createdBy: '2', isActive: true, tracks: []),
        VotingSession(id: '3', title: 'My Session 2', description: 'Desc', createdBy: '1', isActive: false, tracks: []),
      ]);
      
      final mySessions = votingProvider.getMyVotingSessions();
      expect(mySessions, hasLength(2));
      expect(mySessions.every((session) => session.createdBy == '1'), isTrue);
    });

    test('should clear user votes', () {
      votingProvider.userVotes['101'] = Vote(
        id: '1',
        userId: '1',
        trackId: '101',
        sessionId: '1',
        voteType: VoteType.upvote,
        timestamp: DateTime.now(),
      );
      
      expect(votingProvider.userVotes, isNotEmpty);
      
      votingProvider.clearUserVotes();
      
      expect(votingProvider.userVotes, isEmpty);
    });

    test('should handle token not available', () async {
      when(mockAuthProvider.token).thenReturn(null);
      
      final result = await votingProvider.createVotingSession(
        title: 'Test Session',
        description: 'Test Description',
        tracks: [],
      );
      
      expect(result, isFalse);
      expect(votingProvider.hasError, isTrue);
      verifyNever(mockApiService.createVotingSession(any, any));
    });

    test('should notify listeners on state changes', () {
      var notified = false;
      votingProvider.addListener(() => notified = true);
      
      votingProvider.notifyListeners();
      
      expect(notified, isTrue);
    });
  });
}

class VotingSession {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final bool isActive;
  final List<String> tracks;
  
  VotingSession({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.isActive,
    required this.tracks,
  });
}

class Vote {
  final String id;
  final String userId;
  final String trackId;
  final String sessionId;
  final VoteType voteType;
  final DateTime timestamp;
  
  Vote({
    required this.id,
    required this.userId,
    required this.trackId,
    required this.sessionId,
    required this.voteType,
    required this.timestamp,
  });
}

enum VoteType { upvote, downvote }

class VotingSessionResponse {
  final VotingSession? session;
  final bool? success;
  VotingSessionResponse({this.session, this.success});
}

class VotingSessionsResponse {
  final List<VotingSession> sessions;
  VotingSessionsResponse({required this.sessions});
}

class VoteResponse {
  final Vote? vote;
  final bool success;
  VoteResponse({this.vote, required this.success});
}

class VotingResults {
  final String sessionId;
  final int totalVotes;
  final Map<String, TrackVoteResult> trackResults;
  
  VotingResults({
    required this.sessionId,
    required this.totalVotes,
    required this.trackResults,
  });
}

class TrackVoteResult {
  final String trackId;
  final int upvotes;
  final int downvotes;
  final int score;
  
  TrackVoteResult({
    required this.trackId,
    required this.upvotes,
    required this.downvotes,
    required this.score,
  });
}

class VotingResultsResponse {
  final VotingResults results;
  VotingResultsResponse({required this.results});
}
