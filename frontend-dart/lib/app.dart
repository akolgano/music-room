// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_core.dart';
import 'providers/auth_provider.dart';
import 'services/music_player_service.dart';
import 'widgets/app_widgets.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/music/track_search_screen.dart';
import 'screens/music/playlist_editor_screen.dart';
import 'screens/playlists/public_playlists_screen.dart';
import 'screens/friends/friends_list_screen.dart';
import 'screens/friends/add_friend_screen.dart';
import 'screens/friends/friend_request_screen.dart';

class MusicRoomApp extends StatelessWidget {
  const MusicRoomApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: _AppScaffold(child: child!),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) => 
          auth.isLoggedIn ? const HomeScreen() : const AuthScreen(),
      ),
      routes: {
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.auth: (context) => const AuthScreen(),
        AppRoutes.profile: (context) => const ProfileScreen(),
        AppRoutes.playlistEditor: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return PlaylistEditorScreen(playlistId: args is String ? args : null);
        },
        AppRoutes.trackSearch: (context) => const TrackSearchScreen(),
        AppRoutes.publicPlaylists: (context) => const PublicPlaylistsScreen(),
        AppRoutes.friends: (context) => const FriendsListScreen(),
        AppRoutes.addFriend: (context) => const AddFriendScreen(),
        AppRoutes.friendRequests: (context) => const FriendRequestScreen(),
      },
    );
  }
}

class _AppScaffold extends StatelessWidget {
  final Widget child;
  const _AppScaffold({required this.child});

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
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MusicPlayerWidget(showTrackInfo: true),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
