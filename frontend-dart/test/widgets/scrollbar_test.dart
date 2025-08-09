import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/widgets/scrollbar_widgets.dart';

void main() {
  group('CustomSingleChildScrollView Tests', () {
    testWidgets('should create scrollbar with child', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomSingleChildScrollView(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) => ListTile(
                  title: Text('Item $index'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomSingleChildScrollView), findsOneWidget);
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets('should handle scrolling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomSingleChildScrollView(
              child: ListView.builder(
                itemCount: 50,
                itemBuilder: (context, index) => SizedBox(
                  height: 100,
                  child: ListTile(
                    title: Text('Item $index'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 10'), findsNothing);

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Item 0'), findsNothing);
    });

    testWidgets('should display scrollbar when content overflows', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: CustomSingleChildScrollView(
                child: ListView.builder(
                  itemCount: 20,
                  itemBuilder: (context, index) => SizedBox(
                    height: 50,
                    child: ListTile(title: Text('Item $index')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Scrollbar), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should handle empty content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomSingleChildScrollView(
              child: ListView.builder(
                itemCount: 0,
                itemBuilder: (context, index) => ListTile(
                  title: Text('Item $index'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomSingleChildScrollView), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('should work with different scroll directions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomSingleChildScrollView(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 10,
                itemBuilder: (context, index) => SizedBox(
                  width: 100,
                  child: Center(child: Text('Item $index')),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomSingleChildScrollView), findsOneWidget);
      expect(find.text('Item 0'), findsOneWidget);
    });
  });

  group('CustomSingleChildScrollView Tests', () {
    testWidgets('should create single child scroll view', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomSingleChildScrollView(
              child: Column(
                children: List.generate(
                  20,
                  (index) => SizedBox(
                    height: 50,
                    child: ListTile(title: Text('Item $index')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomSingleChildScrollView), findsOneWidget);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('should handle padding parameter', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomSingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: const Text('Padded Content'),
            ),
          ),
        ),
      );

      expect(find.byType(CustomSingleChildScrollView), findsOneWidget);
      expect(find.text('Padded Content'), findsOneWidget);
    });

    testWidgets('should scroll vertically by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: CustomSingleChildScrollView(
                child: Column(
                  children: List.generate(
                    10,
                    (index) => SizedBox(
                      height: 100,
                      child: Center(child: Text('Item $index')),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 5'), findsNothing);

      await tester.drag(find.byType(CustomSingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Item 0'), findsNothing);
    });
  });
}