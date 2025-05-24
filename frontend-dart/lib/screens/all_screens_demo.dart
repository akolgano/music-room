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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Navigate to Different Screens',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildScreenButton(
            context,
            'Home',
            Icons.home,
            AppRoutes.home,
          ),
          _buildScreenButton(
            context,
            'Profile',
            Icons.person,
            AppRoutes.profile,
          ),
          _buildScreenButton(
            context,
            'Playlist Editor',
            Icons.playlist_add,
            AppRoutes.playlistEditor,
          ),
          _buildScreenButton(
            context,
            'Track Search',
            Icons.search,
            AppRoutes.trackSearch,
          ),
          _buildScreenButton(
            context,
            'Public Playlists',
            Icons.public,
            AppRoutes.publicPlaylists,
          ),
          _buildScreenButton(
            context,
            'Track Voting',
            Icons.how_to_vote,
            AppRoutes.trackVote,
          ),
          _buildScreenButton(
            context,
            'Control Delegation',
            Icons.admin_panel_settings,
            AppRoutes.controlDelegation,
          ),
          _buildScreenButton(
            context,
            'Music Features',
            Icons.featured_play_list,
            AppRoutes.musicFeatures,
          ),
          _buildScreenButton(
            context,
            'Player',
            Icons.play_circle,
            AppRoutes.player,
          ),
          _buildScreenButton(
            context,
            'Friends',
            Icons.people,
            AppRoutes.friends,
          ),
          _buildScreenButton(
            context,
            'Add Friend',
            Icons.person_add,
            AppRoutes.addFriend,
          ),
          _buildScreenButton(
            context,
            'Friend Requests',
            Icons.notifications,
            AppRoutes.friendRequests,
          ),
          _buildScreenButton(
            context,
            'API Documentation',
            Icons.api,
            AppRoutes.apiDocs,
          ),
        ],
      ),
    );
  }

  Widget _buildScreenButton(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}
