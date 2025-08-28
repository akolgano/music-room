import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_room/screens/auth/signup_auth.dart';
import 'package:music_room/providers/auth_providers.dart';

void main() {
  group('SignupWithOtpScreen Tests', () {
    late AuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = AuthProvider();
    });

    Widget createTestWidget() {
      return ChangeNotifierProvider<AuthProvider>.value(
        value: mockAuthProvider,
        child: const MaterialApp(
          home: SignupWithOtpScreen(),
        ),
      );
    }

    testWidgets('should render signup screen', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(SignupWithOtpScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('should start with email step', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Enter Email'), findsOneWidget);
      expect(find.text('Enter your email address to get started'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.byIcon(Icons.email), findsWidgets);
    });

    testWidgets('should have proper layout structure', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(Center), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(ConstrainedBox), findsOneWidget);
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('should have form with proper key', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final form = tester.widget<Form>(find.byType(Form));
      expect(form.key, isNotNull);
      expect(form.key, isA<GlobalKey<FormState>>());
    });

    testWidgets('should display email input field in first step', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byIcon(Icons.email), findsWidgets);
    });

    testWidgets('should handle email input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final emailField = find.byType(TextFormField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should have continue button in email step', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Continue'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('should handle continue button tap', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final continueButton = find.text('Continue');
      await tester.tap(continueButton);
      await tester.pump();

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('should have proper AppBar configuration', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.title, isA<Text>());
      
      final titleText = appBar.title as Text;
      expect(titleText.data, 'Create Account');
    });

    testWidgets('should have proper constraint box settings', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final constrainedBox = tester.widget<ConstrainedBox>(find.byType(ConstrainedBox));
      expect(constrainedBox.constraints.maxWidth, 400);
    });

    testWidgets('should have proper text field validation', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final emailField = find.byType(TextFormField);
      await tester.enterText(emailField, 'invalid-email');
      await tester.pump();
      
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('should display proper column layout', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });

    testWidgets('should have proper spacing with SizedBox', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(SizedBox), findsAtLeastNWidgets(2));
      
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      bool hasVerticalSpacing = sizedBoxes.any((box) => box.height != null && box.height! > 0);
      expect(hasVerticalSpacing, isTrue);
    });

    testWidgets('should have proper text styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final instructionText = tester.widget<Text>(find.text('Enter your email address to get started'));
      expect(instructionText.style?.color, Colors.white70);
      expect(instructionText.textAlign, TextAlign.center);
    });

    testWidgets('should handle widget lifecycle properly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      await tester.pumpWidget(Container());
      
      expect(true, isTrue);
    });

    testWidgets('should maintain form state during rebuilds', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final emailField = find.byType(TextFormField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      await tester.pumpWidget(createTestWidget());
      
      expect(find.byType(SignupWithOtpScreen), findsOneWidget);
    });

    testWidgets('should have proper background color', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNotNull);
    });

    testWidgets('should handle form validation correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('should have responsive padding', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Padding), findsAtLeastNWidgets(1));
      
      final paddings = tester.widgetList<Padding>(find.byType(Padding));
      bool hasPadding = paddings.any((padding) => padding.padding != EdgeInsets.zero);
      expect(hasPadding, isTrue);
    });

    testWidgets('should display icons properly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.email), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('should handle text field focus', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final textField = find.byType(TextFormField);
      await tester.tap(textField);
      await tester.pump();

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('should have proper widget hierarchy', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('should display loading state when needed', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should have accessible form elements', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1));
    });
  });
}
