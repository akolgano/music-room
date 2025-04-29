// screens/all_screens_demo.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/playlist.dart';

class AllScreensDemo extends StatelessWidget {
  const AllScreensDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Screens Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildSectionTitle('Main Navigation'),
            _buildNavigationButton(context, 'Home', '/home'),
            _buildNavigationButton(context, 'Profile', '/profile'),
            
            _buildSectionTitle('Music Features'),
            _buildNavigationButton(context, 'Music Features Overview', '/music_features'),
            
            _buildSectionTitle('Playlist Management'),
            _buildNavigationButton(context, 'Enhanced Playlist Editor', '/enhanced_playlist_editor'),
            _buildNavigationButton(context, 'Simple Playlist Editor', '/playlist_editor'),
            _buildNavigationButton(context, 'Public Playlists', '/public_playlists'),
            _buildNavigationButton(context, 'Track Selection', '/track_selection'),
            _buildNavigationButton(context, 'Track Search', '/track_search'),
            
            _buildSectionTitle('Social Features'),
            _buildNavigationButton(context, 'Track Voting', '/track_vote'),
            _buildNavigationButton(context, 'Control Delegation', '/control_delegation'),
            
            _buildSectionTitle('Sample Data'),
            ElevatedButton(
              onPressed: () {
                final demoPlaylist = Playlist(
                  id: 'demo-1',
                  name: 'Demo Playlist',
                  description: 'This is a demo playlist for sharing',
                  isPublic: true,
                  creator: 'Demo User',
                  tracks: [],
                );
                
                Navigator.of(context).pushNamed(
                  '/playlist_sharing',
                  arguments: demoPlaylist,
                );
              },
              child: const Text('Demo Playlist Sharing'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                final trackId = '3135556';
                Navigator.of(context).pushNamed(
                  '/deezer_track_detail',
                  arguments: trackId,
                );
              },
              child: const Text('Demo Deezer Track Detail'),
            ),
            
            _buildSectionTitle('Authentication'),
            ElevatedButton(
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This screen is for development purposes only.'),
            ),
          );
        },
        child: const Icon(Icons.code),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }
  
  Widget _buildNavigationButton(BuildContext context, String title, String route) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushNamed(route);
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(title),
      ),
    );
  }
}
