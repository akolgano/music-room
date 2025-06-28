// lib/core/app_builder.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../core/core.dart';
import '../core/service_locator.dart';
import '../providers/auth_provider.dart';
import '../providers/music_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/dynamic_theme_provider.dart';
import '../providers/voting_provider.dart';
import '../services/music_player_service.dart';
import '../services/websocket_service.dart';
import '../models/models.dart';
import '../screens/screens.dart';

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
          final themeProvider = Provider.of<DynamicThemeProvider>(context, listen: false);
          return getIt<MusicPlayerService>();
        },
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
      AppRoutes.trackSearch: (context) => const TrackSearchScreen(),
      AppRoutes.publicPlaylists: (context) => const PublicPlaylistsScreen(),
      AppRoutes.friends: (context) => const FriendsListScreen(),
      AppRoutes.addFriend: (context) => const AddFriendScreen(),
      AppRoutes.friendRequests: (context) => const FriendRequestScreen(),
      AppRoutes.userPasswordChange: (context) => const UserPasswordChangeScreen(),
      AppRoutes.socialNetworkLink: (context) => const SocialNetworkLinkScreen(),
      '/profile_info': (context) => const ProfileInfoScreen(),
      '/signup_otp': (context) => const SignupWithOtpScreen(),
    };
  }

  static final Set<String> _protectedRoutes = {
    AppRoutes.home,
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
    AppRoutes.deezerTrackDetail,
    AppRoutes.userPasswordChange,
    AppRoutes.socialNetworkLink,
    '/profile_info',
  };

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    print('Generating route for: ${settings.name} with arguments: ${settings.arguments}'); 

    if (settings.name == '/' || settings.name == null || settings.name!.isEmpty) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (!authProvider.isLoggedIn || !authProvider.hasValidToken) return const AuthScreen();
            return const HomeScreen();
          },
        ),
      );
    }

    if (_protectedRoutes.contains(settings.name)) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (!authProvider.isLoggedIn || !authProvider.hasValidToken) return const AuthScreen();
            return _buildProtectedRoute(settings);
          },
        ),
      );
    }

    if (settings.name?.startsWith('/playlist/') == true) {
      final playlistId = settings.name!.split('/').last;
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (!authProvider.isLoggedIn || !authProvider.hasValidToken) return const AuthScreen();
            return PlaylistDetailScreen(playlistId: playlistId);
          },
        ),
      );
    }

    if (settings.name?.startsWith('/track/') == true) {
      final trackId = settings.name!.split('/').last;
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (!authProvider.isLoggedIn || !authProvider.hasValidToken) return const AuthScreen();
            return TrackDetailScreen(trackId: trackId);
          },
        ),
      );
    }

    if (settings.name?.startsWith('/deezer_track/') == true) {
      final trackId = settings.name!.split('/').last;
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (!authProvider.isLoggedIn || !authProvider.hasValidToken) return const AuthScreen();
            return TrackDetailScreen(trackId: trackId);
          },
        ),
      );
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (context) => _buildErrorScreen('Page not found'),
    );
  }

  static Widget _buildProtectedRoute(RouteSettings settings) {
    print('Building protected route: ${settings.name} with arguments: ${settings.arguments}');
    
    switch (settings.name) {
      case AppRoutes.playlistEditor:
        return _buildPlaylistEditor(settings);
      case AppRoutes.playlistDetail:
        return _buildPlaylistDetail(settings);
      case AppRoutes.trackDetail:
        return _buildTrackDetail(settings);
      case AppRoutes.playlistSharing:
        return _buildPlaylistSharing(settings);
      case AppRoutes.deezerTrackDetail:
        return _buildDeezerTrackDetail(settings);
      default:
        final routes = buildRoutes();
        final builder = routes[settings.name];
        if (builder != null) {
          return Builder(builder: builder);
        }
        return _buildErrorScreen('Page not found');
    }
  }

  static Widget _buildPlaylistEditor(RouteSettings settings) {
    final args = settings.arguments;
    return PlaylistEditorScreen(playlistId: args is String ? args : null);
  }

  static Widget _buildPlaylistDetail(RouteSettings settings) {
    final args = settings.arguments;
    print('Playlist detail args: $args, type: ${args.runtimeType}'); 
    
    if (args == null) {
      print('No arguments provided for playlist detail'); 
      return _buildErrorScreen('No playlist ID provided');
    }

    String? playlistId;
    if (args is String) playlistId = args;
    else if (args is Map<String, dynamic> && args.containsKey('id')) playlistId = args['id'].toString();
    else {
      print('Invalid arguments type for playlist detail: ${args.runtimeType}'); 
      return _buildErrorScreen('Invalid playlist ID format');
    }

    if (playlistId == null || playlistId.isEmpty || playlistId == 'null') {
      print('Invalid playlist ID: $playlistId'); 
      return _buildErrorScreen('Invalid playlist ID');
    }

    print('Building PlaylistDetailScreen with ID: $playlistId'); 
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
    } else if (args is String) return TrackDetailScreen(trackId: args);
    else if (args is Track) return TrackDetailScreen(track: args);
    return _buildErrorScreen('Invalid track data');
  }

  static Widget _buildPlaylistSharing(RouteSettings settings) {
    final args = settings.arguments;
    if (args is Playlist) return PlaylistSharingScreen(playlist: args);
    return _buildErrorScreen('Invalid playlist data');
  }

  static Widget _buildDeezerTrackDetail(RouteSettings settings) {
    final args = settings.arguments;
    if (args is String) return TrackDetailScreen(trackId: args);
    if (args is Track) return TrackDetailScreen(track: args);
    return _buildErrorScreen('Invalid track data');
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
              Text(
                message, 
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
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
