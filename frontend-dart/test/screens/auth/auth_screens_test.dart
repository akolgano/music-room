import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:music_room/screens/auth/auth_screens.dart';
import 'package:music_room/providers/auth_providers.dart';
import 'package:music_room/core/locator_core.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'auth_screens_test.mocks.dart';

@GenerateMocks([AuthProvider])


void main() {
  group('AuthScreens Tests', () {
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      GetIt.instance.reset();
      mockAuthProvider = MockAuthProvider();
      getIt.registerSingleton<AuthProvider>(mockAuthProvider);
      
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.hasError).thenReturn(false);
      when(mockAuthProvider.errorMessage).thenReturn('');
      when(mockAuthProvider.isLoggedIn).thenReturn(false);
    });

    tearDown(() {
      GetIt.instance.reset();
    });

    Widget buildTestWidget(Widget child) {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: child,
          ),
        ),
        child: child,
      );
    }

    testWidgets('should render login screen by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(const AuthScreen()),
      );

      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
      expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1));
    });

    testWidgets('should show loading state when authenticating', (WidgetTester tester) async {
      when(mockAuthProvider.isLoading).thenReturn(true);
      
      await tester.pumpWidget(
        buildTestWidget(const AuthScreen()),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error message when login fails', (WidgetTester tester) async {
      when(mockAuthProvider.hasError).thenReturn(true);
      when(mockAuthProvider.errorMessage).thenReturn('Invalid credentials');
      
      await tester.pumpWidget(
        buildTestWidget(const AuthScreen()),
      );

      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('should call login when login button is pressed', (WidgetTester tester) async {
      when(mockAuthProvider.login(any, any)).thenAnswer((_) async => true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      verify(mockAuthProvider.login('testuser', 'password123')).called(1);
    });

    testWidgets('should validate required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      expect(find.text('Please enter username'), findsOneWidget);
      expect(find.text('Please enter password'), findsOneWidget);
    });

    testWidgets('should switch to signup screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(3));
    });

    testWidgets('should handle Google login button tap', (WidgetTester tester) async {
      when(mockAuthProvider.googleLogin()).thenAnswer((_) async => true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Sign in with Google'));
      await tester.pump();

      verify(mockAuthProvider.googleLogin()).called(1);
    });

    testWidgets('should handle Facebook login button tap', (WidgetTester tester) async {
      when(mockAuthProvider.facebookLogin()).thenAnswer((_) async => true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Sign in with Facebook'));
      await tester.pump();

      verify(mockAuthProvider.facebookLogin()).called(1);
    });

    testWidgets('should navigate to forgot password screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Enter your email address'), findsOneWidget);
    });

    testWidgets('should validate email format in signup', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(1), 'invalid-email');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('should validate password strength in signup', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(2), '123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pump();

      expect(find.textContaining('Password must be'), findsOneWidget);
    });

    testWidgets('should confirm password match in signup', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('should call signup when create account button is pressed', (WidgetTester tester) async {
      when(mockAuthProvider.sendSignupEmailOtp(any)).thenAnswer((_) async => true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'newuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'new@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');
      
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
      await tester.pump();

      verify(mockAuthProvider.sendSignupEmailOtp('new@example.com')).called(1);
    });

    testWidgets('should handle password visibility toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      final visibilityIcon = find.byIcon(Icons.visibility_off);
      
      expect(visibilityIcon, findsOneWidget);
      
      await tester.tap(visibilityIcon);
      await tester.pump();
      
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('should show terms and conditions in signup', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Terms and Conditions'), findsOneWidget);
      expect(find.textContaining('Privacy Policy'), findsOneWidget);
    });

    testWidgets('should handle keyboard submission for login', (WidgetTester tester) async {
      when(mockAuthProvider.login(any, any)).thenAnswer((_) async => true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, 'testuser');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      verify(mockAuthProvider.login('testuser', 'password123')).called(1);
    });

    testWidgets('should disable login button when loading', (WidgetTester tester) async {
      when(mockAuthProvider.isLoading).thenReturn(true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      final loginButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Login'),
      );
      
      expect(loginButton.onPressed, isNull);
    });

    testWidgets('should show remember me checkbox', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
    });

    testWidgets('should toggle remember me checkbox', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
      
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      
      final updatedCheckbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(updatedCheckbox.value, isTrue);
    });

    testWidgets('should handle back navigation from signup', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
      
      await tester.tap(find.text('Already have an account? Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('should show appropriate app branding', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      expect(find.textContaining('Music Room'), findsOneWidget);
      expect(find.byType(Image), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle screen orientation changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      expect(find.text('Login'), findsOneWidget);
      
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/platform',
        null,
        (data) {},
      );
      await tester.pump();
      
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('should show social login divider', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuthProvider,
            child: const AuthScreen(),
          ),
        ),
      );

      expect(find.text('Or continue with'), findsOneWidget);
      expect(find.byType(Divider), findsAtLeastNWidgets(2));
    });
  });
}
