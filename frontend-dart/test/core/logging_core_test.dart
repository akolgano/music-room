import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/core/logging_core.dart';

class TestWidgetWithLogging extends StatefulWidget {
  const TestWidgetWithLogging({super.key});

  @override
  State<TestWidgetWithLogging> createState() => _TestWidgetWithLoggingState();
}

class _TestWidgetWithLoggingState extends State<TestWidgetWithLogging> with UserActionLoggingMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test')),
      body: Column(
        children: [
          buildLoggingIconButton(
            icon: const Icon(Icons.science),
            onPressed: () => logButtonClick('test_button'),
            buttonName: 'test_button',
          ),
          buildLoggingButton<TextButton>(
            child: const Text('Text Button'),
            onPressed: () => logButtonClick('text_button'),
            buttonName: 'text_button',
            buttonBuilder: ({required onPressed, required child, style}) => 
                TextButton(onPressed: onPressed, style: style, child: child),
          ),
          buildLoggingElevatedButton(
            child: const Text('Elevated Button'),
            onPressed: () => logButtonClick('elevated_button'),
            buttonName: 'elevated_button',
          ),
        ],
      ),
    );
  }
}

void main() {
  group('UserActionLoggingMixin Tests', () {
    testWidgets('should create logging icon button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestWidgetWithLogging(),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.science), findsOneWidget);
    });

    testWidgets('should create logging text button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestWidgetWithLogging(),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
      expect(find.text('Text Button'), findsOneWidget);
    });

    testWidgets('should create logging elevated button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestWidgetWithLogging(),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Elevated Button'), findsOneWidget);
    });

    testWidgets('should handle button taps without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestWidgetWithLogging(),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle disabled buttons properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.disabled_by_default),
                  onPressed: null,
                ),
                TextButton(
                  onPressed: null,
                  child: const Text('Disabled Text'),
                ),
                ElevatedButton(
                  onPressed: null,
                  child: const Text('Disabled Elevated'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should log button clicks with metadata', (WidgetTester tester) async {
      late _TestWidgetState mixinState;
      
      await tester.pumpWidget(
        MaterialApp(
          home: _TestWidget(),
        ),
      );
      
      mixinState = tester.state(find.byType(_TestWidget));
      
      expect(() => mixinState.logButtonClick('test_button'), returnsNormally);
      expect(() => mixinState.logButtonClick('test_button', metadata: {'key': 'value'}), returnsNormally);
      expect(() => mixinState.logButtonClick('test_button', metadata: {}), returnsNormally);
    });

    testWidgets('should handle null and empty metadata', (WidgetTester tester) async {
      late _TestWidgetState mixinState;
      
      await tester.pumpWidget(
        MaterialApp(
          home: _TestWidget(),
        ),
      );
      
      mixinState = tester.state(find.byType(_TestWidget));
      
      expect(() => mixinState.logButtonClick('test_button', metadata: null), returnsNormally);
      expect(() => mixinState.logButtonClick('test_button', metadata: {}), returnsNormally);
      expect(() => mixinState.logButtonClick(''), returnsNormally);
    });
  });
}

class _TestWidget extends StatefulWidget {
  @override
  _TestWidgetState createState() => _TestWidgetState();
}

class _TestWidgetState extends State<_TestWidget> with UserActionLoggingMixin {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
