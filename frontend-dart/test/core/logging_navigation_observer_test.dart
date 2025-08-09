import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/core/navigation_core.dart';

void main() {
  group('LoggingNavigationObserver Tests', () {
    late LoggingNavigationObserver observer;

    setUp(() {
      observer = LoggingNavigationObserver();
    });

    test('should create LoggingNavigationObserver instance', () {
      expect(observer, isA<LoggingNavigationObserver>());
      expect(observer, isA<NavigatorObserver>());
    });

    testWidgets('should observe navigation events', (WidgetTester tester) async {
      
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: const Scaffold(body: Text('Home')),
          routes: {
            '/second': (context) => const Scaffold(body: Text('Second')),
          },
        ),
      );

      expect(observer.navigator, isNotNull);
    });

    testWidgets('should handle route push operations', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/second'),
                child: const Text('Navigate'),
              ),
            ),
          ),
          routes: {
            '/second': (context) => const Scaffold(body: Text('Second')),
          },
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('should handle route pop operations', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: const Scaffold(body: Text('Home')),
          routes: {
            '/second': (context) => Scaffold(
              appBar: AppBar(title: const Text('Second')),
              body: const Text('Second Page'),
            ),
          },
        ),
      );

      final context = tester.element(find.text('Home'));
      Navigator.pushNamed(context, '/second');
      await tester.pumpAndSettle();

      expect(find.text('Second Page'), findsOneWidget);

      Navigator.pop(context);
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    test('should handle empty route names gracefully', () {
      final mockRoute = MaterialPageRoute(
        builder: (context) => Container(),
        settings: RouteSettings(name: null),
      );
      expect(() => observer.didPush(mockRoute, null), returnsNormally);
      expect(() => observer.didPop(mockRoute, null), returnsNormally);
      expect(() => observer.didReplace(newRoute: mockRoute, oldRoute: null), returnsNormally);
      expect(() => observer.didRemove(mockRoute, null), returnsNormally);
    });
  });
}