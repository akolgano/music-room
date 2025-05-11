// main.dart
import 'app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/music_provider.dart';
import 'providers/friend_provider.dart';
import 'services/music_player_service.dart';

// Music Control Delegation will not be implemented
Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => MusicPlayerService()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
      ],
      child: const MusicRoomApp(),
    ),
  );
}
