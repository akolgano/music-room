import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/core/animations_core.dart';
import 'package:provider/provider.dart';

class TestTickerProvider extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

void main() {
  group('AnimationSettingsProvider', () {
    late AnimationSettingsProvider provider;

    setUp(() {
      provider = AnimationSettingsProvider();
    });

    test('should have default values', () {
      expect(provider.pulsingEnabled, isTrue);
      expect(provider.pulsingDuration, const Duration(seconds: 2));
      expect(provider.pulsingIntensity, 1.0);
    });

    test('should set pulsing enabled', () {
      bool notified = false;
      provider.addListener(() => notified = true);

      provider.setPulsingEnabled(false);

      expect(provider.pulsingEnabled, isFalse);
      expect(notified, isTrue);
    });

    test('should not notify when setting same pulsing enabled value', () {
      bool notified = false;
      provider.addListener(() => notified = true);

      provider.setPulsingEnabled(true); // same as default

      expect(notified, isFalse);
    });

    test('should set pulsing duration', () {
      bool notified = false;
      provider.addListener(() => notified = true);
      
      const newDuration = Duration(seconds: 3);
      provider.setPulsingDuration(newDuration);

      expect(provider.pulsingDuration, newDuration);
      expect(notified, isTrue);
    });

    test('should not notify when setting same pulsing duration', () {
      bool notified = false;
      provider.addListener(() => notified = true);

      provider.setPulsingDuration(const Duration(seconds: 2)); // same as default

      expect(notified, isFalse);
    });

    test('should set pulsing intensity with clamping', () {
      bool notified = false;
      provider.addListener(() => notified = true);

      provider.setPulsingIntensity(2.5);
      expect(provider.pulsingIntensity, 2.5);
      expect(notified, isTrue);

      notified = false;
      provider.setPulsingIntensity(5.0); // should be clamped to 3.0
      expect(provider.pulsingIntensity, 3.0);
      expect(notified, isTrue);

      notified = false;
      provider.setPulsingIntensity(0.05); // should be clamped to 0.1
      expect(provider.pulsingIntensity, 0.1);
      expect(notified, isTrue);
    });

    test('should not notify when setting same pulsing intensity', () {
      bool notified = false;
      provider.addListener(() => notified = true);

      provider.setPulsingIntensity(1.0); // same as default

      expect(notified, isFalse);
    });
  });

  group('PulsingColorAnimation', () {
    test('should have correct default duration', () {
      expect(PulsingColorAnimation.defaultDuration, const Duration(seconds: 2));
    });

    test('should have correct color values', () {
      expect(PulsingColorAnimation.lightGreen, const Color(0xFF2EF564));
      expect(PulsingColorAnimation.darkGreen, const Color(0xFF0F7A2E));
    });

  });

  group('PulsingContainer', () {
    testWidgets('should render child when disabled', (WidgetTester tester) async {
      const testChild = Text('Test Child');
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AnimationSettingsProvider(),
            child: const PulsingContainer(
              enabled: false,
              child: testChild,
            ),
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('should render animated container when enabled', (WidgetTester tester) async {
      const testChild = Text('Test Child');
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AnimationSettingsProvider(),
            child: const PulsingContainer(
              enabled: true,
              child: testChild,
            ),
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
    });

    testWidgets('should use custom duration', (WidgetTester tester) async {
      const testChild = Text('Test Child');
      const customDuration = Duration(milliseconds: 500);
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AnimationSettingsProvider(),
            child: const PulsingContainer(
              enabled: true,
              duration: customDuration,
              child: testChild,
            ),
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
    });
  });

  group('PulsingIcon', () {
    testWidgets('should render static icon when disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PulsingIcon(
            icon: Icons.star,
            enabled: false,
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('should render animated icon when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AnimationSettingsProvider(),
            child: const PulsingIcon(
              icon: Icons.star,
              enabled: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
    });

    testWidgets('should apply custom size', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PulsingIcon(
            icon: Icons.star,
            size: 32.0,
            enabled: false,
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(iconWidget.size, 32.0);
    });
  });


  group('PulsingButton', () {
    testWidgets('should render static button when disabled', (WidgetTester tester) async {
      bool pressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: PulsingButton(
            onPressed: () => pressed = true,
            enabled: false,
            child: const Text('Button'),
          ),
        ),
      );

      expect(find.text('Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      
      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, isTrue);
    });

    testWidgets('should render animated button when enabled', (WidgetTester tester) async {
      bool pressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AnimationSettingsProvider(),
            child: PulsingButton(
              onPressed: () => pressed = true,
              enabled: true,
              child: const Text('Button'),
            ),
          ),
        ),
      );

      expect(find.text('Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
      
      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, isTrue);
    });

    testWidgets('should handle null onPressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PulsingButton(
            onPressed: null,
            enabled: true,
            child: Text('Button'),
          ),
        ),
      );

      expect(find.text('Button'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}