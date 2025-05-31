// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'models/playlist.dart';
import 'providers/auth_provider.dart';
import 'services/music_player_service.dart';
import 'widgets/music_player_widget.dart';
import 'screens/screens.dart';
import 'core/constants.dart';


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
        AppRoutes.trackVote: (context) => const MusicTrackVoteScreen(),
        AppRoutes.controlDelegation: (context) => const MusicControlDelegationScreen(),
        AppRoutes.musicFeatures: (context) => const MusicFeaturesScreen(),
        AppRoutes.apiDocs: (context) => const ApiDocsScreen(),
        AppRoutes.playlistEditor: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return PlaylistEditorScreen(playlistId: args is String ? args : null);
        },
        AppRoutes.trackSelection: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return TrackSelectionScreen(playlistId: args is String ? args : null);
        },
        AppRoutes.trackSearch: (context) => const TrackSearchScreen(),
        AppRoutes.publicPlaylists: (context) => const PublicPlaylistsScreen(),
        AppRoutes.playlistSharing: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return args is Playlist 
            ? PlaylistSharingScreen(playlist: args)
            : const HomeScreen();
        },
        AppRoutes.deezerTrackDetail: (context) {
          final trackId = ModalRoute.of(context)!.settings.arguments as String;
          return DeezerTrackDetailScreen(trackId: trackId);
        },
        AppRoutes.player: (context) => const PlayerScreen(),
        AppRoutes.friends: (context) => const FriendsListScreen(),
        AppRoutes.addFriend: (context) => const AddFriendScreen(),
        AppRoutes.friendRequests: (context) => const FriendRequestScreen(),
        '/playlists': (context) => const PlaylistsScreen(publicOnly: false),
        '/public_playlists': (context) => const PlaylistsScreen(publicOnly: true),
        '/track_search': (context) => const TrackSearchScreen(),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 5,
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
