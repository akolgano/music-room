// lib/screens/music/track_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../models/track.dart';
import '../../core/theme.dart';
import '../../widgets/common_widgets.dart';
import 'track_search_screen.dart';

class TrackSelectionScreen extends StatefulWidget {
  final String? playlistId;

  const TrackSelectionScreen({Key? key, this.playlistId}) : super(key: key);

  @override
  _TrackSelectionScreenState createState() => _TrackSelectionScreenState();
}

class _TrackSelectionScreenState extends State<TrackSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Track Selection'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.library_music, size: 64, color: Colors.white.withOpacity(0.5)),
              const SizedBox(height: 16),
              const Text(
                'Select Tracks',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose tracks to add to your ${widget.playlistId != null ? 'playlist' : 'library'}',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TrackSearchScreen(
                        playlistId: widget.playlistId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('Search Tracks'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(200, 50),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TrackSearchScreen(
                        playlistId: widget.playlistId,
                        searchDeezer: true,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.music_note),
                label: const Text('Browse Deezer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  minimumSize: const Size(200, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
