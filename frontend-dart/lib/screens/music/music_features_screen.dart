// screens/music/music_features_screen.dart
import 'package:flutter/material.dart';
import '../music/track_search_screen.dart';

class MusicFeaturesScreen extends StatelessWidget {
  const MusicFeaturesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Features'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildSectionTitle('Playlist Management'),
            _buildFeatureCard(
              context,
              icon: Icons.playlist_add,
              title: 'Create New Playlist',
              description: 'Create a new playlist with enhanced options',
              route: '/enhanced_playlist_editor',
            ),
            _buildFeatureCard(
              context,
              icon: Icons.public,
              title: 'Public Playlists',
              description: 'Discover and explore playlists created by other users',
              route: '/public_playlists',
            ),
            _buildFeatureCard(
              context,
              icon: Icons.search,
              title: 'Track Selection',
              description: 'Search and select tracks to add to playlists',
              route: '/track_selection',
            ),
            
            _buildSectionTitle('Collaboration Features'),
            _buildFeatureCard(
              context,
              icon: Icons.how_to_vote,
              title: 'Track Voting',
              description: 'Vote on tracks for collaborative playlist creation',
              route: '/track_vote',
            ),
            _buildFeatureCard(
              context,
              icon: Icons.admin_panel_settings,
              title: 'Control Delegation',
              description: 'Delegate playlist control to other users',
              route: '/control_delegation',
            ),
            
            _buildSectionTitle('Deezer Integration'),
            _buildFeatureCard(
              context,
              icon: Icons.music_note,
              title: 'Search Deezer Tracks',
              description: 'Find and add tracks from Deezer',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => TrackSearchScreen(searchDeezer: true),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }
  
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    String? route,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap ?? (route != null ? () => Navigator.of(context).pushNamed(route) : null),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.indigo.withOpacity(0.1),
                child: Icon(
                  icon,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
