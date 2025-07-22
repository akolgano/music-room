import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../core/theme_utils.dart';
import '../core/social_login.dart';
import '../core/constants.dart';
import '../core/service_locator.dart';
import '../providers/auth_provider.dart';
import '../providers/music_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/dynamic_theme_provider.dart';
import '../providers/voting_provider.dart';
import '../services/music_player_service.dart';
import '../models/music_models.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/auth/signup_with_otp_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/music/track_detail_screen.dart';
import '../screens/music/track_search_screen.dart';
import '../screens/playlists/playlist_detail_screen.dart';
import '../screens/playlists/playlist_editor_screen.dart';
import '../screens/playlists/playlist_sharing_screen.dart';
import '../screens/playlists/playlists_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/social_network_link_screen.dart';
import '../screens/profile/user_password_change_screen.dart';
import '../screens/profile/user_page_screen.dart';
import '../screens/friends/add_friend_screen.dart';
import '../screens/friends/friend_request_screen.dart';
import '../screens/friends/friends_list_screen.dart';
import '../screens/deezer/deezer_auth_screen.dart';

class AppBuilder {
  static List<SingleChildWidget> buildProviders() {
    return [
      ChangeNotifierProvider<DynamicThemeProvider>(create: (_) => getIt<DynamicThemeProvider>()),
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ChangeNotifierProvider<MusicProvider>(create: (_) => MusicProvider()),
      ChangeNotifierProvider<FriendProvider>(create: (_) => FriendProvider()),
      ChangeNotifierProvider<ProfileProvider>(create: (_) => ProfileProvider()),
      ChangeNotifierProvider<VotingProvider>(create: (_) => VotingProvider()),
    ];
  }

  static List<SingleChildWidget> buildAdditionalProviders() {
    return [
      ChangeNotifierProxyProvider<DynamicThemeProvider, MusicPlayerService>(
        create: (context) {
          return getIt<MusicPlayerService>();
        },
        update: (context, themeProvider, previous) => previous ?? getIt<MusicPlayerService>(),
      ),
    ];
  }

  static Widget _buildAuthenticatedRoute(Widget Function() builder) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isLoggedIn || !authProvider.hasValidToken) return const AuthScreen();
        return builder();
      },
    );
  }

  static final Set<String> _protectedRoutes = {
    AppRoutes.home, AppRoutes.profile,
    AppRoutes.playlistEditor,
    AppRoutes.playlistDetail,
    AppRoutes.trackDetail,
    AppRoutes.trackSearch,
    AppRoutes.publicPlaylists,
    AppRoutes.friends,
    AppRoutes.addFriend,
    AppRoutes.friendRequests,
    AppRoutes.playlistSharing,
    AppRoutes.player,
    AppRoutes.userPasswordChange, AppRoutes.socialNetworkLink, AppRoutes.deezerAuth, AppRoutes.userPage,
  };

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    if (kDebugMode) {
      developer.log('Generating route for: ${settings.name} with arguments: ${settings.arguments}', name: 'AppBuilder');
    }

    if (settings.name == '/' || settings.name == null || settings.name!.isEmpty) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => _buildAuthenticatedRoute(() => const HomeScreen()),
      );
    }

    if (settings.name == AppRoutes.auth) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => const AuthScreen(),
      );
    }

    if (settings.name == '/signup_otp') {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => const SignupWithOtpScreen(),
      );
    }

    if (_protectedRoutes.contains(settings.name)) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => _buildAuthenticatedRoute(() => _buildProtectedRoute(settings)),
      );
    }

    if (settings.name?.startsWith('/playlist/') == true) {
      final playlistId = settings.name!.split('/').last;
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => _buildAuthenticatedRoute(() => PlaylistDetailScreen(playlistId: playlistId)),
      );
    }

    if (settings.name?.startsWith('/track/') == true || settings.name?.startsWith('/deezer_track/') == true) {
      final trackId = settings.name!.split('/').last;
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => _buildAuthenticatedRoute(() => TrackDetailScreen(trackId: trackId)),
      );
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (context) => _buildErrorScreen('Page not found'),
    );
  }

  static Widget _buildProtectedRoute(RouteSettings settings) {
    if (kDebugMode) {
      developer.log('Building protected route: ${settings.name} with arguments: ${settings.arguments}', name: 'AppBuilder');
    }
    
    switch (settings.name) {
      case AppRoutes.home:
        return const HomeScreen();
      case AppRoutes.profile:
        return const ProfileScreen();
      case AppRoutes.trackSearch:
        return const TrackSearchScreen();
      case AppRoutes.publicPlaylists:
        return const PublicPlaylistsScreen();
      case AppRoutes.friends:
        return const FriendsListScreen();
      case AppRoutes.addFriend:
        return const AddFriendScreen();
      case AppRoutes.friendRequests:
        return const FriendRequestScreen();
      case AppRoutes.userPasswordChange:
        return const UserPasswordChangeScreen();
      case AppRoutes.socialNetworkLink:
        return const SocialNetworkLinkScreen();
      case AppRoutes.deezerAuth:
        return const DeezerAuthScreen();
      case AppRoutes.userPage:
        return _buildUserPage(settings);
      case '/profile_info':
        return const ProfileScreen();
      case AppRoutes.playlistEditor:
        return _buildPlaylistEditor(settings);
      case AppRoutes.playlistDetail:
        return _buildPlaylistDetail(settings);
      case AppRoutes.trackDetail:
        return _buildTrackDetail(settings);
      case AppRoutes.playlistSharing:
        return _buildPlaylistSharing(settings);
      default:
        return _buildErrorScreen('Page not found');
    }
  }

  static Widget _buildPlaylistEditor(RouteSettings settings) {
    final args = settings.arguments;
    return PlaylistEditorScreen(playlistId: args is String ? args : null);
  }

  static Widget _buildPlaylistDetail(RouteSettings settings) {
    final args = settings.arguments;
    if (kDebugMode) {
      developer.log('Playlist detail args: $args, type: ${args.runtimeType}', name: 'AppBuilder');
    }
    
    if (args == null) {
      if (kDebugMode) {
        developer.log('No arguments provided for playlist detail', name: 'AppBuilder');
      }
      return _buildErrorScreen('No playlist ID provided');
    }

    String? playlistId;
    if (args is String) {
      playlistId = args;
    } else if (args is Map<String, dynamic> && args.containsKey('id')) {
      playlistId = args['id'].toString();
    } else {
      if (kDebugMode) {
        developer.log('Invalid arguments type for playlist detail: ${args.runtimeType}', name: 'AppBuilder');
      }
      return _buildErrorScreen('Invalid playlist ID format');
    }

    if (playlistId.isEmpty || playlistId == 'null') {
      if (kDebugMode) {
        developer.log('Invalid playlist ID: $playlistId', name: 'AppBuilder');
      }
      return _buildErrorScreen('Invalid playlist ID');
    }

    if (kDebugMode) {
      developer.log('Building PlaylistDetailScreen with ID: $playlistId', name: 'AppBuilder');
    }
    return PlaylistDetailScreen(playlistId: playlistId);
  }

  static Widget _buildTrackDetail(RouteSettings settings) {
    final args = settings.arguments;
    
    if (args is Map<String, dynamic>) {
      return TrackDetailScreen(
        trackId: args['trackId'] as String?,
        track: args['track'] as Track?,
        playlistId: args['playlistId'] as String?,
      );
    } else if (args is String) {
      return TrackDetailScreen(trackId: args);
    } else if (args is Track) {
      return TrackDetailScreen(track: args);
    }
    return _buildErrorScreen('Invalid track data');
  }

  static Widget _buildPlaylistSharing(RouteSettings settings) {
    final args = settings.arguments;
    if (args is Playlist) return PlaylistSharingScreen(playlist: args);
    return _buildErrorScreen('Invalid playlist data');
  }

  static Widget _buildUserPage(RouteSettings settings) {
    final args = settings.arguments;
    
    if (args is Map<String, dynamic>) {
      final userId = args['userId'];
      final username = args['username'] as String?;
      
      if (userId is int) {
        return UserPageScreen(userId: userId, username: username);
      } else if (userId is String) {
        final parsedUserId = int.tryParse(userId);
        if (parsedUserId != null) {
          return UserPageScreen(userId: parsedUserId, username: username);
        }
      }
    } else if (args is int) {
      return UserPageScreen(userId: args);
    }
    
    return _buildErrorScreen('Invalid user data provided');
  }

  static Widget _buildErrorScreen(String message) {
    return Builder(
      builder: (context) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(backgroundColor: AppTheme.background, title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(color: Colors.white, fontSize: 18), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
