// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_core.dart';
import 'providers/auth_provider.dart';
import 'services/music_player_service.dart';
import 'widgets/common_widgets.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/music/track_search_screen.dart';
import 'screens/music/playlist_editor_screen.dart';
import 'screens/playlists/playlists_screen.dart';
import 'screens/friends/friends_list_screen.dart';
import 'screens/friends/add_friend_screen.dart';
import 'screens/friends/friend_request_screen.dart';
import 'screens/devices/device_management_screen.dart';
import 'screens/music/playlist_sharing_screen.dart';
import 'screens/music/music_features_screen.dart';
import 'screens/music/track_vote_screen.dart';
import 'screens/music/control_delegation_screen.dart';
import 'screens/music/player_screen.dart';
import 'screens/music/track_selection_screen.dart';
import 'screens/music/deezer_track_detail_screen.dart';
import 'screens/profile/user_password_change_screen.dart';
import 'screens/profile/social_network_link_screen.dart';
import 'models/models.dart';

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
      routes: _buildRoutes(),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      AppRoutes.home: (context) => const HomeScreen(),
      AppRoutes.auth: (context) => const AuthScreen(),
      AppRoutes.profile: (context) => const ProfileScreen(),
      AppRoutes.playlistEditor: (context) => _buildPlaylistEditor(context),
      AppRoutes.trackSearch: (context) => const TrackSearchScreen(),
      AppRoutes.publicPlaylists: (context) => const PublicPlaylistsScreen(),
      AppRoutes.friends: (context) => const FriendsListScreen(),
      AppRoutes.addFriend: (context) => const AddFriendScreen(),
      AppRoutes.friendRequests: (context) => const FriendRequestScreen(),
      AppRoutes.deviceManagement: (context) => const DeviceManagementScreen(),
      AppRoutes.playlistSharing: (context) => _buildPlaylistSharing(context),
      AppRoutes.musicFeatures: (context) => const MusicFeaturesScreen(),
      AppRoutes.trackVote: (context) => const MusicTrackVoteScreen(),
      AppRoutes.controlDelegation: (context) => const MusicControlDelegationScreen(),
      AppRoutes.player: (context) => const PlayerScreen(),
      AppRoutes.trackSelection: (context) => _buildTrackSelection(context),
      AppRoutes.deezerTrackDetail: (context) => _buildDeezerTrackDetail(context),
      AppRoutes.userPasswordChange: (context) => const UserPasswordChangeScreen(),
      AppRoutes.socialNetworkLink: (context) => const SocialNetworkLinkScreen(),
    };
  }

  Widget _buildPlaylistEditor(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return PlaylistEditorScreen(playlistId: args is String ? args : null);
  }

  Widget _buildPlaylistSharing(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Playlist) {
      return PlaylistSharingScreen(playlist: args);
    }
    return const Scaffold(
      body: Center(child: Text('Invalid playlist data')),
    );
  }

  Widget _buildTrackSelection(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return TrackSelectionScreen(playlistId: args is String ? args : null);
  }

  Widget _buildDeezerTrackDetail(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      return DeezerTrackDetailScreen(trackId: args);
    }
    return const Scaffold(
      body: Center(child: Text('Invalid track ID')),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    if (settings.name?.startsWith('/deezer_track/') == true) {
      final trackId = settings.name!.split('/').last;
      return MaterialPageRoute(
        builder: (context) => DeezerTrackDetailScreen(trackId: trackId),
      );
    }
    
    if (settings.name?.startsWith('/playlist/') == true) {
      final playlistId = settings.name!.split('/').last;
      return MaterialPageRoute(
        builder: (context) => PlaylistEditorScreen(playlistId: playlistId),
      );
    }
    
    return MaterialPageRoute(
      builder: (context) => const Scaffold(
        body: Center(child: Text('Page not found')),
      ),
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
              child: const MiniPlayerWidget(),
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
            Consumer<MusicPlayerService>(
              builder: (context, playerService, _) {
                final track = playerService.currentTrack;
                if (track == null) return const SizedBox.shrink();

                return Container(
                  height: 100,
                  decoration: BoxDecoration(color: AppTheme.surface, boxShadow: AppTheme.lightShadow),
                  child: Row(
                    children: [
                      Container(
                        width: 100, height: 100,
                        color: AppTheme.surfaceVariant,
                        child: track.imageUrl?.isNotEmpty == true
                            ? Image.network(track.imageUrl!, fit: BoxFit.cover, 
                                errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white))
                            : const Icon(Icons.music_note, color: Colors.white),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(track.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(track.artist, style: const TextStyle(color: Colors.grey, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: playerService.togglePlay,
                        icon: Icon(playerService.isPlaying ? Icons.pause : Icons.play_arrow, color: AppTheme.primary, size: 32),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
