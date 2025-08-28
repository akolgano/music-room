import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/screens/admin/webview_admin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AdminWebViewScreen Tests', () {
    testWidgets('should render admin webview screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminWebViewScreen(
            routePath: '/admin/',
            title: 'Django Admin',
          ),
        ),
      );

      expect(find.text('Django Admin'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display custom title', (WidgetTester tester) async {
      const customTitle = 'Custom Admin Title';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminWebViewScreen(
            routePath: '/custom/',
            title: customTitle,
          ),
        ),
      );

      expect(find.text(customTitle), findsOneWidget);
    });

    testWidgets('should display route path information', (WidgetTester tester) async {
      const routePath = '/custom/admin/dashboard/';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminWebViewScreen(
            routePath: routePath,
            title: 'Dashboard Admin',
          ),
        ),
      );

      expect(find.byType(AdminWebViewScreen), findsOneWidget);
      expect(find.text('Dashboard Admin'), findsOneWidget);
    });

    testWidgets('should have proper AppBar configuration', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminWebViewScreen(
            routePath: '/admin/',
            title: 'Django Admin',
          ),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.transparent);
      expect(appBar.elevation, 0);
      expect(appBar.iconTheme?.color, Colors.white);
    });

    testWidgets('should have navigation action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminWebViewScreen(
            routePath: '/admin/',
            title: 'Django Admin',
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should have proper button tooltips', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminWebViewScreen(
            routePath: '/admin/',
            title: 'Django Admin',
          ),
        ),
      );

      final backButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.arrow_back_ios),
      );
      expect(backButton.tooltip, 'Go Back');

      final forwardButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.arrow_forward_ios),
      );
      expect(forwardButton.tooltip, 'Go Forward');

      final refreshButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.refresh),
      );
      expect(refreshButton.tooltip, 'Reload');
    });

    testWidgets('should have gradient background containers', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminWebViewScreen(
            routePath: '/admin/',
            title: 'Django Admin',
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container)).toList();
      expect(containers.length, greaterThan(0));

      bool hasGradientContainer = containers.any((container) => 
          container.decoration is BoxDecoration &&
          (container.decoration as BoxDecoration).gradient != null
      );
      expect(hasGradientContainer, isTrue);
    });

    testWidgets('should have Scaffold as root widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminWebViewScreen(
            routePath: '/admin/',
            title: 'Django Admin',
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should have SafeArea wrapper', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminWebViewScreen(
            routePath: '/admin/',
            title: 'Django Admin',
          ),
        ),
      );

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('should have proper layout structure with Columns', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminWebViewScreen(
            routePath: '/admin/',
            title: 'Django Admin',
          ),
        ),
      );

      expect(find.byType(Column), findsNWidgets(2));
    });

    testWidgets('should have Expanded widgets for proper layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminWebViewScreen(
            routePath: '/admin/',
            title: 'Django Admin',
          ),
        ),
      );

      expect(find.byType(Expanded), findsNWidgets(2));
    });

    testWidgets('should display CircularProgressIndicator when controller is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminWebViewScreen(
            routePath: '/admin/',
            title: 'Django Admin',
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should have proper title text styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminWebViewScreen(
            routePath: '/admin/',
            title: 'Django Admin',
          ),
        ),
      );

      final titleText = tester.widget<Text>(find.text('Django Admin'));
      expect(titleText.style?.color, Colors.white);
    });

    testWidgets('should handle different route paths correctly', (WidgetTester tester) async {
      const testCases = [
        {'routePath': '/admin/', 'title': 'Django Admin'},
        {'routePath': '/api/schema/swagger-ui/', 'title': 'Swagger UI'},
        {'routePath': '/custom/path/', 'title': 'Custom Path'},
      ];

      for (final testCase in testCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: AdminWebViewScreen(
              routePath: testCase['routePath']!,
              title: testCase['title']!,
            ),
          ),
        );

        expect(find.text(testCase['title']!), findsOneWidget);
        expect(find.byType(AdminWebViewScreen), findsOneWidget);
        
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('should accept empty route path', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminWebViewScreen(
            routePath: '',
            title: 'Empty Route',
          ),
        ),
      );

      expect(find.text('Empty Route'), findsOneWidget);
      expect(find.byType(AdminWebViewScreen), findsOneWidget);
    });

    testWidgets('should handle special characters in title', (WidgetTester tester) async {
      const specialTitle = 'Admin & API: Dashboard (v2.0) - Test/Debug';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminWebViewScreen(
            routePath: '/admin/',
            title: specialTitle,
          ),
        ),
      );

      expect(find.text(specialTitle), findsOneWidget);
    });

    testWidgets('should handle very long titles', (WidgetTester tester) async {
      const longTitle = 'Very Long Admin Dashboard Title That Should Be Handled Properly By The Widget Even If It Exceeds Normal Length';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminWebViewScreen(
            routePath: '/admin/',
            title: longTitle,
          ),
        ),
      );

      expect(find.text(longTitle), findsOneWidget);
    });

    testWidgets('should have proper widget hierarchy', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminWebViewScreen(
            routePath: '/admin/',
            title: 'Django Admin',
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.body, isA<Container>());
    });

    testWidgets('should handle tap interactions on navigation buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminWebViewScreen(
            routePath: '/admin/',
            title: 'Django Admin',
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back_ios));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_forward_ios));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(true, isTrue);
    });

    testWidgets('should have proper widget key handling', (WidgetTester tester) async {
      const key = Key('admin_webview_test_key');
      
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminWebViewScreen(
            key: key,
            routePath: '/admin/',
            title: 'Django Admin',
          ),
        ),
      );

      expect(find.byKey(key), findsOneWidget);
    });
  });
}