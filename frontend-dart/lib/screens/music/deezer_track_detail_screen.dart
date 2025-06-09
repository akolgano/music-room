// lib/screens/music/deezer_track_detail_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_core.dart';

class DeezerTrackDetailScreen extends StatelessWidget {
  final String trackId;
  
  const DeezerTrackDetailScreen({Key? key, required this.trackId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Track Details'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 64, color: AppTheme.primary),
            const SizedBox(height: 16),
            const Text('Track Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Track ID: $trackId', style: const TextStyle(color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            const Text('Coming Soon', style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
