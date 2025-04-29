// screens/music/deezer_track_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../models/track.dart';
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
    } catch (error) {
      _errorMessage = error.toString();
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading track details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_errorMessage!),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadTrackDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _track == null
                  ? const Center(child: Text('Track not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.music_note, size: 80, color: Colors.indigo),
                                const SizedBox(height: 16),
                                Text(
                                  _track!.name,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _track!.artist,
                                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Album: ${_track!.album}',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Divider(),
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
                              backgroundColor: Colors.indigo[300],
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
    );
  }
}
