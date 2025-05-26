// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/providers.dart';
import 'services/music_player_service.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'app.dart';

final fbAppId = dotenv.env['FACEBOOK_APP_ID'];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: .env file not found, using default values');
  }

  if (kIsWeb) {
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: fbAppId.toString(),
      cookie: true,
      xfbml: true,
      version: "v22.0", 
  );
  }
  

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => MusicPlayerService()),
      ],
      child: const MusicRoomApp(),
    ),
  );
}
