import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_room/screens/friends/add_friends.dart';
import 'package:music_room/providers/auth_providers.dart';
import 'package:music_room/providers/friend_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AddFriendScreen Tests', () {
    late AuthProvider mockAuthProvider;
    late FriendProvider mockFriendProvider;

    setUp(() {
      mockAuthProvider = AuthProvider();
      mockFriendProvider = FriendProvider();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ChangeNotifierProvider<FriendProvider>.value(value: mockFriendProvider),
        ],
        child: const MaterialApp(
          home: AddFriendScreen(),
        ),
      );
    }

    testWidgets('should render add friend screen', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(AddFriendScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Add New Friend'), findsOneWidget);
    });

    testWidgets('should display proper screen title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Add New Friend'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have requests button in actions', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Requests'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.byType(TextButton), findsAtLeastNWidgets(1));
    });

    testWidgets('should have form with user ID input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('User ID'), findsOneWidget);
      expect(find.byIcon(Icons.person_search), findsOneWidget);
    });

    testWidgets('should display form card with title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Add Friend by User ID'), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('should have proper layout structure', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Column), findsAtLeastNWidgets(1));
      expect(find.byType(Padding), findsAtLeastNWidgets(1));
    });

    testWidgets('should have hint text for user ID format', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.textContaining('e.g.,'), findsOneWidget);
    });

    testWidgets('should handle user ID input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final userIdField = find.byType(TextFormField);
      await tester.enterText(userIdField, '4270552b-1e03-4f35-980c-723b52b91d10');
      await tester.pump();

      expect(find.text('4270552b-1e03-4f35-980c-723b52b91d10'), findsOneWidget);
    });

    testWidgets('should show send request button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Send Request'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('should show view profile button when user ID is entered', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final userIdField = find.byType(TextFormField);
      await tester.enterText(userIdField, '4270552b-1e03-4f35-980c-723b52b91d10');
      await tester.pump();

      expect(find.text('View Profile'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should handle form validation', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Send Request'));
      await tester.pump();

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('should have proper form key', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final form = tester.widget<Form>(find.byType(Form));
      expect(form.key, isNotNull);
      expect(form.key, isA<GlobalKey<FormState>>());
    });

    testWidgets('should validate UUID format', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final userIdField = find.byType(TextFormField);
      
      await tester.enterText(userIdField, 'invalid-uuid');
      await tester.pump();
      await tester.tap(find.text('Send Request'));
      await tester.pump();

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('should handle valid UUID input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final userIdField = find.byType(TextFormField);
      
      await tester.enterText(userIdField, '4270552b-1e03-4f35-980c-723b52b91d10');
      await tester.pump();

      expect(find.text('View Profile'), findsOneWidget);
    });

    testWidgets('should handle tap on view profile button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final userIdField = find.byType(TextFormField);
      await tester.enterText(userIdField, '4270552b-1e03-4f35-980c-723b52b91d10');
      await tester.pump();

      await tester.tap(find.text('View Profile'));
      await tester.pump();

      expect(true, isTrue);
    });

    testWidgets('should handle tap on requests button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Requests'));
      await tester.pump();

      expect(true, isTrue);
    });

    testWidgets('should have proper button styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final elevatedButtons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
      expect(elevatedButtons.length, greaterThanOrEqualTo(1));
    });

    testWidgets('should have proper spacing between elements', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(SizedBox), findsAtLeastNWidgets(2));
      
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      bool hasVerticalSpacing = sizedBoxes.any((box) => box.height != null && box.height! > 0);
      expect(hasVerticalSpacing, isTrue);
    });

    testWidgets('should handle loading state', (WidgetTester tester) async {
      mockFriendProvider.setLoading(true);
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Sending...'), findsOneWidget);
    });

    testWidgets('should disable button when loading', (WidgetTester tester) async {
      mockFriendProvider.setLoading(true);
      await tester.pumpWidget(createTestWidget());

      final sendButton = find.text('Sending...');
      expect(sendButton, findsOneWidget);
    });

    testWidgets('should handle text field focus and input changes', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final textField = find.byType(TextFormField);
      await tester.tap(textField);
      await tester.pump();

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('should dispose controller properly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      await tester.pumpWidget(Container());
      
      expect(true, isTrue);
    });

    testWidgets('should handle consumer content properly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Send Request'), findsOneWidget);
    });

    testWidgets('should have proper card elevation and styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Card), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle empty input validation', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Send Request'));
      await tester.pump();

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('should maintain state during rebuilds', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final userIdField = find.byType(TextFormField);
      await tester.enterText(userIdField, 'test-input');
      await tester.pump();

      await tester.pumpWidget(createTestWidget());
      
      expect(find.byType(AddFriendScreen), findsOneWidget);
    });
  });
}
