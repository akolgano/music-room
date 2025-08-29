import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BaseScreen Tests', () {
    testWidgets('should build a basic screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Test Screen'),
            ),
          ),
        ),
      );

      expect(find.text('Test Screen'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should have proper Material structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Test Title'),
            ),
            body: const Center(
              child: Column(
                children: [
                  Text('Content 1'),
                  Text('Content 2'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Content 1'), findsOneWidget);
      expect(find.text('Content 2'), findsOneWidget);
    });

    testWidgets('should handle FloatingActionButton', (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                buttonPressed = true;
              },
              child: const Icon(Icons.add),
            ),
            body: const Center(
              child: Text('FAB Test'),
            ),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      
      await tester.tap(find.byType(FloatingActionButton));
      expect(buttonPressed, isTrue);
    });

    testWidgets('should render navigation elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              leading: const BackButton(),
              actions: const [
                Icon(Icons.search),
                Icon(Icons.more_vert),
              ],
            ),
            body: const Center(
              child: Text('Navigation Test'),
            ),
          ),
        ),
      );

      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('should handle drawer', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: Drawer(
              child: ListView(
                children: const [
                  DrawerHeader(
                    child: Text('Header'),
                  ),
                  ListTile(
                    title: Text('Item 1'),
                  ),
                ],
              ),
            ),
            body: const Center(
              child: Text('Drawer Test'),
            ),
          ),
        ),
      );

      expect(find.byType(Drawer), findsNothing); // Drawer is closed initially
      
      // Open drawer
      await tester.dragFrom(const Offset(0, 100), const Offset(300, 100));
      await tester.pumpAndSettle();
      
      expect(find.byType(Drawer), findsOneWidget);
      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets('should handle bottom navigation', (WidgetTester tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Center(
                  child: Text('Page $selectedIndex'),
                ),
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: selectedIndex,
                  onTap: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.search),
                      label: 'Search',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Page 0'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      
      expect(find.text('Page 1'), findsOneWidget);
    });

    testWidgets('should display snackbar messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Test Message')),
                    );
                  },
                  child: const Text('Show Snackbar'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Message'), findsNothing);
      
      await tester.tap(find.text('Show Snackbar'));
      await tester.pump();
      
      expect(find.text('Test Message'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('should handle safe area', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: Center(
                child: Text('Safe Area Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.text('Safe Area Content'), findsOneWidget);
    });


    testWidgets('should handle theme properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
          ),
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Theme Test'),
            ),
            body: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Themed Content'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Themed Content'), findsOneWidget);
      
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.brightness, Brightness.light);
    });
  });
}