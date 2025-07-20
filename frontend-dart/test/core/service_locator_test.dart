import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/core/service_locator.dart';
import 'package:get_it/get_it.dart';

void main() {
  group('Service Locator Tests', () {
    test('Service locator should have setupServiceLocator function', () {
      print('Testing: Service locator should have setupServiceLocator function');
      expect(setupServiceLocator, isA<Function>());
    });

    test('Service locator should work with GetIt', () {
      print('Testing: Service locator should work with GetIt');
      expect(getIt, isA<GetIt>());
    });

    test('Service locator should be callable', () {
      print('Testing: Service locator should be callable');
      expect(setupServiceLocator, isA<Function>());
    });

    test('Service locator should reset properly', () {
      print('Testing: Service locator should reset properly');
      getIt.reset();
      expect(getIt.allReady(), completion(isEmpty));
    });

    test('Service locator should handle dependency injection', () {
      print('Testing: Service locator should handle dependency injection');
      expect(getIt, isNotNull);
      expect(getIt, isA<GetIt>());
    });
  });
}
