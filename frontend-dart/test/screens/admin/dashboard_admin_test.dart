import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_room/screens/admin/dashboard_admin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

    testWidgets('should have proper AppBar styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.transparent);
      expect(appBar.elevation, 0);
      expect(appBar.title, isA<Text>());
    });

    testWidgets('should have gradient background', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
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

    testWidgets('should have GridView with proper layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
      expect(delegate.crossAxisSpacing, 16);
      expect(delegate.mainAxisSpacing, 16);
      expect(delegate.childAspectRatio, 1.2);
    });

    testWidgets('should have InkWell widgets for interaction', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      expect(find.byType(InkWell), findsNWidgets(2));
      
      final inkWells = tester.widgetList<InkWell>(find.byType(InkWell)).toList();
      for (final inkWell in inkWells) {
        expect(inkWell.borderRadius, BorderRadius.circular(12));
      }
    });

    testWidgets('should have Material widgets with transparent colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      final materials = tester.widgetList<Material>(find.byType(Material)).toList();
      final transparentMaterials = materials.where((material) => 
          material.color == Colors.transparent
      ).toList();
      
      expect(transparentMaterials.length, greaterThanOrEqualTo(2));
    });

    testWidgets('should display description text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      expect(find.text('Access Django admin interface and API endpoints directly from the app.'), 
             findsOneWidget);
    });

    testWidgets('should have proper text styling for title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      final titleText = tester.widget<Text>(find.text('Django Routes'));
      expect(titleText.style?.color, Colors.white);
      expect(titleText.style?.fontSize, 24);
      expect(titleText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('should have proper text styling for description', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      final descText = tester.widget<Text>(
          find.text('Access Django admin interface and API endpoints directly from the app.'));
      expect(descText.style?.color, Colors.grey);
      expect(descText.style?.fontSize, 16);
    });

    testWidgets('should have proper icon colors and sizes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      final adminIcon = tester.widget<Icon>(find.byIcon(Icons.admin_panel_settings));
      expect(adminIcon.size, 32);
      expect(adminIcon.color, Colors.red);

      final apiIcon = tester.widget<Icon>(find.byIcon(Icons.api));
      expect(apiIcon.size, 32);
      expect(apiIcon.color, Colors.green);
    });

    testWidgets('should have proper card text styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      final djangoAdminText = tester.widget<Text>(find.text('Django Admin'));
      expect(djangoAdminText.style?.color, Colors.white);
      expect(djangoAdminText.style?.fontSize, 16);
      expect(djangoAdminText.style?.fontWeight, FontWeight.bold);

      final swaggerText = tester.widget<Text>(find.text('Swagger UI'));
      expect(swaggerText.style?.color, Colors.white);
      expect(swaggerText.style?.fontSize, 16);
      expect(swaggerText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('should have proper subtitle text styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      final adminSubtitle = tester.widget<Text>(find.text('Admin interface'));
      expect(adminSubtitle.style?.color, Colors.grey);
      expect(adminSubtitle.style?.fontSize, 12);

      final apiSubtitle = tester.widget<Text>(find.text('Interactive API docs'));
      expect(apiSubtitle.style?.color, Colors.grey);
      expect(apiSubtitle.style?.fontSize, 12);
    });

    testWidgets('should have SafeArea wrapper', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('should have Scaffold as root widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should have Expanded widgets for proper layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      expect(find.byType(Expanded), findsNWidgets(2));
    });

    testWidgets('should have proper padding configuration', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      final paddings = tester.widgetList<Padding>(find.byType(Padding)).toList();
      expect(paddings.length, greaterThanOrEqualTo(2));
      
      bool hasMainPadding = paddings.any((padding) => 
          padding.padding == const EdgeInsets.all(4.0)
      );
      expect(hasMainPadding, isTrue);
    });

    testWidgets('should have SizedBox for spacing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox)).toList();
      expect(sizedBoxes.length, greaterThanOrEqualTo(4));
      
      bool hasHeight16 = sizedBoxes.any((box) => box.height == 16);
      bool hasHeight32 = sizedBoxes.any((box) => box.height == 32);
      bool hasHeight12 = sizedBoxes.any((box) => box.height == 12);
      
      expect(hasHeight16, isTrue);
      expect(hasHeight32, isTrue);
      expect(hasHeight12, isTrue);
    });

    testWidgets('should have proper Column layout structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      final columns = tester.widgetList<Column>(find.byType(Column)).toList();
      expect(columns.length, greaterThanOrEqualTo(3));
      
      bool hasStartAlignment = columns.any((column) => 
          column.crossAxisAlignment == CrossAxisAlignment.start
      );
      expect(hasStartAlignment, isTrue);
    });

    testWidgets('should handle tap interactions on cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      final inkWells = find.byType(InkWell);
      expect(inkWells, findsNWidgets(2));
      
      await tester.tap(inkWells.first);
      await tester.pump();
      
      await tester.tap(inkWells.last);
      await tester.pump();
      
      expect(true, isTrue);
    });

    testWidgets('should have proper icon theme configuration', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.iconTheme?.color, Colors.white);
    });
  });
}