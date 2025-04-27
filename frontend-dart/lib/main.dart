import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_room/providers/auth_provider.dart';
import 'package:music_room/providers/music_service_provider.dart';
import 'package:music_room/screens/splash_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MusicServiceProvider()),
      ],
      child: const MusicRoomApp(),
    ),
  );
}

class MusicRoomApp extends StatelessWidget {
  const MusicRoomApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Room',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
