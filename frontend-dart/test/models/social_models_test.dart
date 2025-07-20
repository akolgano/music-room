import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/models/social_models.dart';

void main() {
  group('Social Models Tests', () {
    group('Friendship', () {
      test('should create Friendship from JSON', () {
        print('Testing: should create Friendship from JSON');
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

      test('should convert Friendship to JSON', () {
        print('Testing: should convert Friendship to JSON');
        final friendship = Friendship(
          id: '123',
          fromUser: 456,
          toUser: 789,
          status: 'accepted',
          createdAt: DateTime.parse('2023-12-01T10:30:00.000Z')
        );
        
        final json = friendship.toJson();
        
        expect(json['id'], '123');
        expect(json['from_user'], 456);
        expect(json['to_user'], 789);
        expect(json['status'], 'accepted');
        expect(json['created_at'], '2023-12-01T10:30:00.000Z');
      });

      test('should handle different friendship statuses', () {
        print('Testing: should handle different friendship statuses');
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
        print('Testing: should handle integer ID conversion');
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

      test('should preserve datetime precision', () {
        print('Testing: should preserve datetime precision');
        final originalDate = DateTime.now();
        final friendship = Friendship(
          id: '123',
          fromUser: 456,
          toUser: 789,
          status: 'pending',
          createdAt: originalDate
        );
        
        final json = friendship.toJson();
        final recreated = Friendship.fromJson(json);
        

        expect(recreated.createdAt.millisecondsSinceEpoch, 
               originalDate.millisecondsSinceEpoch);
      });

      test('should handle various datetime formats', () {
        print('Testing: should handle various datetime formats');
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