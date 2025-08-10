import 'navigation_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../core/constants_core.dart';
import '../core/locator_core.dart';
import '../widgets/app_widgets.dart';
import '../providers/auth_providers.dart';
import '../providers/music_providers.dart';
import '../providers/friend_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/theme_providers.dart';
import '../providers/voting_providers.dart';
import '../providers/connectivity_providers.dart';
import '../providers/animation_providers.dart';
import '../services/player_services.dart';
import '../models/music_models.dart';
import '../screens/auth/auth_screens.dart';
import '../screens/auth/signup_auth.dart';
import '../screens/home/home_screens.dart';
import '../screens/music/detail_music.dart';
import '../screens/music/search_music.dart';
import '../screens/playlists/detail_playlists.dart';
import '../screens/playlists/editor_playlists.dart';
import '../screens/playlists/sharing_playlists.dart';
import '../screens/playlists/main_playlists.dart';
import '../screens/profile/profile_screens.dart';
import '../screens/profile/social_profile.dart';
import '../screens/profile/password_profile.dart';
import '../screens/profile/user_profile.dart';
import '../screens/friends/add_friends.dart';
import '../screens/friends/request_friends.dart';
import '../screens/friends/list_friends.dart';
import '../screens/admin/dashboard_admin.dart';

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
      ChangeNotifierProvider<AnimationSettingsProvider>(create: (_) => AnimationSettingsProvider()),
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
    AppRoutes.profile,
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
