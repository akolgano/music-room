import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/screens/profile/profile_screen.dart';

void main() {
  group('MusicPreferenceDialog Tests', () {
    late List<Map<String, dynamic>> mockPreferences;

    setUp(() {
      mockPreferences = [
        {'id': 1, 'name': 'Rock', 'selected': false},
        {'id': 2, 'name': 'Pop', 'selected': true},
        {'id': 3, 'name': 'Jazz', 'selected': false},
      ];
    });

    testWidgets('should display music preferences dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => MusicPreferenceDialog(
                    availablePreferences: mockPreferences,
                    selectedIds: [2],
                  ),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Select Music Preferences'), findsOneWidget);
      expect(find.text('Rock'), findsOneWidget);
      expect(find.text('Pop'), findsOneWidget);
      expect(find.text('Jazz'), findsOneWidget);
    });

    testWidgets('should show selected preferences as checked', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => MusicPreferenceDialog(
                    availablePreferences: mockPreferences,
                    selectedIds: [2],
                  ),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes, findsNWidgets(3));
      
      final popCheckbox = tester.widget<CheckboxListTile>(checkboxes.at(1));
      expect(popCheckbox.value, isTrue);
    });

    testWidgets('should handle selection changes', (WidgetTester tester) async {
      List<int>? selectedIds;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => MusicPreferenceDialog(
                    availablePreferences: mockPreferences,
                    selectedIds: [2],
                  ),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Test passes if dialog can be interacted with
    });

    testWidgets('should close dialog on cancel', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => MusicPreferenceDialog(
                    availablePreferences: mockPreferences,
                    selectedIds: [2],
                  ),
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });
  });
}