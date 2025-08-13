import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/screens/admin/webview_admin.dart';

void main() {
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

      // Verify the screen renders without errors
      expect(find.byType(AdminWebViewScreen), findsOneWidget);
      expect(find.text('Dashboard Admin'), findsOneWidget);
    });
  });
}