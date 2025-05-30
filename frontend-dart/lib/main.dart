// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'core/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/app_provider.dart';
import 'providers/music_provider.dart';
import 'providers/friend_provider.dart';
import 'services/music_player_service.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/music/playlist_editor_screen.dart';
import 'screens/music/track_search_screen.dart';
import 'screens/music/track_selection_screen.dart';
import 'screens/music/deezer_track_detail_screen.dart';
import 'screens/music/music_features_screen.dart';
import 'screens/music/track_vote_screen.dart';
import 'screens/music/control_delegation_screen.dart';
import 'screens/music/player_screen.dart';
import 'screens/music/playlist_sharing_screen.dart';
import 'screens/playlists/public_playlists_screen.dart';
import 'screens/friends/friends_screen.dart';
import 'screens/friends/add_friend_screen.dart';
import 'screens/friends/friend_request_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: Could not load .env file: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => MusicPlayerService()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.darkTheme,
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return authProvider.isLoggedIn ? const HomeScreen() : const AuthScreen();
          },
        ),
        routes: {
          AppRoutes.home: (context) => const HomeScreen(),
          AppRoutes.auth: (context) => const AuthScreen(),
          AppRoutes.profile: (context) => const ProfileScreen(),
          AppRoutes.trackVote: (context) => const MusicTrackVoteScreen(),
          AppRoutes.controlDelegation: (context) => const MusicControlDelegationScreen(),
          AppRoutes.musicFeatures: (context) => const MusicFeaturesScreen(),
          AppRoutes.playlistEditor: (context) {
            final playlistId = ModalRoute.of(context)?.settings.arguments as String?;
            return PlaylistEditorScreen(playlistId: playlistId);
          },
          AppRoutes.trackSelection: (context) => const TrackSelectionScreen(),
          AppRoutes.trackSearch: (context) {
            final playlistId = ModalRoute.of(context)?.settings.arguments as String?;
            return TrackSearchScreen(playlistId: playlistId);
          },
          AppRoutes.publicPlaylists: (context) => const PublicPlaylistsScreen(),
          AppRoutes.playlistSharing: (context) {
            final playlist = ModalRoute.of(context)?.settings.arguments;
            if (playlist != null) {
              return PlaylistSharingScreen(playlist: playlist as dynamic);
            }
            return const Scaffold(
              body: Center(child: Text('Invalid playlist data')),
            );
          },
          AppRoutes.deezerTrackDetail: (context) {
            final trackId = ModalRoute.of(context)?.settings.arguments as String?;
            if (trackId != null) {
              return DeezerTrackDetailScreen(trackId: trackId);
            }
            return const Scaffold(
              body: Center(child: Text('Invalid track ID')),
            );
          },
          AppRoutes.player: (context) => const PlayerScreen(),
          AppRoutes.friends: (context) => const FriendsScreen(),
          AppRoutes.addFriend: (context) => const AddFriendScreen(),
          AppRoutes.friendRequests: (context) => const FriendRequestScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
