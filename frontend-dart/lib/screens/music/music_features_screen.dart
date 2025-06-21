// lib/screens/music/music_features_screen.dart
import 'package:flutter/material.dart';
import '../../core/core.dart';
import '../../widgets/app_widgets.dart'; 
import 'track_search_screen.dart';

class MusicFeaturesScreen extends StatelessWidget {
  const MusicFeaturesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(backgroundColor: AppTheme.background, title: const Text('Music Features')),
      body: SingleChildScrollView(
        padding: AppSizes.screenPadding,
        child: Column(
          children: [
            AppWidgets.sectionTitle('Playlist Management'), 
            AppWidgets.featureCard( 
              icon: Icons.playlist_add,
              title: 'Create New Playlist',
              description: 'Create a new playlist with enhanced options',
              onTap: () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
            ),
            AppWidgets.featureCard( 
              icon: Icons.public,
              title: 'Public Playlists',
              description: 'Discover and explore playlists created by other users',
              onTap: () => Navigator.pushNamed(context, AppRoutes.publicPlaylists),
            ),
            AppWidgets.featureCard( 
              icon: Icons.search,
              title: 'Search Deezer Tracks',
              description: 'Search and add tracks from Deezer to your playlists',
              onTap: () => Navigator.pushNamed(context, AppRoutes.trackSearch),
            ),
            AppWidgets.sectionTitle('Collaboration Features'), 
            AppWidgets.featureCard( 
              icon: Icons.admin_panel_settings,
              title: 'Control Delegation',
              description: 'Delegate playlist control to other users',
              onTap: () => Navigator.pushNamed(context, AppRoutes.controlDelegation),
            ),
            AppWidgets.sectionTitle('Deezer Integration'), 
            AppWidgets.featureCard( 
              icon: Icons.music_note,
              title: 'Browse Deezer Catalog',
              description: 'Explore millions of tracks from Deezer\'s music catalog',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const TrackSearchScreen())),
            ),
            AppWidgets.featureCard( 
              icon: Icons.library_add,
              title: 'Add to Library',
              description: 'Add your favorite Deezer tracks to your personal library',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const TrackSearchScreen())),
            ),
          ],
        ),
      ),
    );
  }
}
