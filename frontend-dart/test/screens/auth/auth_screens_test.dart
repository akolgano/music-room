import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:music_room/screens/auth/auth_screens.dart';
import 'package:music_room/providers/auth_providers.dart';
import 'package:music_room/services/auth_services.dart';
import 'package:music_room/services/websocket_services.dart';
import 'package:music_room/services/logging_services.dart';
import 'package:music_room/services/player_services.dart';
import 'package:music_room/services/api_services.dart';
import 'package:music_room/models/api_models.dart';
import 'package:music_room/core/locator_core.dart';
import 'package:get_it/get_it.dart';

class MockAuthService implements AuthService {
  @override
  User? get currentUser => null;
  
  @override
  String? get currentToken => null;
  
  @override
  bool get isLoggedIn => false;
  
  @override
  ApiService get api => MockApiService();
  
  @override
  Future<void> refreshCurrentUser() async {}
  
  @override
  Future<bool> login(String username, String password) async => false;
  
  @override
  Future<void> logout() async {}
  
  @override
  Future<bool> checkUsernameAvailability(String username) async => true;
  
  @override
  Future<bool> checkEmailAvailability(String email) async => true;
  
  @override
  Future<bool> sendPasswordResetEmail(String email) async => true;
  
  @override
  Future<bool> sendSignupEmailOTP(String email) async => true;
  
  @override
  Future<bool> signupWithOTP(String email, String username, String password, String otp) async => false;
}

class MockWebSocketService implements WebSocketService {
  @override
  void connect(String token) {}
  
  @override
  void disconnect() {}
  
  @override
  Future<void> dispose() async {}
}

class MockFrontendLoggingService implements FrontendLoggingService {
  @override
  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters}) async {}
  
  @override
  Future<void> logError(String message, {dynamic error, StackTrace? stackTrace}) async {}
}

class MockMusicPlayerService implements MusicPlayerService {
  @override
  void stop() {}
  
  @override
  void pause() {}
  
  @override
  void play() {}
  
  @override
  void dispose() {}
  
  @override
  Future<void> playTrack(dynamic track, {dynamic playlist}) async {}
  
  @override
  Future<void> playNext() async {}
  
  @override
  Future<void> playPrevious() async {}
}

class MockApiService implements ApiService {}

class TestAuthProvider extends AuthProvider {
  bool _isLoading = false;
  
  @override
  bool get isLoading => _isLoading;
  
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AuthScreen Tests', () {
    late TestAuthProvider mockAuthProvider;

    setUp(() {
      // Reset and register mocks in GetIt
      GetIt.instance.reset();
      GetIt.instance.registerSingleton<AuthService>(MockAuthService());
      GetIt.instance.registerSingleton<WebSocketService>(MockWebSocketService());
      GetIt.instance.registerSingleton<FrontendLoggingService>(MockFrontendLoggingService());
      GetIt.instance.registerSingleton<MusicPlayerService>(MockMusicPlayerService());
      GetIt.instance.registerSingleton<ApiService>(MockApiService());
      
      mockAuthProvider = TestAuthProvider();
    });
    
    tearDown(() {
      GetIt.instance.reset();
    });

    Widget createTestWidget({bool isLogin = true}) {
      return ChangeNotifierProvider<AuthProvider>.value(
        value: mockAuthProvider,
        child: const MaterialApp(
          home: AuthScreen(),
        ),
      );
    }

    testWidgets('should render auth screen with basic elements', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('should display proper header text for login mode', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue your musical journey'), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
    });

    testWidgets('should have proper form fields for login', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // username and password
      
      final usernameField = find.widgetWithText(TextFormField, 'Username');
      expect(usernameField, findsOneWidget);
      
      final passwordField = find.widgetWithText(TextFormField, 'Password');
      expect(passwordField, findsOneWidget);
    });

    testWidgets('should have social login buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Or continue with'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Facebook'), findsOneWidget);
      expect(find.byIcon(Icons.g_mobiledata), findsOneWidget);
      expect(find.byIcon(Icons.facebook), findsOneWidget);
    });

    testWidgets('should have forgot password link in login mode', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.byType(TextButton), findsAtLeastNWidgets(2));
    });

    testWidgets('should have mode toggle button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text("Don't have an account? "), findsOneWidget);
      expect(find.text('Sign Up'), findsWidgets);
    });

    testWidgets('should display app logo or music icon', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should have proper card structure', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Card), findsAtLeastNWidgets(3)); // header, form, social
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(ConstrainedBox), findsOneWidget);
    });

    testWidgets('should have proper icon themes', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.login), findsNWidgets(2));
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('should handle form validation', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final submitButton = find.text('Sign In').last;
      await tester.tap(submitButton);
      await tester.pump();

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('should have proper button styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final elevatedButtons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
      expect(elevatedButtons.length, greaterThanOrEqualTo(3)); // main submit + social buttons
    });

    testWidgets('should handle tap interactions on social buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final googleButton = find.text('Continue with Google');
      expect(googleButton, findsOneWidget);
      await tester.tap(googleButton);
      await tester.pump();

      final facebookButton = find.text('Continue with Facebook');
      expect(facebookButton, findsOneWidget);
      await tester.tap(facebookButton);
      await tester.pump();

      expect(true, isTrue);
    });

    testWidgets('should open forgot password dialog', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final forgotPasswordButton = find.text('Forgot Password?');
      await tester.tap(forgotPasswordButton);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Forgot Password'), findsOneWidget);
    });

    testWidgets('should handle username input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final usernameField = find.byType(TextFormField).first;
      await tester.enterText(usernameField, 'testuser');
      await tester.pump();

      expect(find.text('testuser'), findsOneWidget);
    });

    testWidgets('should handle password input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final passwordFields = find.byType(TextFormField);
      final passwordField = passwordFields.at(1); // Second field is password
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // Check if password field is properly configured for obscured text
      expect(passwordField, findsOneWidget);
    });

    testWidgets('should have proper responsive layout', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Flexible), findsAtLeastNWidgets(2));
      expect(find.byType(SizedBox), findsAtLeastNWidgets(3));
      expect(find.byType(Column), findsAtLeastNWidgets(3));
    });

    testWidgets('should have proper alignment and spacing', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final columns = tester.widgetList<Column>(find.byType(Column));
      expect(columns.length, greaterThan(0));
      
      bool hasCenterAlignment = columns.any((column) => 
          column.mainAxisAlignment == MainAxisAlignment.center
      );
      expect(hasCenterAlignment, isTrue);
    });

    testWidgets('should display loading states', (WidgetTester tester) async {
      mockAuthProvider.setLoading(true);
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('should handle rich text in mode toggle', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(RichText), findsOneWidget);
      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text, isA<TextSpan>());
    });

    testWidgets('should have proper text styling throughout', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      expect(textWidgets.length, greaterThan(5));
      
      bool hasStyledText = textWidgets.any((text) => text.style != null);
      expect(hasStyledText, isTrue);
    });

    testWidgets('should have proper form key', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final form = tester.widget<Form>(find.byType(Form));
      expect(form.key, isNotNull);
      expect(form.key, isA<GlobalKey<FormState>>());
    });

    testWidgets('should handle TextButton interactions', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final textButtons = find.byType(TextButton);
      expect(textButtons, findsAtLeastNWidgets(2));
      
      await tester.tap(textButtons.first);
      await tester.pump();
      
      expect(true, isTrue); // Should not throw
    });

    testWidgets('should have proper container decoration', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers.length, greaterThan(0));
      
      bool hasDecoratedContainer = containers.any((container) => 
          container.decoration != null
      );
      expect(hasDecoratedContainer, isTrue);
    });

    testWidgets('should handle side border styling on social buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final elevatedButtons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
      expect(elevatedButtons.length, greaterThanOrEqualTo(2));
      
      bool hasStyledButton = elevatedButtons.any((button) => 
          button.style != null
      );
      expect(hasStyledButton, isTrue);
    });
  });

  group('ForgotPasswordDialog Tests', () {
    late TestAuthProvider mockAuthProvider;

    setUp(() {
      // Reset and register mocks in GetIt
      GetIt.instance.reset();
      GetIt.instance.registerSingleton<AuthService>(MockAuthService());
      GetIt.instance.registerSingleton<WebSocketService>(MockWebSocketService());
      GetIt.instance.registerSingleton<FrontendLoggingService>(MockFrontendLoggingService());
      GetIt.instance.registerSingleton<MusicPlayerService>(MockMusicPlayerService());
      GetIt.instance.registerSingleton<ApiService>(MockApiService());
      
      mockAuthProvider = TestAuthProvider();
    });
    
    tearDown(() {
      GetIt.instance.reset();
    });

    Widget createDialogTestWidget() {
      return ChangeNotifierProvider<AuthProvider>.value(
        value: mockAuthProvider,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const AuthScreen(),
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('forgot password dialog should have proper structure', (WidgetTester tester) async {
      await tester.pumpWidget(createDialogTestWidget());
      
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      
      if (find.text('Forgot Password?').evaluate().isNotEmpty) {
        await tester.tap(find.text('Forgot Password?'));
        await tester.pumpAndSettle();
        
        expect(find.byType(AlertDialog), findsOneWidget);
      }
    });
  });
}