// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'core/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/music_provider.dart';
import 'providers/device_provider.dart';
import 'services/music_player_service.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/music/track_search_screen.dart';
import 'screens/music/playlist_editor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: Could not load .env file: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()), 
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => MusicPlayerService()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            theme: AppTheme.darkTheme,
            home: authProvider.isLoggedIn ? const HomeScreen() : const AuthScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/auth': (context) => const AuthScreen(),
              '/track_search': (context) => const TrackSearchScreen(),
              '/playlist_editor': (context) => const PlaylistEditorScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
