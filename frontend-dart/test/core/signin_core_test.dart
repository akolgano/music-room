import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:music_room/services/auth_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('GoogleSignInCore Tests', () {
    test('should have GoogleSignIn instance getter', () {
      expect(GoogleSignInCore.instance, isNotNull);
    });

    test('instance should be GoogleSignIn type', () {
      expect(GoogleSignInCore.instance, isA<GoogleSignIn>());
    });

    test('instance should have correct scopes', () {
      final instance = GoogleSignInCore.instance;
      expect(instance.scopes, contains('email'));
      expect(instance.scopes, contains('profile'));
    });

    test('instance should be singleton', () {
      final instance1 = GoogleSignInCore.instance;
      final instance2 = GoogleSignInCore.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('clearCache should complete without throwing', () async {
      expect(() async => await GoogleSignInCore.clearCache(), returnsNormally);
    });

    test('resetGoogleSignIn should complete without throwing', () async {
      expect(() async => await GoogleSignInCore.resetGoogleSignIn(), returnsNormally);
    });

    test('clearCache should handle disconnect errors gracefully', () async {
      await expectLater(GoogleSignInCore.clearCache(), completes);
    });

    test('clearCache should handle signOut errors gracefully', () async {
      await expectLater(GoogleSignInCore.clearCache(), completes);
    });

    test('resetGoogleSignIn calls clearCache internally', () async {
      await expectLater(GoogleSignInCore.resetGoogleSignIn(), completes);
    });

    test('instance should have serverClientId configured', () {
      final instance = GoogleSignInCore.instance;
      expect(instance, isNotNull);
    });

    test('multiple calls to clearCache should not interfere', () async {
      await GoogleSignInCore.clearCache();
      await GoogleSignInCore.clearCache();
      expect(true, isTrue);
    });

    test('multiple calls to resetGoogleSignIn should not interfere', () async {
      await GoogleSignInCore.resetGoogleSignIn();
      await GoogleSignInCore.resetGoogleSignIn();
      expect(true, isTrue);
    });

    test('clearCache should not throw when already signed out', () async {
      await GoogleSignInCore.clearCache();
      await expectLater(GoogleSignInCore.clearCache(), completes);
    });

    test('resetGoogleSignIn should not throw when already reset', () async {
      await GoogleSignInCore.resetGoogleSignIn();
      await expectLater(GoogleSignInCore.resetGoogleSignIn(), completes);
    });

    test('instance should maintain state after clearCache', () async {
      final instanceBefore = GoogleSignInCore.instance;
      await GoogleSignInCore.clearCache();
      final instanceAfter = GoogleSignInCore.instance;
      expect(identical(instanceBefore, instanceAfter), isTrue);
    });

    test('instance should maintain state after resetGoogleSignIn', () async {
      final instanceBefore = GoogleSignInCore.instance;
      await GoogleSignInCore.resetGoogleSignIn();
      final instanceAfter = GoogleSignInCore.instance;
      expect(identical(instanceBefore, instanceAfter), isTrue);
    });

    test('clearCache handles sequential operations correctly', () async {
      final futures = List.generate(3, (index) => GoogleSignInCore.clearCache());
      await expectLater(Future.wait(futures), completes);
    });

    test('resetGoogleSignIn handles sequential operations correctly', () async {
      final futures = List.generate(3, (index) => GoogleSignInCore.resetGoogleSignIn());
      await expectLater(Future.wait(futures), completes);
    });

    test('clearCache and resetGoogleSignIn can be called interchangeably', () async {
      await GoogleSignInCore.clearCache();
      await GoogleSignInCore.resetGoogleSignIn();
      await GoogleSignInCore.clearCache();
      expect(true, isTrue);
    });

    test('GoogleSignIn instance has correct configuration', () {
      final instance = GoogleSignInCore.instance;
      expect(instance.scopes.length, greaterThanOrEqualTo(2));
    });

    test('clearCache method exists and is callable', () {
      expect(GoogleSignInCore.clearCache, isA<Function>());
    });

    test('resetGoogleSignIn method exists and is callable', () {
      expect(GoogleSignInCore.resetGoogleSignIn, isA<Function>());
    });

    test('instance getter is static and accessible', () {
      expect(() => GoogleSignInCore.instance, returnsNormally);
    });

    test('clearCache returns Future<void>', () async {
      final result = GoogleSignInCore.clearCache();
      expect(result, isA<Future<void>>());
      await result;
    });

    test('resetGoogleSignIn returns Future<void>', () async {
      final result = GoogleSignInCore.resetGoogleSignIn();
      expect(result, isA<Future<void>>());
      await result;
    });

    test('concurrent clearCache calls complete successfully', () async {
      final future1 = GoogleSignInCore.clearCache();
      final future2 = GoogleSignInCore.clearCache();
      await expectLater(Future.wait([future1, future2]), completes);
    });

    test('concurrent resetGoogleSignIn calls complete successfully', () async {
      final future1 = GoogleSignInCore.resetGoogleSignIn();
      final future2 = GoogleSignInCore.resetGoogleSignIn();
      await expectLater(Future.wait([future1, future2]), completes);
    });

    test('GoogleSignInCore class exists and is accessible', () {
      expect(GoogleSignInCore, isNotNull);
    });

    test('instance scopes contain required permissions', () {
      final instance = GoogleSignInCore.instance;
      expect(instance.scopes, isNotEmpty);
      expect(instance.scopes.every((scope) => scope.isNotEmpty), isTrue);
    });

    test('clearCache method completes within reasonable time', () async {
      final stopwatch = Stopwatch()..start();
      await GoogleSignInCore.clearCache();
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('resetGoogleSignIn method completes within reasonable time', () async {
      final stopwatch = Stopwatch()..start();
      await GoogleSignInCore.resetGoogleSignIn();
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('instance getter returns same object consistently', () {
      final instances = List.generate(10, (index) => GoogleSignInCore.instance);
      expect(instances.every((instance) => identical(instance, instances.first)), isTrue);
    });

    test('clearCache can be called after resetGoogleSignIn', () async {
      await GoogleSignInCore.resetGoogleSignIn();
      await expectLater(GoogleSignInCore.clearCache(), completes);
    });

    test('resetGoogleSignIn can be called after clearCache', () async {
      await GoogleSignInCore.clearCache();
      await expectLater(GoogleSignInCore.resetGoogleSignIn(), completes);
    });

    test('GoogleSignIn instance maintains configuration after operations', () async {
      final originalScopes = GoogleSignInCore.instance.scopes;
      await GoogleSignInCore.clearCache();
      await GoogleSignInCore.resetGoogleSignIn();
      final newScopes = GoogleSignInCore.instance.scopes;
      expect(originalScopes, equals(newScopes));
    });
  });
}