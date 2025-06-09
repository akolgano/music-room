// lib/screens/music/player_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_core.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Music Player'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 64, color: AppTheme.primary),
            SizedBox(height: 16),
            Text('Music Player', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 8),
            Text('Coming Soon', style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
