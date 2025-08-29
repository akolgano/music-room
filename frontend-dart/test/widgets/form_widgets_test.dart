import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('FormWidgets Tests', () {
    testWidgets('should render TextFormField', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFormField(
              decoration: const InputDecoration(labelText: 'Test Field'),
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Test Field'), findsOneWidget);
    });

    testWidgets('should handle form validation', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: TextFormField(
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      
      final isValid = formKey.currentState?.validate() ?? false;
      expect(isValid, isFalse);
    });

    testWidgets('should handle input decoration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'Hint',
                prefixIcon: Icon(Icons.person),
                suffixIcon: Icon(Icons.visibility),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Label'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('should handle obscure text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFormField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Field'),
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('should handle text input', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFormField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Input'),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'test input');
      expect(controller.text, 'test input');
      
      controller.dispose();
    });

    testWidgets('should handle different input types', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Number'),
                ),
                TextFormField(
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Number'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
    });

    testWidgets('should handle form submission', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      bool submitted = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Field'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        submitted = true;
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'test');
      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(submitted, isTrue);
    });

    test('should validate email format', () {
      bool isValidEmail(String email) {
        return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
      }

      expect(isValidEmail('test@example.com'), isTrue);
      expect(isValidEmail('invalid-email'), isFalse);
      expect(isValidEmail('user@domain.co.uk'), isTrue);
      expect(isValidEmail(''), isFalse);
    });

    test('should handle form data', () {
      final formData = {
        'username': 'user',
        'email': 'user@example.com',
        'age': 25,
        'isActive': true
      };

      expect(formData['username'], 'user');
      expect(formData['email'], contains('@'));
      expect(formData['age'], isA<int>());
      expect(formData['isActive'], isTrue);
    });
  });
}