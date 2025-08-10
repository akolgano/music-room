import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/core/locator_core.dart';
import 'package:get_it/get_it.dart';
void main() {
  group('Service Locator Tests', () {
    test('Service locator should have setupServiceLocator function', () {
      expect(setupServiceLocator, isA<Function>());
    });
    test('Service locator should work with GetIt', () {
      expect(getIt, isA<GetIt>());
    });
    test('Service locator should be callable', () {
      expect(setupServiceLocator, isA<Function>());
    });
    test('Service locator should reset properly', () {
      getIt.reset();
      expect(getIt.allReady(), completion(isEmpty));
    });
    test('Service locator should handle dependency injection', () {
      expect(getIt, isNotNull);
      expect(getIt, isA<GetIt>());
    });
  });
}
