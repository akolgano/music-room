// app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/playlist.dart';
import 'providers/auth_provider.dart';
import 'services/music_player_service.dart';
import 'widgets/music_player_widget.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/music/track_vote_screen.dart';
import 'screens/music/control_delegation_screen.dart';
import 'screens/music/playlist_editor_screen.dart';
import 'screens/music/deezer_track_detail_screen.dart';
import 'screens/music/enhanced_playlist_editor_screen.dart';
import 'screens/music/track_selection_screen.dart';
import 'screens/music/playlist_sharing_screen.dart';
import 'screens/music/public_playlists_screen.dart';
import 'screens/music/music_features_screen.dart';
import 'screens/music/track_search_screen.dart';
import 'screens/music/player_screen.dart';
import 'screens/docs/api_docs_screen.dart';
import 'screens/all_screens_demo.dart';

class MusicColors {
  static const Color primary = Color(0xFF1DB954);
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF282828);
  static const Color surfaceVariant = Color(0xFF333333);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFB3B3B3);
  static const Color error = Color(0xFFE91429);
}

class MusicRoomApp extends StatelessWidget {
  const MusicRoomApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Room',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: MusicColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: MusicColors.primary,
          secondary: MusicColors.primary,
          background: MusicColors.background,
          surface: MusicColors.surface,
          error: MusicColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: Colors.white,
          onSurface: MusicColors.onSurface,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: MusicColors.background,
        cardColor: MusicColors.surface,
        dividerColor: MusicColors.surfaceVariant,
        fontFamily: 'Gotham',
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(color: MusicColors.onSurfaceVariant, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: MusicColors.onSurfaceVariant),
          labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          labelMedium: TextStyle(color: Colors.white),
          labelSmall: TextStyle(color: MusicColors.onSurfaceVariant),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: MusicColors.background,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: MusicColors.background,
          selectedItemColor: MusicColors.primary,
          unselectedItemColor: MusicColors.onSurfaceVariant,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: MusicColors.primary,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: MusicColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: MusicColors.primary),
          ),
          labelStyle: const TextStyle(color: MusicColors.onSurfaceVariant),
          hintStyle: const TextStyle(color: MusicColors.onSurfaceVariant),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return MusicColors.primary;
            }
            return Colors.white;
          }),
          trackColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return MusicColors.primary.withOpacity(0.5);
            }
            return Colors.grey;
          }),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: MusicColors.primary,
          thumbColor: MusicColors.primary,
          inactiveTrackColor: MusicColors.onSurfaceVariant.withOpacity(0.3),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: MusicColors.primary,
        ),
        cardTheme: CardTheme(
          color: MusicColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: MusicColors.surfaceVariant,
          selectedColor: MusicColors.primary,
          labelStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: MusicColors.surfaceVariant,
          thickness: 1,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return MusicColors.primary;
            }
            return Colors.transparent;
          }),
          checkColor: MaterialStateProperty.all(Colors.white),
          side: const BorderSide(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: _CustomScaffold(child: child!),
        );
      },
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return auth.isLoggedIn ? const HomeScreen() : const AuthScreen();
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/track_vote': (context) => const MusicTrackVoteScreen(),
        '/control_delegation': (context) => const MusicControlDelegationScreen(),
        '/music_features': (context) => const MusicFeaturesScreen(),
        '/api_docs': (context) => const ApiDocsScreen(),
        '/playlist_editor': (context) => const MusicPlaylistEditorScreen(),
        
        '/enhanced_playlist_editor': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args != null && args is String) {
            return EnhancedPlaylistEditorScreen(playlistId: args);
          }
          return const EnhancedPlaylistEditorScreen();
        },
        
        '/track_selection': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args != null && args is String) {
            return TrackSelectionScreen(playlistId: args);
          }
          return const TrackSelectionScreen();
        },
        
        '/track_search': (context) => const TrackSearchScreen(),
        
        '/public_playlists': (context) => const PublicPlaylistsScreen(),
        '/playlist_sharing': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args != null && args is Playlist) {
            return PlaylistSharingScreen(playlist: args);
          }
          return const HomeScreen();
        }, 
        
        '/deezer_track_detail': (context) => DeezerTrackDetailScreen(
          trackId: ModalRoute.of(context)!.settings.arguments as String,
        ),
        '/player': (context) => const PlayerScreen(),
        '/all_screens_demo': (context) => const AllScreensDemo(),
      },
    );
  }
}

class _CustomScaffold extends StatelessWidget {
  final Widget child;

  const _CustomScaffold({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<MusicPlayerService>(context);
    final hasCurrentTrack = playerService.currentTrack != null;
    final bottomPadding = hasCurrentTrack ? 56.0 : 0.0;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: child,
          ),
          if (hasCurrentTrack)
            GestureDetector(
              onTap: () {
                _showPlayerBottomSheet(context);
              },
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
      backgroundColor: MusicColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: MusicColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: MusicColors.onSurfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            const MusicPlayerWidget(showTrackInfo: true),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/player');
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
