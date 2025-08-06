import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/screens/admin/admin_dashboard_screen.dart';

void main() {
  group('AdminDashboardScreen Tests', () {
    testWidgets('should render admin dashboard screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      expect(find.text('Admin Dashboard'), findsOneWidget);
      expect(find.text('Django Routes'), findsOneWidget);
      expect(find.text('Django Admin'), findsOneWidget);
      expect(find.text('Swagger UI'), findsOneWidget);
    });

    testWidgets('should have route cards with proper icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      expect(find.byIcon(Icons.admin_panel_settings), findsOneWidget);
      expect(find.byIcon(Icons.api), findsOneWidget);
    });

    testWidgets('should have proper subtitles', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      expect(find.text('Admin interface'), findsOneWidget);
      expect(find.text('Interactive API docs'), findsOneWidget);
    });
  });
}