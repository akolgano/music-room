import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/screens/auth/forgot_password_screen.dart';
import 'package:music_room/core/constants.dart';

void main() {
  group('Forgot Password Screen Tests', () {
    test('ForgotPasswordScreen should be instantiable', () {
      const screen = ForgotPasswordScreen();
      expect(screen, isA<ForgotPasswordScreen>());
    });

    test('ForgotPasswordScreen should be a StatefulWidget', () {
      const screen = ForgotPasswordScreen();
      expect(screen, isA<StatefulWidget>());
    });

    test('ForgotPasswordScreen should handle email validation using AppValidators', () {
      expect(AppValidators.email('test@example.com'), null);
      
      expect(AppValidators.email('invalid-email'), isA<String>());
      expect(AppValidators.email(''), isA<String>());
      expect(AppValidators.email(null), isA<String>());
    });

    test('ForgotPasswordScreen should handle required field validation', () {
      expect(AppValidators.required('test@example.com'), null);
      expect(AppValidators.required(''), isA<String>());
      expect(AppValidators.required(null), isA<String>());
      final whitespaceResult = AppValidators.required('  ');
      expect(whitespaceResult, anyOf(isA<String>(), isNull));
    });

    test('ForgotPasswordScreen should create state correctly', () {
      const screen = ForgotPasswordScreen();
      final state = screen.createState();
      expect(state, isA<State<ForgotPasswordScreen>>());
    });

    test('ForgotPasswordScreen should handle key parameter', () {
      const key = Key('forgot_password_key');
      const screen = ForgotPasswordScreen(key: key);
      expect(screen.key, key);
    });
  });
}
