import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:music_room/providers/voting_providers.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/providers/auth_providers.dart';
import 'package:music_room/models/voting_models.dart';
import 'package:music_room/models/api_models.dart';
import 'package:music_room/models/music_models.dart';
import 'package:music_room/core/locator_core.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

@GenerateMocks([VotingService, AuthProvider, ApiService])
import 'voting_providers_test.mocks.dart';

void main() {
  group('VotingProvider Tests', () {
    late VotingProvider votingProvider;
    late MockVotingService mockVotingService;
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      GetIt.instance.reset();
      mockVotingService = MockVotingService();
      mockAuthProvider = MockAuthProvider();
      
      getIt.registerSingleton<VotingService>(mockVotingService);
      getIt.registerSingleton<AuthProvider>(mockAuthProvider);
      
      when(mockAuthProvider.token).thenReturn('test_token');
      when(mockAuthProvider.userId).thenReturn('user123');
      when(mockAuthProvider.username).thenReturn('testuser');
      when(mockAuthProvider.authHeaders).thenReturn({
        'Content-Type': 'application/json',
        'Authorization': 'Token test_token'
      });
      
      votingProvider = VotingProvider();
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    test('should initialize with empty track votes', () {
      expect(votingProvider.trackVotes, isEmpty);
      expect(votingProvider.canVote, isTrue);
      expect(votingProvider.hasUserVotedForPlaylist, isFalse);
      expect(votingProvider.trackPoints, isEmpty);
    });

    test('should update track points correctly', () {
      votingProvider.updateTrackPoints(0, 10);
      
      expect(votingProvider.trackPoints[0], equals(10));
      expect(votingProvider.trackVotes['track_0'], isNotNull);
      expect(votingProvider.trackVotes['track_0']?.totalVotes, equals(10));
      expect(votingProvider.trackVotes['track_0']?.voteScore, equals(10.0));
    });

    test('should initialize track points from playlist tracks', () {
      final tracks = [
        PlaylistTrack(
          id: 'track1',
          name: 'Track 1',
          artist: 'Artist 1',
          preview: 'preview1',
          image: 'image1',
          points: 5,
        ),
        PlaylistTrack(
          id: 'track2',
          name: 'Track 2',
          artist: 'Artist 2',
          preview: 'preview2',
          image: 'image2',
          points: 3,
        ),
      ];
      
      votingProvider.initializeTrackPoints(tracks);
      
      expect(votingProvider.trackPoints[0], equals(5));
      expect(votingProvider.trackPoints[1], equals(3));
      expect(votingProvider.trackVotes['track_0']?.totalVotes, equals(5));
      expect(votingProvider.trackVotes['track_1']?.totalVotes, equals(3));
    });

    test('should set voting permission correctly', () {
      votingProvider.setVotingPermission(false);
      expect(votingProvider.canVote, isFalse);
      
      votingProvider.setVotingPermission(true);
      expect(votingProvider.canVote, isTrue);
    });

    test('should update voting eligibility based on open license', () {
      final playlist = Playlist(
        id: 'playlist1',
        name: 'Test Playlist',
        description: 'Test',
        public: true,
        createdBy: 'user123',
        licenseType: 'open',
        tracks: [],
      );
      
      votingProvider.updateVotingEligibilityFromPlaylist(playlist);
      expect(votingProvider.canVote, isTrue);
    });

    test('should update voting eligibility based on invite_only license', () {
      final playlist = Playlist(
        id: 'playlist1',
        name: 'Test Playlist',
        description: 'Test',
        public: true,
        createdBy: 'user123',
        licenseType: 'invite_only',
        tracks: [],
      );
      
      votingProvider.updateVotingEligibilityFromPlaylist(playlist);
      expect(votingProvider.canVote, isTrue);
    });

    test('should handle vote for track successfully', () async {
      final voteResponse = VoteResponse(
        message: 'Vote recorded',
        playlist: [
          PlaylistInfoWithVotes(
            id: 1,
            playlistName: 'Test Playlist',
            description: 'Test',
            public: true,
            creator: 'testuser',
            tracks: [
              {'name': 'Track 1', 'points': 6},
            ],
          ),
        ],
      );
      
      when(mockVotingService.voteForTrack(
        playlistId: anyNamed('playlistId'),
        trackIndex: anyNamed('trackIndex'),
        token: anyNamed('token'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenAnswer((_) async => voteResponse);
      
      final result = await votingProvider.voteForTrackByIndex(
        playlistId: 'playlist1',
        trackIndex: 0,
        token: 'test_token',
      );
      
      expect(result, isTrue);
      expect(votingProvider.hasUserVotedForPlaylist, isTrue);
    });

    test('should handle vote for track when user already voted', () async {
      votingProvider.setHasUserVotedForPlaylist(true);
      
      final result = await votingProvider.voteForTrackByIndex(
        playlistId: 'playlist1',
        trackIndex: 0,
        token: 'test_token',
      );
      
      expect(result, isFalse);
      expect(votingProvider.hasError, isTrue);
      expect(votingProvider.errorMessage, contains('already voted'));
    });

    test('should clear voting data correctly', () {
      votingProvider.updateTrackPoints(0, 10);
      votingProvider.setHasUserVotedForPlaylist(true);
      
      votingProvider.clearVotingData();
      
      expect(votingProvider.trackVotes, isEmpty);
      expect(votingProvider.hasUserVotedForPlaylist, isFalse);
      expect(votingProvider.trackPoints, isEmpty);
    });

    test('should get track votes by index', () {
      votingProvider.updateTrackPoints(0, 10);
      
      final voteStats = votingProvider.getTrackVotesByIndex(0);
      expect(voteStats, isNotNull);
      expect(voteStats?.totalVotes, equals(10));
      
      final nullStats = votingProvider.getTrackVotesByIndex(999);
      expect(nullStats, isNull);
    });

    test('should refresh voting data from tracks', () {
      votingProvider.updateTrackPoints(0, 5);
      votingProvider.updateTrackPoints(1, 3);
      
      final tracks = [
        PlaylistTrack(
          id: 'track1',
          name: 'Track 1',
          artist: 'Artist 1',
          preview: 'preview1',
          image: 'image1',
          points: 8,
        ),
        PlaylistTrack(
          id: 'track2',
          name: 'Track 2',
          artist: 'Artist 2',
          preview: 'preview2',
          image: 'image2',
          points: 4,
        ),
      ];
      
      votingProvider.refreshVotingData(tracks);
      
      expect(votingProvider.trackPoints[0], equals(8));
      expect(votingProvider.trackPoints[1], equals(4));
    });

    test('should handle voting error with DioException', () async {
      final dioError = DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 403,
          data: {'detail': 'User not invited to vote on this playlist'},
        ),
      );
      
      when(mockVotingService.voteForTrack(
        playlistId: anyNamed('playlistId'),
        trackIndex: anyNamed('trackIndex'),
        token: anyNamed('token'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenThrow(dioError);
      
      final result = await votingProvider.voteForTrackByIndex(
        playlistId: 'playlist1',
        trackIndex: 0,
        token: 'test_token',
      );
      
      expect(result, isFalse);
      expect(votingProvider.hasError, isTrue);
      expect(votingProvider.errorMessage, contains('not invited'));
    });

    test('should handle voting with location restrictions', () async {
      final dioError = DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 403,
          data: {'detail': 'You are not within the allowed voting area'},
        ),
      );
      
      when(mockVotingService.voteForTrack(
        playlistId: anyNamed('playlistId'),
        trackIndex: anyNamed('trackIndex'),
        token: anyNamed('token'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenThrow(dioError);
      
      final result = await votingProvider.voteForTrackByIndex(
        playlistId: 'playlist1',
        trackIndex: 0,
        token: 'test_token',
      );
      
      expect(result, isFalse);
      expect(votingProvider.hasError, isTrue);
      expect(votingProvider.errorMessage, contains('not within the allowed voting area'));
    });

    test('should handle voting with time restrictions', () async {
      final dioError = DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 403,
          data: {'detail': 'Voting is not allowed at this time'},
        ),
      );
      
      when(mockVotingService.voteForTrack(
        playlistId: anyNamed('playlistId'),
        trackIndex: anyNamed('trackIndex'),
        token: anyNamed('token'),
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      )).thenThrow(dioError);
      
      final result = await votingProvider.voteForTrackByIndex(
        playlistId: 'playlist1',
        trackIndex: 0,
        token: 'test_token',
      );
      
      expect(result, isFalse);
      expect(votingProvider.hasError, isTrue);
      expect(votingProvider.errorMessage, contains('not allowed at this time'));
    });

    test('should notify listeners on state changes', () {
      var notified = false;
      votingProvider.addListener(() => notified = true);
      
      votingProvider.updateTrackPoints(0, 10);
      
      expect(notified, isTrue);
    });

    test('should set has user voted for playlist', () {
      expect(votingProvider.hasUserVotedForPlaylist, isFalse);
      
      votingProvider.setHasUserVotedForPlaylist(true);
      
      expect(votingProvider.hasUserVotedForPlaylist, isTrue);
    });
  });
}