// lib/screens/music/deezer_track_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../services/music_player_service.dart';
import '../../models/track.dart';
import '../../widgets/music_player_widget.dart';
import '../../core/theme.dart';
import 'track_search_screen.dart';

class DeezerTrackDetailScreen extends StatefulWidget {
  final String trackId;
  
  const DeezerTrackDetailScreen({Key? key, required this.trackId}) : super(key: key);

  @override
  _DeezerTrackDetailScreenState createState() => _DeezerTrackDetailScreenState();
}

class _DeezerTrackDetailScreenState extends State<DeezerTrackDetailScreen> {
  bool _isLoading = true;
  Track? _track;
  String? _previewUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTrackDetails();
  }

  Future<void> _loadTrackDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      _track = await musicProvider.getDeezerTrack(widget.trackId);
      
      if (_track != null && _track!.deezerTrackId != null) {
        _previewUrl = await musicProvider.getDeezerTrackPreviewUrl(_track!.deezerTrackId!);
      }
      
    } catch (error) {
      _errorMessage = error.toString();
    }

    setState(() {
      _isLoading = false;
    });
  }
  
  void _playTrack() {
    if (_track != null && _previewUrl != null) {
      final playerService = Provider.of<MusicPlayerService>(context, listen: false);
      playerService.playTrack(_track!, _previewUrl!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No preview available for this track'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final playerService = Provider.of<MusicPlayerService>(context);
    final bool isCurrentTrack = _track != null && playerService.currentTrack?.id == _track!.id;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Track Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading track details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(_errorMessage!, style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadTrackDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _track == null
                  ? const Center(child: Text('Track not found', style: TextStyle(color: Colors.white)))
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Column(
                                    children: [
                                      _track!.imageUrl != null && _track!.imageUrl!.isNotEmpty
                                          ? Container(
                                              width: 200,
                                              height: 200,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.3),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                                image: DecorationImage(
                                                  image: NetworkImage(_track!.imageUrl!),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            )
                                          : const Icon(Icons.music_note, size: 80, color: AppTheme.primary),
                                      const SizedBox(height: 16),
                                      Text(
                                        _track!.name,
                                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _track!.artist,
                                        style: const TextStyle(fontSize: 18, color: AppTheme.onSurfaceVariant),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Album: ${_track!.album}',
                                        style: const TextStyle(fontSize: 16, color: AppTheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                const Divider(color: AppTheme.surfaceVariant),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: isCurrentTrack 
                                    ? playerService.togglePlay
                                    : _playTrack,
                                  icon: Icon(
                                    isCurrentTrack && playerService.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow
                                  ),
                                  label: Text(
                                    isCurrentTrack && playerService.isPlaying
                                      ? 'Pause Preview'
                                      : 'Play Preview'
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 50),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      await musicProvider.addTrackFromDeezer(
                                        _track!.deezerTrackId!,
                                        authProvider.token!,
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Track added to your library'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } catch (error) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to add track: $error'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add to My Library'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 50),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TrackSearchScreen(
                                          initialTrack: _track,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.playlist_add),
                                  label: const Text('Add to Playlist'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 50),
                                    backgroundColor: AppTheme.primary,
                                  ),
                                ),
                                if (_track?.url != null && _track!.url.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Opening Deezer link requires adding the url_launcher package',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('Open in Deezer'),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 50),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (isCurrentTrack)
                          const MusicPlayerWidget(),
                      ],
                    ),
    );
  }
}
