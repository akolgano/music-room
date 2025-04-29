// app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/playlist.dart';
import 'providers/auth_provider.dart';
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
          child: child!,
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
        '/all_screens_demo': (context) => const AllScreensDemo(),
      },
    );
  }
}
