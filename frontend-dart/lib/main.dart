// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/service_locator.dart';
import 'core/app_builder.dart';
import 'core/consolidated_core.dart';
import 'providers/auth_provider.dart';
import 'providers/music_provider.dart';
import 'providers/friend_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/device_provider.dart';
import 'providers/dynamic_theme_provider.dart';
import 'providers/playlist_license_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: .env file not found or failed to load: $e');
  }
  
  await setupServiceLocator();
  await SocialLoginUtils.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ...AppBuilder.buildProviders(),
        ...AppBuilder.buildAdditionalProviders(),
      ],
      child: Consumer<DynamicThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            theme: themeProvider.dynamicTheme,
            home: const AuthWrapperScreen(),
            routes: AppBuilder.buildRoutes(),
            onGenerateRoute: AppBuilder.generateRoute,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthWrapperScreen extends StatelessWidget {
  const AuthWrapperScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoggedIn) {
          return const HomeScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}
