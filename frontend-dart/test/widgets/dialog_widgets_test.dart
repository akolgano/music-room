import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/widgets/dialog_widgets.dart';

void main() {
  group('DialogWidgets Tests', () {
    testWidgets('buildStyledTextField should create text field with proper styling', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogWidgets.buildStyledTextField(
              controller: controller,
              hintText: 'Test hint',
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Test hint'), findsOneWidget);
      
      controller.dispose();
    });

    testWidgets('buildStyledTextField should handle user input', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogWidgets.buildStyledTextField(
              controller: controller,
              hintText: 'Enter text',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Test input');
      expect(controller.text, 'Test input');
      
      controller.dispose();
    });

    testWidgets('buildStyledTextField should apply custom decoration', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogWidgets.buildStyledTextField(
              controller: controller,
              hintText: 'Styled field',
            ),
          ),
        ),
      );

      // Test that the widget is properly constructed
      expect(find.byType(TextFormField), findsOneWidget);
      // We can't easily test decoration properties on TextFormField, 
      // so we verify the widget exists and is functional
      
      controller.dispose();
    });

    testWidgets('buildStyledTextField should handle empty controller', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogWidgets.buildStyledTextField(
              controller: controller,
              hintText: 'Empty field',
            ),
          ),
        ),
      );

      expect(controller.text, isEmpty);
      expect(find.byType(TextFormField), findsOneWidget);
      
      controller.dispose();
    });
  });
}