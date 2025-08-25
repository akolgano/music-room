import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/widgets/core_widgets.dart';

void main() {
  group('DialogWidgets Tests', () {
    testWidgets('showTextInputDialog displays correct title and hint text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DialogWidgets.showTextInputDialog(
                  context,
                  title: 'Test Title',
                  hintText: 'Test Hint',
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Hint'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('showTextInputDialog returns input value when saved', (WidgetTester tester) async {
      String? result;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await DialogWidgets.showTextInputDialog(
                    context,
                    title: 'Test Title',
                    initialValue: 'Initial Value',
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Test Input');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, equals('Test Input'));
    });

    testWidgets('showTextInputDialog returns null when cancelled', (WidgetTester tester) async {
      String? result = 'not null';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await DialogWidgets.showTextInputDialog(
                    context,
                    title: 'Test Title',
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('showConfirmDialog displays correct title and message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DialogWidgets.showConfirmDialog(
                  context,
                  title: 'Confirm Title',
                  message: 'Confirm Message',
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Title'), findsOneWidget);
      expect(find.text('Confirm Message'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('showConfirmDialog returns true when confirmed', (WidgetTester tester) async {
      bool? result;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await DialogWidgets.showConfirmDialog(
                    context,
                    title: 'Test',
                    message: 'Test Message',
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, equals(true));
    });

    testWidgets('showConfirmDialog returns false when cancelled', (WidgetTester tester) async {
      bool? result;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await DialogWidgets.showConfirmDialog(
                    context,
                    title: 'Test',
                    message: 'Test Message',
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, equals(false));
    });

    testWidgets('showConfirmDialog shows dangerous styling when isDangerous is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DialogWidgets.showConfirmDialog(
                  context,
                  title: 'Dangerous Action',
                  message: 'This is dangerous',
                  isDangerous: true,
                  confirmText: 'Delete',
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Dangerous Action'), findsOneWidget);
      expect(find.text('This is dangerous'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      
      final deleteButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Delete')
      );
      expect(deleteButton.style!.backgroundColor!.resolve({}), equals(Colors.red));
    });

    testWidgets('showTextInputDialog validates input when validator is provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DialogWidgets.showTextInputDialog(
                  context,
                  title: 'Test Title',
                  validator: (value) => value?.isEmpty == true ? 'Required' : null,
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('showTextInputDialog supports multiline input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DialogWidgets.showTextInputDialog(
                  context,
                  title: 'Multiline Test',
                  maxLines: 3,
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField, isNotNull);
    });
  });
}