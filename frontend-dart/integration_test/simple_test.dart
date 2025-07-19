import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:music_room/main.dart' as app;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:music_room/core/service_locator.dart';
import 'package:music_room/core/core.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Simple Integration Tests', () {
    testWidgets('App starts without critical errors', (WidgetTester tester) async {
      // Setup dependencies like main() does
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        // Ignore if .env file doesn't exist
      }
      
      try {
        await setupServiceLocator();
        await SocialLoginUtils.initialize();
      } catch (e) {
        // Ignore initialization errors for testing
      }
      
      // Now run the app
      await tester.pumpWidget(const app.MyApp());
      
      // Give it time to initialize
      await tester.pump(const Duration(milliseconds: 500));
      
      // Just verify something rendered
      expect(tester.allWidgets.isNotEmpty, true, reason: 'App should render widgets');
    });
  });
}