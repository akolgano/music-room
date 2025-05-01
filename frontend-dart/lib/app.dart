// app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/playlist.dart';
import 'providers/auth_provider.dart';
import 'services/music_player_service.dart';
import 'widgets/music_player_widget.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';

import 'screens/music/track_vote_screen.dart';
import 'screens/music/control_delegation_screen.dart';
import 'screens/music/playlist_editor_screen.dart';
import 'screens/music/deezer_track_detail_screen.dart';
import 'screens/music/enhanced_playlist_editor_screen.dart';
import 'screens/music/track_selection_screen.dart';
import 'screens/music/playlist_sharing_screen.dart';
import 'screens/music/public_playlists_screen.dart';
import 'screens/music/music_features_screen.dart';
import 'screens/music/track_search_screen.dart';
import 'screens/music/player_screen.dart';
import 'screens/all_screens_demo.dart';

class MusicRoomApp extends StatelessWidget {
  const MusicRoomApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Room',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: _CustomScaffold(child: child!),
        );
      },
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return auth.isLoggedIn ? const HomeScreen() : const AuthScreen();
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/track_vote': (context) => const MusicTrackVoteScreen(),
        '/control_delegation': (context) => const MusicControlDelegationScreen(),
        '/music_features': (context) => const MusicFeaturesScreen(),
        
        '/playlist_editor': (context) => const MusicPlaylistEditorScreen(),
        
        '/enhanced_playlist_editor': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args != null && args is String) {
            return EnhancedPlaylistEditorScreen(playlistId: args);
          }
          return const EnhancedPlaylistEditorScreen();
        },
        
        '/track_selection': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args != null && args is String) {
            return TrackSelectionScreen(playlistId: args);
          }
          return const TrackSelectionScreen();
        },
        
        '/track_search': (context) => const TrackSearchScreen(),
        
        '/public_playlists': (context) => const PublicPlaylistsScreen(),
        '/playlist_sharing': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args != null && args is Playlist) {
            return PlaylistSharingScreen(playlist: args);
          }
          return const HomeScreen();
        }, 
        
        '/deezer_track_detail': (context) => DeezerTrackDetailScreen(
          trackId: ModalRoute.of(context)!.settings.arguments as String,
        ),
        '/player': (context) => const PlayerScreen(),
        '/all_screens_demo': (context) => const AllScreensDemo(),
      },
    );
  }
}

class _CustomScaffold extends StatelessWidget {
  final Widget child;

  const _CustomScaffold({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<MusicPlayerService>(context);
    final hasCurrentTrack = playerService.currentTrack != null;
    final bottomPadding = hasCurrentTrack ? 56.0 : 0.0;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: child,
          ),
          if (hasCurrentTrack)
            GestureDetector(
              onTap: () {
                _showPlayerBottomSheet(context);
              },
              child: const MusicPlayerWidget(mini: true),
            ),
        ],
      ),
    );
  }

  void _showPlayerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            const MusicPlayerWidget(showTrackInfo: true),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/player');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Full Screen Player'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
