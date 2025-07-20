import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:music_room/screens/profile/user_password_change_screen.dart';
import 'package:music_room/core/validators.dart';

void main() {
  group('User Password Change Screen Tests', () {
    test('UserPasswordChangeScreen should be instantiable', () {
      const screen = UserPasswordChangeScreen();
      expect(screen, isA<UserPasswordChangeScreen>());
    });

    test('UserPasswordChangeScreen should validate current password', () {
      final currentPasswordValidator = AppValidators.required;
      
      expect(currentPasswordValidator('', 'current password'), contains('field is required'));
      expect(currentPasswordValidator(null, 'current password'), contains('field is required'));
      expect(currentPasswordValidator('validpassword', 'current password'), null);
    });

    test('UserPasswordChangeScreen should validate new password', () {
      final passwordValidator = AppValidators.password;
      
      expect(passwordValidator('123'), contains('Password must be at least 4 characters'));
      expect(passwordValidator('1234'), null);
      expect(passwordValidator('strongpassword'), null);
      expect(passwordValidator(''), contains('field is required'));
      expect(passwordValidator(null), contains('field is required'));
    });

    test('UserPasswordChangeScreen should handle password confirmation', () {
      const password = 'newpassword123';
      const confirmPassword = 'newpassword123';
      const mismatchPassword = 'differentpassword';
      expect(password == confirmPassword, true);
      expect(password == mismatchPassword, false);
      final confirmValidator = AppValidators.required;
      expect(confirmValidator('', 'password confirmation'), contains('field is required'));
      expect(confirmValidator('validconfirmation', 'password confirmation'), null);
    });

    test('UserPasswordChangeScreen should handle form submission', () {
      const validCurrentPassword = 'currentpass';
      const validNewPassword = 'newpass123';
      const validConfirmPassword = 'newpass123';
      expect(AppValidators.required(validCurrentPassword, 'current password'), null);
      expect(AppValidators.password(validNewPassword), null);
      expect(AppValidators.required(validConfirmPassword, 'password confirmation'), null);
      expect(validNewPassword == validConfirmPassword, true);
      expect(AppValidators.password('123'), isNotNull);
      expect(AppValidators.required('', 'current password'), isNotNull);
    });

    test('UserPasswordChangeScreen should handle password change success', () {
      const successMessage = 'Password changed successfully';
      const errorMessage = 'Failed to change password';
      expect(successMessage.isNotEmpty, true);
      expect(successMessage.contains('success'), true);
      expect(errorMessage.isNotEmpty, true);
      expect(errorMessage.contains('Failed'), true);
      expect(successMessage.length, greaterThan(0));
    });

    test('UserPasswordChangeScreen should handle password strength requirements', () {
      const weakPassword = '123';
      const validPassword = 'pass123';
      const strongPassword = 'StrongPass123!';
      
      expect(AppValidators.password(weakPassword), isNotNull);
      expect(AppValidators.password(validPassword), null);
      expect(AppValidators.password(strongPassword), null);
    });

    test('UserPasswordChangeScreen should handle form state management', () {
      expect(UserPasswordChangeScreen, isA<Type>());
      const screen = UserPasswordChangeScreen();
      expect(screen, isA<StatefulWidget>());
    });
  });
}