import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/widgets/core_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AppWidgets', () {
    testWidgets('loading widget should display CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppWidgets.loading('Loading...'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('emptyState should display icon and title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppWidgets.emptyState(
              icon: Icons.inbox,
              title: 'No items',
              subtitle: 'Add some items to get started',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No items'), findsOneWidget);
      expect(find.text('Add some items to get started'), findsOneWidget);
    });

    testWidgets('showConfirmDialog should return true when confirmed', (tester) async {
      late bool? result;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AppWidgets.showConfirmDialog(
                    context,
                    title: 'Confirm',
                    message: 'Are you sure?',
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

      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('primaryButton should display correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => AppWidgets.primaryButton(
                context: context,
                text: 'Primary Button',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Primary Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('textField should display correctly', (tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => AppWidgets.textField(
                context: context,
                controller: controller,
                labelText: 'Test Field',
                hintText: 'Enter text',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Test Field'), findsOneWidget);
    });
  });
}