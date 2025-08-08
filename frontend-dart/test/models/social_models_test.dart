import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/models/api_models.dart';
void main() {
  group('Social Models Tests', () {
    group('Friendship', () {
      test('should create Friendship from JSON', () {
        final json = {
          'id': '123',
          'from_user': 456,
          'to_user': 789,
          'status': 'pending',
          'created_at': '2023-12-01T10:30:00.000Z'
        };
        
        final friendship = Friendship.fromJson(json);
        
        expect(friendship.id, '123');
        expect(friendship.fromUser, 456);
        expect(friendship.toUser, 789);
        expect(friendship.status, 'pending');
        expect(friendship.createdAt, DateTime.parse('2023-12-01T10:30:00.000Z'));
      });
      test('should handle different friendship statuses', () {
        final statuses = ['pending', 'accepted', 'rejected', 'blocked'];
        
        for (final status in statuses) {
          final json = {
            'id': '123',
            'from_user': 456,
            'to_user': 789,
            'status': status,
            'created_at': '2023-12-01T10:30:00.000Z'
          };
          
          final friendship = Friendship.fromJson(json);
          expect(friendship.status, status);
        }
      });
      test('should handle integer ID conversion', () {
        final json = {
          'id': 123,
          'from_user': 456,
          'to_user': 789,
          'status': 'pending',
          'created_at': '2023-12-01T10:30:00.000Z'
        };
        
        final friendship = Friendship.fromJson(json);
        
        expect(friendship.id, '123');
        expect(friendship.fromUser, 456);
        expect(friendship.toUser, 789);
      });
      test('should handle various datetime formats', () {
        final dateFormats = [
          '2023-12-01T10:30:00.000Z',
          '2023-12-01T10:30:00Z',
          '2023-12-01T10:30:00.123456Z'
        ];
        
        for (final dateStr in dateFormats) {
          final json = {
            'id': '123',
            'from_user': 456,
            'to_user': 789,
            'status': 'pending',
            'created_at': dateStr
          };
          
          expect(() => Friendship.fromJson(json), returnsNormally);
        }
      });
    });
  });
}