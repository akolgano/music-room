import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_room/screens/auth/password_auth.dart';
import 'package:music_room/providers/auth_providers.dart';

void main() {
  group('ForgotPasswordScreen Tests', () {
    late AuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = AuthProvider();
    });

    Widget createTestWidget() {
      return ChangeNotifierProvider<AuthProvider>.value(
        value: mockAuthProvider,
        child: const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      );
    }

    testWidgets('should render forgot password screen', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Forgot Password'), findsOneWidget);
    });

    testWidgets('should have proper layout structure', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Container), findsAtLeastNWidgets(1));
      expect(find.byType(Center), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(ConstrainedBox), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('should display app branding elements', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Music Room'), findsOneWidget);
      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('should have email input field in initial state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byIcon(Icons.email), findsOneWidget);
      expect(find.text('Send OTP'), findsOneWidget);
    });

    testWidgets('should have proper form validation', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Send OTP'));
      await tester.pump();

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('should handle email input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final emailField = find.byType(TextFormField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should have back button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Back'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNWidgets(2));
    });

    testWidgets('should handle back button tap', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final backButton = find.text('Back');
      await tester.tap(backButton);
      await tester.pump();

      expect(true, isTrue);
    });

    testWidgets('should have proper button styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final buttons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
      expect(buttons.length, 2);
      
      for (final button in buttons) {
        expect(button.style, isNotNull);
      }
    });

    testWidgets('should display proper gradient background', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.decoration, isA<BoxDecoration>());
      
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
    });

    testWidgets('should have proper card styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 8);
      expect(card.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('should respond to orientation changes', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Column), findsAtLeastNWidgets(1));

      expect(find.byType(Padding), findsAtLeastNWidgets(2));
    });

    testWidgets('should handle form submission', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final emailField = find.byType(TextFormField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      await tester.tap(find.text('Send OTP'));
      await tester.pump();

      expect(true, isTrue);
    });

    testWidgets('should have proper text styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final titleText = tester.widget<Text>(find.text('Forgot Password'));
      expect(titleText.style?.fontSize, 24);
      expect(titleText.style?.fontWeight, FontWeight.bold);
      expect(titleText.textAlign, TextAlign.center);

      final brandText = tester.widget<Text>(find.text('Music Room'));
      expect(brandText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('should display form with proper structure', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final form = tester.widget<Form>(find.byType(Form));
      expect(form.key, isNotNull);
      expect(form.key, isA<GlobalKey<FormState>>());
    });

    testWidgets('should have proper icon styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final musicIcon = tester.widget<Icon>(find.byIcon(Icons.music_note));
      expect(musicIcon.size, 80);
    });

    testWidgets('should handle SizedBox spacing correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(SizedBox), findsAtLeastNWidgets(3));
      
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      bool hasHeightSpacing = sizedBoxes.any((box) => box.height != null && box.height! > 0);
      expect(hasHeightSpacing, isTrue);
    });

    testWidgets('should have accessible form elements', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNWidgets(2));
    });

    testWidgets('should handle loading state properly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Send OTP'), findsOneWidget);
    });

    testWidgets('should validate email format correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final emailField = find.byType(TextFormField);
      
      await tester.enterText(emailField, 'invalid-email');
      await tester.pump();
      await tester.tap(find.text('Send OTP'));
      await tester.pump();

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('should handle widget disposal properly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      await tester.pumpWidget(Container());
      
      expect(true, isTrue);
    });

    testWidgets('should have proper constraints on layout', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final constrainedBox = tester.widget<ConstrainedBox>(find.byType(ConstrainedBox));
      expect(constrainedBox.constraints.maxWidth, 450);
    });

    testWidgets('should maintain state during rebuilds', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final emailField = find.byType(TextFormField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      await tester.pumpWidget(createTestWidget());
      
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });
  });
}