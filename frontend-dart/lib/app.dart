// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'core/constants.dart';
import 'models/playlist.dart';
import 'providers/auth_provider.dart';
import 'services/music_player_service.dart';
import 'widgets/music_player_widget.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/music/enhanced_playlist_editor_screen.dart';
import 'screens/music/track_selection_screen.dart';
import 'screens/music/track_search_screen.dart';
import 'screens/music/public_playlists_screen.dart';
import 'screens/music/playlist_sharing_screen.dart';
import 'screens/music/deezer_track_detail_screen.dart';
import 'screens/music/player_screen.dart';
import 'screens/music/track_vote_screen.dart';
import 'screens/music/control_delegation_screen.dart';
import 'screens/music/music_features_screen.dart';
import 'screens/docs/api_docs_screen.dart';
import 'screens/all_screens_demo.dart';
import 'screens/friends/friends_list_screen.dart';
import 'screens/friends/add_friend_screen.dart';
import 'screens/friends/friend_request_screen.dart';

class MusicRoomApp extends StatelessWidget {
  const MusicRoomApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: _CustomScaffold(child: child!),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) => 
          auth.isLoggedIn ? const HomeScreen() : const AuthScreen(),
      ),
      routes: _buildRoutes(),
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() => {
    AppRoutes.home: (context) => const HomeScreen(),
    AppRoutes.profile: (context) => const ProfileScreen(),
    AppRoutes.trackVote: (context) => const MusicTrackVoteScreen(),
    AppRoutes.controlDelegation: (context) => const MusicControlDelegationScreen(),
    AppRoutes.musicFeatures: (context) => const MusicFeaturesScreen(),
    AppRoutes.apiDocs: (context) => const ApiDocsScreen(),
    AppRoutes.enhancedPlaylistEditor: (context) {
      final args = ModalRoute.of(context)!.settings.arguments;
      return EnhancedPlaylistEditorScreen(
        playlistId: args is String ? args : null
      );
    },
    AppRoutes.trackSelection: (context) {
      final args = ModalRoute.of(context)!.settings.arguments;
      return TrackSelectionScreen(playlistId: args is String ? args : null);
    },
    AppRoutes.trackSearch: (context) => const TrackSearchScreen(),
    AppRoutes.publicPlaylists: (context) => const PublicPlaylistsScreen(),
    AppRoutes.playlistSharing: (context) {
      final args = ModalRoute.of(context)!.settings.arguments;
      return args is Playlist 
        ? PlaylistSharingScreen(playlist: args)
        : const HomeScreen();
    },
    AppRoutes.deezerTrackDetail: (context) => DeezerTrackDetailScreen(
      trackId: ModalRoute.of(context)!.settings.arguments as String,
    ),
    AppRoutes.player: (context) => const PlayerScreen(),
    // Friend-related routes
    AppRoutes.friends: (context) => const FriendsListScreen(),
    AppRoutes.addFriend: (context) => const AddFriendScreen(),
    AppRoutes.friendRequests: (context) => const FriendRequestScreen(),
  };
}

class _CustomScaffold extends StatelessWidget {
  final Widget child;
  const _CustomScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<MusicPlayerService>(context);
    final hasCurrentTrack = playerService.currentTrack != null;

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          if (hasCurrentTrack)
            GestureDetector(
              onTap: () => _showPlayerBottomSheet(context),
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
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            const MusicPlayerWidget(showTrackInfo: true),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(AppRoutes.player);
              },
              child: const Text('FULL SCREEN PLAYER'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
