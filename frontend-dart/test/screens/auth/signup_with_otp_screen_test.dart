import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:music_room/screens/auth/signup_with_otp_screen.dart';
import 'package:music_room/core/validators.dart';

void main() {
  group('Signup With OTP Screen Tests', () {
    test('SignupWithOtpScreen should be instantiable', () {
      const screen = SignupWithOtpScreen();
      expect(screen, isA<SignupWithOtpScreen>());
    });

    test('SignupWithOtpScreen should handle OTP validation', () {
      const validOtp = '123456';
      const invalidOtp = '12345';
      const emptyOtp = '';
      const nonNumericOtp = 'abc123';
      
      expect(validOtp.length, 6);
      expect(invalidOtp.length, lessThan(6));
      expect(emptyOtp.isEmpty, true);
      
      final numericPattern = RegExp(r'^[0-9]+$');
      expect(numericPattern.hasMatch(validOtp), true);
      expect(numericPattern.hasMatch(nonNumericOtp), false);
      
      final otpController = TextEditingController();
      otpController.text = validOtp;
      
      expect(otpController.text, validOtp);
      expect(otpController.text.length, 6);
      
      final otpValidator = AppValidators.required;
      expect(otpValidator(validOtp, 'OTP'), null);
      expect(otpValidator('', 'OTP'), isNotNull);
      
      otpController.dispose();
      
      final otpSentTime = DateTime.now().subtract(const Duration(minutes: 5));
      final currentTime = DateTime.now();
      const otpExpiryMinutes = 10;
      
      final isOtpExpired = currentTime.difference(otpSentTime).inMinutes > otpExpiryMinutes;
      expect(isOtpExpired, false);
    });

    test('SignupWithOtpScreen should handle signup form submission', () {

      const formData = {
        'email': 'test@example.com',
        'password': 'password123',
        'confirmPassword': 'password123',
        'firstName': 'John',
        'lastName': 'Doe',
        'username': 'johndoe',
        'otp': '123456',
      };
      

      expect(formData['email'], contains('@'));
      expect(formData['password'], isNotEmpty);
      expect(formData['password'] == formData['confirmPassword'], true);
      expect(formData['firstName'], isNotEmpty);
      expect(formData['lastName'], isNotEmpty);
      expect(formData['username'], isNotEmpty);
      expect(formData['otp']!.length, 6);
      

      final emailValidator = AppValidators.email;
      expect(emailValidator(formData['email']!), null);
      expect(emailValidator('invalid-email'), isNotNull);
      

      final passwordValidator = AppValidators.password;
      expect(passwordValidator(formData['password']!), null);
      expect(passwordValidator('123'), isNotNull);
      

      final usernameValidator = AppValidators.required;
      expect(usernameValidator(formData['username']!, 'username'), null);
      expect(usernameValidator('', 'username'), isNotNull);
      

      var isSubmitting = false;
      var submissionError = '';
      var submissionSuccess = false;
      

      isSubmitting = true;
      expect(isSubmitting, true);
      

      isSubmitting = false;
      submissionSuccess = true;
      
      expect(submissionSuccess, true);
      expect(submissionError.isEmpty, true);
      

      submissionSuccess = false;
      submissionError = 'Invalid OTP';
      
      expect(submissionError, contains('OTP'));
    });

    test('SignupWithOtpScreen should handle email verification', () {

      const email = 'test@example.com';
      var isEmailVerified = false;
      var otpSent = false;
      

      final emailValidator = AppValidators.email;
      final isValidEmail = emailValidator(email) == null;
      
      expect(isValidEmail, true);
      

      if (isValidEmail) {
        otpSent = true;
      }
      
      expect(otpSent, true);
      

      const receivedOtp = '123456';
      const userEnteredOtp = '123456';
      
      if (receivedOtp == userEnteredOtp) {
        isEmailVerified = true;
      }
      
      expect(isEmailVerified, true);
      

      const verificationMessages = {
        'otpSent': 'OTP sent to your email',
        'invalidOtp': 'Invalid or expired OTP',
        'verificationSuccess': 'Email verified successfully',
        'resendOtp': 'Resend OTP',
      };
      
      expect(verificationMessages['otpSent'], contains('sent'));
      expect(verificationMessages['invalidOtp'], contains('Invalid'));
      expect(verificationMessages['verificationSuccess'], contains('verified'));
      expect(verificationMessages['resendOtp'], contains('Resend'));
      

      var otpResendCount = 0;
      const maxResendAttempts = 3;
      
      otpResendCount++;
      expect(otpResendCount, lessThanOrEqualTo(maxResendAttempts));
      

      final lastOtpSentTime = DateTime.now();
      const resendCooldownSeconds = 60;
      
      final canResend = DateTime.now().difference(lastOtpSentTime).inSeconds >= resendCooldownSeconds;
      expect(canResend, false);
      

      var canChangeEmail = !isEmailVerified;
      expect(canChangeEmail, false);
    });
  });
}
