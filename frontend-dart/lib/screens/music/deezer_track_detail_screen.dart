// lib/screens/music/deezer_track_detail_screen.dart
import 'package:flutter/material.dart';
import 'track_detail_screen.dart';

class DeezerTrackDetailScreen extends StatelessWidget {
  final String trackId;
  
  const DeezerTrackDetailScreen({Key? key, required this.trackId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TrackDetailScreen(trackId: trackId);
  }
}
