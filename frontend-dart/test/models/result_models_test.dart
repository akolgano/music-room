import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/models/result_models.dart';
void main() {
  group('Result Models Tests', () {
    group('BatchLibraryAddResult', () {
      test('should calculate status correctly for complete success', () {
        const result = BatchLibraryAddResult(
          totalTracks: 5,
          successCount: 5,
          failureCount: 0,
          successfulTracks: ['track1', 'track2', 'track3', 'track4', 'track5']
        );
        
        expect(result.hasErrors, false);
        expect(result.hasPartialSuccess, false);
        expect(result.isCompleteSuccess, true);
        expect(result.summaryMessage, 'All 5 tracks added to your library successfully!');
      });
      test('should calculate status correctly for partial success', () {
        const result = BatchLibraryAddResult(
          totalTracks: 5,
          successCount: 3,
          failureCount: 2,
          errors: ['Error 1', 'Error 2'],
          successfulTracks: ['track1', 'track2', 'track3']
        );
        
        expect(result.hasErrors, true);
        expect(result.hasPartialSuccess, true);
        expect(result.isCompleteSuccess, false);
        expect(result.summaryMessage, '3/5 tracks added to your library');
        expect(result.detailedMessage, '3 added, 2 failed');
      });
      test('should calculate status correctly for complete failure', () {
        const result = BatchLibraryAddResult(
          totalTracks: 5,
          successCount: 0,
          failureCount: 5,
          errors: ['Error 1', 'Error 2', 'Error 3', 'Error 4', 'Error 5']
        );
        
        expect(result.hasErrors, true);
        expect(result.hasPartialSuccess, false);
        expect(result.isCompleteSuccess, false);
        expect(result.summaryMessage, 'Failed to add tracks to your library');
        expect(result.detailedMessage, '5 failed');
      });
      test('should provide sample data correctly', () {
        const result = BatchLibraryAddResult(
          totalTracks: 10,
          successCount: 5,
          failureCount: 5,
          errors: ['Error 1', 'Error 2', 'Error 3', 'Error 4', 'Error 5'],
          successfulTracks: ['track1', 'track2', 'track3', 'track4', 'track5']
        );
        
        expect(result.successSample, ['track1', 'track2', 'track3']);
        expect(result.errors.take(3).toList(), ['Error 1', 'Error 2', 'Error 3']);
      });
    });
    group('SocialLoginResult', () {
      test('should create success result correctly', () {
        final result = SocialLoginResult.success('token123', 'google');
        
        expect(result.success, true);
        expect(result.token, 'token123');
        expect(result.provider, 'google');
        expect(result.error, null);
      });
      test('should create error result correctly', () {
        final result = SocialLoginResult.error('Login failed');
        
        expect(result.success, false);
        expect(result.token, null);
        expect(result.provider, null);
        expect(result.error, 'Login failed');
      });
    });
    group('AddTrackResult', () {
      test('should create AddTrackResult from JSON', () {
        final json = {
          'success': true,
          'message': 'Track added successfully',
          'is_duplicate': false
        };
        
        final result = AddTrackResult.fromJson(json);
        
        expect(result.success, true);
        expect(result.message, 'Track added successfully');
        expect(result.isDuplicate, false);
      });
      test('should handle missing is_duplicate field', () {
        final json = {
          'success': true,
          'message': 'Track added successfully'
        };
        
        final result = AddTrackResult.fromJson(json);
        
        expect(result.success, true);
        expect(result.message, 'Track added successfully');
        expect(result.isDuplicate, false);
      });
    });
    group('BatchAddResult', () {
      test('should create BatchAddResult from JSON', () {
        final json = {
          'total_tracks': 10,
          'success_count': 7,
          'duplicate_count': 2,
          'failure_count': 1,
          'errors': ['Error 1']
        };
        
        final result = BatchAddResult.fromJson(json);
        
        expect(result.totalTracks, 10);
        expect(result.successCount, 7);
        expect(result.duplicateCount, 2);
        expect(result.failureCount, 1);
        expect(result.errors, ['Error 1']);
      });
      test('should calculate status correctly for complete success', () {
        const result = BatchAddResult(
          totalTracks: 5,
          successCount: 5,
          duplicateCount: 0,
          failureCount: 0
        );
        
        expect(result.hasErrors, false);
        expect(result.hasPartialSuccess, false);
        expect(result.isCompleteSuccess, true);
        expect(result.summaryMessage, 'All 5 tracks added successfully!');
      });
      test('should calculate status correctly for partial success', () {
        const result = BatchAddResult(
          totalTracks: 10,
          successCount: 6,
          duplicateCount: 2,
          failureCount: 2,
          errors: ['Error 1', 'Error 2']
        );
        
        expect(result.hasErrors, true);
        expect(result.hasPartialSuccess, true);
        expect(result.isCompleteSuccess, false);
        expect(result.summaryMessage, '6/10 tracks added successfully');
        expect(result.detailedMessage, '6 added, 2 duplicates, 2 failed');
      });
      test('should calculate status correctly for complete failure', () {
        const result = BatchAddResult(
          totalTracks: 5,
          successCount: 0,
          duplicateCount: 0,
          failureCount: 5,
          errors: ['Error 1', 'Error 2', 'Error 3', 'Error 4', 'Error 5']
        );
        
        expect(result.hasErrors, true);
        expect(result.hasPartialSuccess, false);
        expect(result.isCompleteSuccess, false);
        expect(result.summaryMessage, 'Failed to add tracks to playlist');
        expect(result.detailedMessage, '5 failed');
      });
      test('should handle missing errors field', () {
        final json = {
          'total_tracks': 5,
          'success_count': 5,
          'duplicate_count': 0,
          'failure_count': 0
        };
        
        final result = BatchAddResult.fromJson(json);
        
        expect(result.errors, isEmpty);
      });
    });
  });
}