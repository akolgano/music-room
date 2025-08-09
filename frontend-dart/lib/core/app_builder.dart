import 'logging_navigation_observer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../core/constants.dart';
import '../core/service_locator.dart';
import '../widgets/app_widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/music_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/dynamic_theme_provider.dart';
import '../providers/voting_provider.dart';
import '../providers/connectivity_provider.dart';
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
import '../screens/admin/admin_dashboard_screen.dart';

class AppBuilder {
  static final LoggingNavigationObserver _navigationObserver = LoggingNavigationObserver();
  
  static LoggingNavigationObserver get navigationObserver => _navigationObserver;
  
  static List<SingleChildWidget> buildProviders() {
    return [
      ChangeNotifierProvider<DynamicThemeProvider>(create: (_) => getIt<DynamicThemeProvider>()),
      ChangeNotifierProvider<ConnectivityProvider>(create: (_) => getIt<ConnectivityProvider>()),
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ChangeNotifierProvider<MusicProvider>(create: (_) => getIt<MusicProvider>()),
      ChangeNotifierProvider<FriendProvider>(create: (_) => FriendProvider()),
      ChangeNotifierProvider<ProfileProvider>(create: (_) => ProfileProvider()),
      ChangeNotifierProvider<VotingProvider>(create: (_) => getIt<VotingProvider>()),
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
    AppRoutes.userPasswordChange, AppRoutes.socialNetworkLink, AppRoutes.userPage,
    AppRoutes.adminDashboard,
  };

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    AppLogger.debug('Generating route for: ${settings.name} with arguments: ${settings.arguments}', 'AppBuilder');

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
      builder: (context) => AppWidgets.buildErrorScreen('Page not found'),
    );
  }

  static Widget _buildProtectedRoute(RouteSettings settings) {
    AppLogger.debug('Building protected route: ${settings.name} with arguments: ${settings.arguments}', 'AppBuilder');
    
    switch (settings.name) {
      case AppRoutes.home:
        return const HomeScreen();
      case AppRoutes.profile:
        return const ProfileScreen();
      case AppRoutes.trackSearch:
        return const TrackSearchScreen();
      case AppRoutes.publicPlaylists:
        return const AllPlaylistsScreen();
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
      case AppRoutes.userPage:
        return _buildUserPage(settings);
      case AppRoutes.adminDashboard:
        return const AdminDashboardScreen();
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
        return AppWidgets.buildErrorScreen('Page not found');
    }
  }

  static Widget _buildPlaylistEditor(RouteSettings settings) {
    final args = settings.arguments;
    return PlaylistEditorScreen(playlistId: args is String ? args : null);
  }

  static Widget _buildPlaylistDetail(RouteSettings settings) {
    final args = settings.arguments;
    AppLogger.debug('Playlist detail args: $args, type: ${args.runtimeType}', 'AppBuilder');
    
    if (args == null) {
      AppLogger.warning('No arguments provided for playlist detail', 'AppBuilder');
      return AppWidgets.buildErrorScreen('No playlist ID provided');
    }

    String? playlistId;
    if (args is String) {
      playlistId = args;
    } else if (args is Map<String, dynamic> && args.containsKey('id')) {
      playlistId = args['id'].toString();
    } else {
      AppLogger.error('Invalid arguments type for playlist detail: ${args.runtimeType}', null, null, 'AppBuilder');
      return AppWidgets.buildErrorScreen('Invalid playlist ID format');
    }

    if (playlistId.isEmpty || playlistId == 'null') {
      AppLogger.error('Invalid playlist ID: $playlistId', null, null, 'AppBuilder');
      return AppWidgets.buildErrorScreen('Invalid playlist ID');
    }

    AppLogger.debug('Building PlaylistDetailScreen with ID: $playlistId', 'AppBuilder');
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
    return AppWidgets.buildErrorScreen('Invalid track data');
  }

  static Widget _buildPlaylistSharing(RouteSettings settings) {
    final args = settings.arguments;
    if (args is Playlist) return PlaylistSharingScreen(playlist: args);
    return AppWidgets.buildErrorScreen('Invalid playlist data');
  }

  static Widget _buildUserPage(RouteSettings settings) {
    final args = settings.arguments;
    
    if (args is Map<String, dynamic>) {
      final userId = args['userId'];
      final username = args['username'] as String?;
      
      if (userId is String) {
        return UserPageScreen(userId: userId, username: username);
      } else if (userId is int) {
        return UserPageScreen(userId: userId.toString(), username: username);
      }
    } else if (args is String) {
      return UserPageScreen(userId: args);
    } else if (args is int) {
      return UserPageScreen(userId: args.toString());
    }
    
    return AppWidgets.buildErrorScreen('Invalid user data provided');
  }


}
