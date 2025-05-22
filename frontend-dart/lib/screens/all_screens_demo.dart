// lib/screens/all_screens_demo.dart
import 'package:flutter/material.dart';
import '../core/constants.dart';

class AllScreensDemo extends StatelessWidget {
  const AllScreensDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Screens Demo'),
        backgroundColor: AppConstants.background,
      ),
      backgroundColor: AppConstants.background,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Music Room - All Screens',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This demo screen provides access to all screens in the Music Room app for development and testing purposes.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildSection(
            context,
            'Authentication',
            [
              _ScreenItem('Login/Signup', '/auth', Icons.login),
            ],
          ),
          
          _buildSection(
            context,
            'Main Navigation',
            [
              _ScreenItem('Home Screen', '/home', Icons.home),
              _ScreenItem('Profile', '/profile', Icons.person),
            ],
          ),
          
          _buildSection(
            context,
            'Playlist Management',
            [
              _ScreenItem('Enhanced Playlist Editor', '/enhanced_playlist_editor', Icons.playlist_add),
              _ScreenItem('Public Playlists', '/public_playlists', Icons.public),
              _ScreenItem('Track Selection', '/track_selection', Icons.track_changes),
            ],
          ),
          
          _buildSection(
            context,
            'Music Features',
            [
              _ScreenItem('Track Search', '/track_search', Icons.search),
              _ScreenItem('Music Features', '/music_features', Icons.featured_play_list),
              _ScreenItem('Player Screen', '/player', Icons.play_circle),
            ],
          ),
          
          _buildSection(
            context,
            'Social Features',
            [
              _ScreenItem('Track Voting', '/track_vote', Icons.how_to_vote),
              _ScreenItem('Control Delegation', '/control_delegation', Icons.admin_panel_settings),
            ],
          ),
          
          _buildSection(
            context,
            'Documentation',
            [
              _ScreenItem('API Documentation', '/api_docs', Icons.api),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<_ScreenItem> screens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.primary,
            ),
          ),
        ),
        ...screens.map((screen) => _buildScreenCard(context, screen)),
      ],
    );
  }

  Widget _buildScreenCard(BuildContext context, _ScreenItem screen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppConstants.surface,
      child: ListTile(
        leading: Icon(
          screen.icon,
          color: AppConstants.primary,
        ),
        title: Text(
          screen.title,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
          size: 16,
        ),
        onTap: () {
          try {
            Navigator.of(context).pushNamed(screen.route);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error navigating to ${screen.title}: $e'),
                backgroundColor: AppConstants.error,
              ),
            );
          }
        },
      ),
    );
  }
}

class _ScreenItem {
  final String title;
  final String route;
  final IconData icon;

  const _ScreenItem(this.title, this.route, this.icon);
}
