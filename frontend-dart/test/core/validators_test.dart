import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/core/validators.dart';
void main() {
  group('AppValidators Tests', () {
    test('AppValidators should have required validator', () {
      expect(AppValidators.required('test'), null);
      expect(AppValidators.required(''), isA<String>());
    });
    test('AppValidators should have email validator', () {
      expect(AppValidators.email('test@example.com'), null);
      expect(AppValidators.email('invalid'), isA<String>());
    });
    test('AppValidators should have password validator', () {
      expect(AppValidators.password('1234'), null);
      expect(AppValidators.password('123'), isA<String>());
    });
    test('AppValidators should have username validator', () {
      expect(AppValidators.username('username'), null);
      expect(AppValidators.username('ab'), isA<String>());
    });
    test('AppValidators should have phoneNumber validator', () {
      expect(AppValidators.phoneNumber(''), null);
      expect(AppValidators.phoneNumber('', true), isA<String>());
    });
    test('AppValidators should have description validator', () {
      expect(AppValidators.description('Valid description'), null);
      expect(AppValidators.description('a' * 501), 'Description must be less than 500 characters');
    });
  });
}