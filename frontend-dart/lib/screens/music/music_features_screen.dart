// lib/screens/music/music_features_screen.dart
import 'package:flutter/material.dart';
import '../../core/app_core.dart';
import '../../widgets/unified_components.dart';
import 'track_search_screen.dart';

class MusicFeaturesScreen extends StatelessWidget {
  const MusicFeaturesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Music Features'),
      ),
      body: SingleChildScrollView(
        padding: AppSizes.screenPadding,
        child: Column(
          children: [
            UnifiedComponents.sectionTitle('Playlist Management'),
            UnifiedComponents.featureCard(
              icon: Icons.playlist_add,
              title: 'Create New Playlist',
              description: 'Create a new playlist with enhanced options',
              onTap: () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
            ),
            UnifiedComponents.featureCard(
              icon: Icons.public,
              title: 'Public Playlists',
              description: 'Discover and explore playlists created by other users',
              onTap: () => Navigator.pushNamed(context, AppRoutes.publicPlaylists),
            ),
            UnifiedComponents.featureCard(
              icon: Icons.search,
              title: 'Track Selection',
              description: 'Search and select tracks to add to playlists',
              onTap: () => Navigator.pushNamed(context, AppRoutes.trackSelection),
            ),
            
            UnifiedComponents.sectionTitle('Collaboration Features'),
            UnifiedComponents.featureCard(
              icon: Icons.how_to_vote,
              title: 'Track Voting',
              description: 'Vote on tracks for collaborative playlist creation',
              onTap: () => Navigator.pushNamed(context, AppRoutes.trackVote),
            ),
            UnifiedComponents.featureCard(
              icon: Icons.admin_panel_settings,
              title: 'Control Delegation',
              description: 'Delegate playlist control to other users',
              onTap: () => Navigator.pushNamed(context, AppRoutes.controlDelegation),
            ),
            
            UnifiedComponents.sectionTitle('Deezer Integration'),
            UnifiedComponents.featureCard(
              icon: Icons.music_note,
              title: 'Search Deezer Tracks',
              description: 'Find and add tracks from Deezer',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => const TrackSearchScreen(searchDeezer: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
