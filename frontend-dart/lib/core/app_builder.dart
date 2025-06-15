// lib/core/app_builder.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../core/consolidated_core.dart';
import '../core/service_locator.dart';
import '../providers/auth_provider.dart';
import '../providers/music_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/device_provider.dart';
import '../providers/dynamic_theme_provider.dart';
import '../providers/playlist_license_provider.dart';
import '../services/music_player_service.dart';
import '../services/websocket_service.dart';
import '../screens/home/home_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/music/track_search_screen.dart';
import '../screens/music/playlist_editor_screen.dart';
import '../screens/playlists/playlists_screen.dart';
import '../screens/friends/friends_list_screen.dart';
import '../screens/friends/add_friend_screen.dart';
import '../screens/friends/friend_request_screen.dart';
import '../screens/devices/device_management_screen.dart';
import '../screens/music/playlist_sharing_screen.dart';
import '../screens/music/music_features_screen.dart';
import '../screens/music/track_vote_screen.dart';
import '../screens/music/control_delegation_screen.dart';
import '../screens/music/player_screen.dart';
import '../screens/music/track_selection_screen.dart';
import '../screens/music/deezer_track_detail_screen.dart';
import '../screens/profile/user_password_change_screen.dart';
import '../screens/profile/social_network_link_screen.dart';
import '../screens/profile/profile_info_screen.dart';
import '../models/models.dart';

class AppBuilder {
  static List<SingleChildWidget> buildProviders() {
    return [
      ChangeNotifierProvider<DynamicThemeProvider>(create: (_) => getIt<DynamicThemeProvider>()),
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ChangeNotifierProvider<MusicProvider>(create: (_) => MusicProvider()),
      ChangeNotifierProvider<FriendProvider>(create: (_) => FriendProvider()),
      ChangeNotifierProvider<ProfileProvider>(create: (_) => ProfileProvider()),
      ChangeNotifierProvider<DeviceProvider>(create: (_) => DeviceProvider()),
      ChangeNotifierProvider<PlaylistLicenseProvider>(create: (_) => PlaylistLicenseProvider()),
    ];
  }

  static List<SingleChildWidget> buildAdditionalProviders() {
    return [
      ChangeNotifierProxyProvider<DynamicThemeProvider, MusicPlayerService>(
        create: (context) => getIt<MusicPlayerService>(),
        update: (context, themeProvider, previous) => previous ?? getIt<MusicPlayerService>(),
      ),
      Provider<WebSocketService>(create: (_) => WebSocketService()),
    ];
  }

  static Map<String, WidgetBuilder> buildRoutes() {
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
      '/profile_info': (context) => const ProfileInfoScreen(),
    };
  }

  static Widget _buildPlaylistEditor(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return PlaylistEditorScreen(playlistId: args is String ? args : null);
  }

  static Widget _buildPlaylistSharing(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Playlist) return PlaylistSharingScreen(playlist: args);
    return _buildErrorScreen('Invalid playlist data');
  }

  static Widget _buildTrackSelection(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return TrackSelectionScreen(playlistId: args is String ? args : null);
  }

  static Widget _buildDeezerTrackDetail(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) return DeezerTrackDetailScreen(trackId: args);
    return _buildErrorScreen('Invalid track ID');
  }

  static Widget _buildErrorScreen(String message) {
    return Builder(
      builder: (context) => Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    if (settings.name?.startsWith('/deezer_track/') == true) {
      final trackId = settings.name!.split('/').last;
      return MaterialPageRoute(builder: (context) => DeezerTrackDetailScreen(trackId: trackId));
    }
    
    if (settings.name?.startsWith('/playlist/') == true) {
      final playlistId = settings.name!.split('/').last;
      return MaterialPageRoute(builder: (context) => PlaylistEditorScreen(playlistId: playlistId));
    }
    
    return MaterialPageRoute(builder: (context) => _buildErrorScreen('Page not found'));
  }
}
