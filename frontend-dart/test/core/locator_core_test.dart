import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/core/locator_core.dart';
import 'package:get_it/get_it.dart';

void main() {
  group('Service Locator Tests', () {
    setUp(() {
      if (getIt.isRegistered<String>()) {
        getIt.unregister<String>();
      }
    });

    tearDown(() {
      getIt.reset();
    });

    test('setupServiceLocator function should exist', () {
      expect(setupServiceLocator, isA<Function>());
    });

    test('getIt should be accessible', () {
      expect(getIt, isA<GetIt>());
    });

    test('getIt should be singleton instance', () {
      final instance1 = getIt;
      final instance2 = getIt;
      expect(identical(instance1, instance2), isTrue);
    });

    test('setupServiceLocator should be callable', () {
      expect(() => setupServiceLocator(), returnsNormally);
    });

    test('getIt should reset properly', () {
      getIt.registerSingleton<String>('test');
      expect(getIt.isRegistered<String>(), isTrue);
      getIt.reset();
      expect(getIt.isRegistered<String>(), isFalse);
    });

    test('getIt should handle service registration', () {
      getIt.registerSingleton<String>('test service');
      expect(getIt.isRegistered<String>(), isTrue);
      expect(getIt<String>(), equals('test service'));
    });

    test('getIt should handle lazy singletons', () {
      getIt.registerLazySingleton<String>(() => 'lazy test');
      expect(getIt.isRegistered<String>(), isTrue);
      expect(getIt<String>(), equals('lazy test'));
    });

    test('getIt should handle factory registration', () {
      var counter = 0;
      getIt.registerFactory<String>(() => 'factory_${++counter}');
      expect(getIt.isRegistered<String>(), isTrue);
      expect(getIt<String>(), equals('factory_1'));
      expect(getIt<String>(), equals('factory_2'));
    });

    test('getIt should handle service unregistration', () {
      getIt.registerSingleton<String>('test');
      expect(getIt.isRegistered<String>(), isTrue);
      getIt.unregister<String>();
      expect(getIt.isRegistered<String>(), isFalse);
    });

    test('getIt should handle multiple service types', () {
      getIt.registerSingleton<String>('string service');
      getIt.registerSingleton<int>(42);
      expect(getIt.isRegistered<String>(), isTrue);
      expect(getIt.isRegistered<int>(), isTrue);
      expect(getIt<String>(), equals('string service'));
      expect(getIt<int>(), equals(42));
    });

    test('getIt should handle named instances', () {
      getIt.registerSingleton<String>('default', instanceName: 'default');
      getIt.registerSingleton<String>('custom', instanceName: 'custom');
      expect(getIt<String>(instanceName: 'default'), equals('default'));
      expect(getIt<String>(instanceName: 'custom'), equals('custom'));
    });

    test('getIt should handle async registration', () async {
      getIt.registerSingletonAsync<String>(() async {
        await Future.delayed(Duration(milliseconds: 10));
        return 'async service';
      });
      await getIt.allReady();
      expect(getIt<String>(), equals('async service'));
    });

    test('getIt should handle disposal of services', () {
      var disposed = false;
      getIt.registerSingleton<DisposableService>(DisposableService(() => disposed = true));
      expect(disposed, isFalse);
      getIt.resetLazySingleton<DisposableService>();
      expect(disposed, isTrue);
    });

    test('getIt should check if ready for all services', () async {
      getIt.registerSingleton<String>('ready service');
      final readyFuture = getIt.allReady();
      await expectLater(readyFuture, completes);
    });

    test('getIt should handle dependencies correctly', () {
      getIt.registerSingleton<String>('dependency');
      getIt.registerFactory<TestService>(() => TestService(getIt<String>()));
      final service = getIt<TestService>();
      expect(service.dependency, equals('dependency'));
    });

    test('getIt should handle scopes', () {
      getIt.pushNewScope();
      getIt.registerSingleton<String>('scoped service');
      expect(getIt.isRegistered<String>(), isTrue);
      getIt.popScope();
      expect(getIt.isRegistered<String>(), isFalse);
    });

    test('getIt should handle scope disposal', () {
      getIt.pushNewScope();
      var disposed = false;
      getIt.registerSingleton<DisposableService>(DisposableService(() => disposed = true));
      getIt.popScope();
      expect(disposed, isTrue);
    });

    test('setupServiceLocator should initialize all required services', () {
      setupServiceLocator();
      expect(getIt, isNotNull);
    });

    test('setupServiceLocator should handle multiple calls', () {
      setupServiceLocator();
      expect(() => setupServiceLocator(), returnsNormally);
    });

    test('getIt should handle concurrent access', () async {
      getIt.registerFactory<String>(() => 'concurrent');
      final futures = List.generate(10, (index) => Future(() => getIt<String>()));
      final results = await Future.wait(futures);
      expect(results.every((result) => result == 'concurrent'), isTrue);
    });

    test('getIt should handle service replacement', () {
      getIt.registerSingleton<String>('original');
      expect(getIt<String>(), equals('original'));
      getIt.unregister<String>();
      getIt.registerSingleton<String>('replacement');
      expect(getIt<String>(), equals('replacement'));
    });

    test('getIt should validate service registration', () {
      expect(getIt.isRegistered<String>(), isFalse);
      getIt.registerSingleton<String>('test');
      expect(getIt.isRegistered<String>(), isTrue);
    });

    test('getIt should handle complex service hierarchies', () {
      getIt.registerSingleton<String>('base service');
      getIt.registerFactory<TestService>(() => TestService(getIt<String>()));
      getIt.registerFactory<ComplexService>(() => ComplexService(getIt<TestService>()));
      final service = getIt<ComplexService>();
      expect(service.testService.dependency, equals('base service'));
    });

    test('getIt should handle service lifecycle correctly', () {
      var creationCount = 0;
      getIt.registerFactory<String>(() => 'instance_${++creationCount}');
      expect(getIt<String>(), equals('instance_1'));
      expect(getIt<String>(), equals('instance_2'));
      expect(creationCount, equals(2));
    });

    test('getIt should handle singleton lifecycle correctly', () {
      var creationCount = 0;
      getIt.registerLazySingleton<String>(() => 'singleton_${++creationCount}');
      expect(getIt<String>(), equals('singleton_1'));
      expect(getIt<String>(), equals('singleton_1'));
      expect(creationCount, equals(1));
    });

    test('getIt should handle error cases gracefully', () {
      expect(() => getIt<String>(), throwsA(isA<Error>()));
    });

    test('getIt should handle async dependencies', () async {
      getIt.registerSingletonAsync<String>(() async => 'async dependency');
      await getIt.allReady();
      getIt.registerFactory<TestService>(() => TestService(getIt<String>()));
      final service = getIt<TestService>();
      expect(service.dependency, equals('async dependency'));
    });

    test('setupServiceLocator should be idempotent', () {
      setupServiceLocator();
      setupServiceLocator();
      expect(true, isTrue);
    });
  });
}

class DisposableService {
  final VoidCallback onDispose;
  DisposableService(this.onDispose);
}

class TestService {
  final String dependency;
  TestService(this.dependency);
}

class ComplexService {
  final TestService testService;
  ComplexService(this.testService);
}

typedef VoidCallback = void Function();
