// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/music_provider.dart';
import 'providers/friend_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/device_provider.dart';
import 'providers/dynamic_theme_provider.dart';
import 'providers/playlist_license_provider.dart';
import 'services/music_player_service.dart';
import 'services/websocket_service.dart';
import 'app.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 

final fbAppId = dotenv.env['FACEBOOK_APP_ID'];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: Could not load .env file: $e');
  }
  
  if (kIsWeb) {
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: fbAppId.toString(),
      cookie: true,
      xfbml: true,
      version: "v22.0", 
    );
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => DynamicThemeProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistLicenseProvider()),
        ChangeNotifierProxyProvider<DynamicThemeProvider, MusicPlayerService>(
          create: (context) => MusicPlayerService(
            themeProvider: Provider.of<DynamicThemeProvider>(context, listen: false),
          ),
          update: (context, themeProvider, previous) => previous ?? MusicPlayerService(
            themeProvider: themeProvider,
          ),
        ),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        Provider<WebSocketService>(create: (_) => WebSocketService()),
      ],
      child: const MusicRoomApp(),
    );
  }
}
