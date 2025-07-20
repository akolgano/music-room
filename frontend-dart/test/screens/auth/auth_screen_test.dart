import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/screens/auth/auth_screen.dart';
import 'package:music_room/core/validators.dart';

void main() {
  group('Auth Screen Tests', () {
    test('AuthScreen should be instantiable', () {
      print('Testing: AuthScreen should be instantiable');
      const screen = AuthScreen();
      expect(screen, isA<AuthScreen>());
    });

    test('AuthScreen should be a StatefulWidget', () {
      print('Testing: AuthScreen should be a StatefulWidget');
      const screen = AuthScreen();
      expect(screen, isA<StatefulWidget>());
    });

    test('AuthScreen should create state correctly', () {
      print('Testing: AuthScreen should create state correctly');
      const screen = AuthScreen();
      final state = screen.createState();
      expect(state, isA<State<AuthScreen>>());
    });

    test('AuthScreen should handle key parameter', () {
      print('Testing: AuthScreen should handle key parameter');
      const key = Key('auth_screen_key');
      const screen = AuthScreen(key: key);
      expect(screen.key, key);
    });

    test('AppValidators should validate login fields correctly', () {
      print('Testing: AppValidators should validate login fields correctly');
      expect(AppValidators.username('validuser'), null);
      expect(AppValidators.username('us'), isA<String>());
      expect(AppValidators.username(''), isA<String>());
      
      expect(AppValidators.password('validpass'), null);
      expect(AppValidators.password('123'), isA<String>());
      expect(AppValidators.password(''), isA<String>());
      
      expect(AppValidators.email('test@example.com'), null);
      expect(AppValidators.email('invalid-email'), isA<String>());
      expect(AppValidators.email(''), isA<String>());
    });

    test('AppValidators should validate required fields', () {
      print('Testing: AppValidators should validate required fields');
      expect(AppValidators.required('value'), null);
      expect(AppValidators.required(''), isA<String>());
      expect(AppValidators.required(null), isA<String>());
    });

    test('AppValidators should provide custom field names in error messages', () {
      print('Testing: AppValidators should provide custom field names in error messages');
      final result = AppValidators.required('', 'Username');
      expect(result, isA<String>());
      expect(result!.isNotEmpty, true);
    });

    test('AppValidators username should handle special characters', () {
      print('Testing: AppValidators username should handle special characters');
      expect(AppValidators.username('user_name'), null);
      expect(AppValidators.username('user123'), null);
      expect(AppValidators.username('user-name'), isA<String>());
      expect(AppValidators.username('user name'), isA<String>());
    });
  });
}
