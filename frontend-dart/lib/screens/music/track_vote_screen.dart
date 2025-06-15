// lib/screens/music/track_vote_screen.dart
import 'package:flutter/material.dart';
import '../../core/consolidated_core.dart';

class MusicTrackVoteScreen extends StatelessWidget {
  const MusicTrackVoteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Track Voting'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_vote, size: 64, color: AppTheme.primary),
            SizedBox(height: 16),
            Text('Track Voting', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 8),
            Text('Coming Soon', style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
