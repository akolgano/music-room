// lib/screens/music/track_selection_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_core.dart';

class TrackSelectionScreen extends StatelessWidget {
  final String? playlistId;
  
  const TrackSelectionScreen({Key? key, this.playlistId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Track Selection'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_music, size: 64, color: AppTheme.primary),
            const SizedBox(height: 16),
            const Text('Select Tracks', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Choose tracks for ${playlistId != null ? 'playlist' : 'library'}', 
                 style: const TextStyle(color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.trackSearch, arguments: playlistId),
              icon: const Icon(Icons.search),
              label: const Text('Search Tracks'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
