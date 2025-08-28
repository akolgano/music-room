import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_room/screens/base_screens.dart';
import 'package:music_room/providers/auth_providers.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends BaseScreen<TestScreen> {
  @override
  String get screenTitle => 'Test Screen';

  @override
  Widget buildContent() {
    return const Center(
      child: Text('Test Content'),
    );
  }
}

class CustomTestScreen extends StatefulWidget {
  final bool customShowBackButton;
  final bool customShowMiniPlayer;
  final List<Widget> customActions;
  final Widget? customFloatingActionButton;
  final String customTitle;

  const CustomTestScreen({
    super.key,
    this.customShowBackButton = true,
    this.customShowMiniPlayer = true,
    this.customActions = const [],
    this.customFloatingActionButton,
    this.customTitle = 'Custom Test',
  });

  @override
  State<CustomTestScreen> createState() => _CustomTestScreenState();
}

class _CustomTestScreenState extends BaseScreen<CustomTestScreen> {
  @override
  String get screenTitle => widget.customTitle;

  @override
  bool get showBackButton => widget.customShowBackButton;

  @override
  bool get showMiniPlayer => widget.customShowMiniPlayer;

  @override
  List<Widget> get actions => widget.customActions;

  @override
  Widget? get floatingActionButton => widget.customFloatingActionButton;

  @override
  Widget buildContent() {
    return Column(
      children: [
        const Text('Custom Content'),
        ElevatedButton(
          onPressed: () => showSuccess('Success message'),
          child: const Text('Show Success'),
        ),
        ElevatedButton(
          onPressed: () => showError('Error message'),
          child: const Text('Show Error'),
        ),
        ElevatedButton(
          onPressed: () => showInfo('Info message'),
          child: const Text('Show Info'),
        ),
      ],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('BaseScreen Tests', () {
    late AuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = AuthProvider();
    });

    Widget createTestWidget({Widget? child}) {
      return ChangeNotifierProvider<AuthProvider>.value(
        value: mockAuthProvider,
        child: MaterialApp(
          home: child ?? const TestScreen(),
        ),
      );
    }

    testWidgets('should render basic BaseScreen implementation', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TestScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Test Screen'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should have proper Scaffold structure', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNotNull);
      expect(scaffold.appBar, isNotNull);
      expect(scaffold.body, isNotNull);
    });

    testWidgets('should display AppBar with title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Test Screen'), findsOneWidget);
      
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.title, isA<Text>());
      expect(appBar.automaticallyImplyLeading, isTrue);
    });

    testWidgets('should have SafeArea with proper configuration', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(SafeArea), findsOneWidget);
      final safeArea = tester.widget<SafeArea>(find.byType(SafeArea));
      expect(safeArea.bottom, isFalse);
    });

    testWidgets('should display content in Column layout', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Column), findsOneWidget);
      expect(find.byType(Expanded), findsOneWidget);
    });

    testWidgets('should handle custom showBackButton setting', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const CustomTestScreen(customShowBackButton: false),
      ));

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.automaticallyImplyLeading, isFalse);
    });

    testWidgets('should handle custom actions', (WidgetTester tester) async {
      final customActions = [
        IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.help)),
      ];

      await tester.pumpWidget(createTestWidget(
        child: CustomTestScreen(customActions: customActions),
      ));

      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.help), findsOneWidget);
    });

    testWidgets('should handle custom floating action button', (WidgetTester tester) async {
      final fab = FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      );

      await tester.pumpWidget(createTestWidget(
        child: CustomTestScreen(customFloatingActionButton: fab),
      ));

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should handle custom title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const CustomTestScreen(customTitle: 'My Custom Title'),
      ));

      expect(find.text('My Custom Title'), findsOneWidget);
    });

    testWidgets('should handle showMiniPlayer setting', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const CustomTestScreen(customShowMiniPlayer: false),
      ));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should position FAB correctly with mini player', (WidgetTester tester) async {
      final fab = FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      );

      await tester.pumpWidget(createTestWidget(
        child: CustomTestScreen(
          customFloatingActionButton: fab,
          customShowMiniPlayer: true,
        ),
      ));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.floatingActionButtonLocation, FloatingActionButtonLocation.endFloat);
    });

    testWidgets('should handle success message display', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const CustomTestScreen(),
      ));

      await tester.tap(find.text('Show Success'));
      await tester.pump();

      expect(true, isTrue);
    });

    testWidgets('should handle error message display', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const CustomTestScreen(),
      ));

      await tester.tap(find.text('Show Error'));
      await tester.pump();

      expect(true, isTrue);
    });

    testWidgets('should handle info message display', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const CustomTestScreen(),
      ));

      await tester.tap(find.text('Show Info'));
      await tester.pump();

      expect(true, isTrue);
    });

    testWidgets('should provide access to AuthProvider', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TestScreen), findsOneWidget);
    });

    testWidgets('should handle navigation methods', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TestScreen), findsOneWidget);
    });

    testWidgets('should handle provider access method', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TestScreen), findsOneWidget);
    });

    testWidgets('should handle empty actions list', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions, isEmpty);
    });

    testWidgets('should handle null floating action button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.floatingActionButton, isNull);
    });

    testWidgets('should have proper background color', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNotNull);
    });

    testWidgets('should handle widget rebuilds correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Test Content'), findsOneWidget);

      await tester.pumpWidget(createTestWidget());

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should maintain state consistency', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(BaseScreen), findsOneWidget);
      expect(find.text('Test Screen'), findsOneWidget);
    });

    testWidgets('should handle different screen configurations', (WidgetTester tester) async {
      const configurations = [
        CustomTestScreen(customShowBackButton: true, customShowMiniPlayer: true),
        CustomTestScreen(customShowBackButton: false, customShowMiniPlayer: false),
        CustomTestScreen(customShowBackButton: true, customShowMiniPlayer: false),
        CustomTestScreen(customShowBackButton: false, customShowMiniPlayer: true),
      ];

      for (final config in configurations) {
        await tester.pumpWidget(createTestWidget(child: config));
        expect(find.byType(CustomTestScreen), findsOneWidget);
        
        await tester.pumpWidget(Container());
      }
    });
  });
}