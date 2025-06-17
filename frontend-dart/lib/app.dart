// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/consolidated_core.dart';  
import 'core/app_builder.dart';
import 'providers/auth_provider.dart';
import 'providers/dynamic_theme_provider.dart';
import 'services/music_player_service.dart';
import 'widgets/app_widgets.dart';
import 'screens/screens.dart';
import 'models/models.dart';

class MusicRoomApp extends StatelessWidget {
  const MusicRoomApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<DynamicThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: themeProvider.dynamicTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: _AppScaffold(child: child!),
          ),
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) => 
              auth.isLoggedIn ? const HomeScreen() : const AuthScreen(),
          ),
          routes: AppBuilder.buildRoutes(),
          onGenerateRoute: AppBuilder.generateRoute,
        );
      },
    );
  }
}

class _AppScaffold extends StatelessWidget {
  final Widget child;
  const _AppScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicPlayerService>(
      builder: (context, playerService, _) {
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
      },
    );
  }

  void _showPlayerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _PlayerBottomSheet(),
    );
  }
}

class _PlayerBottomSheet extends StatelessWidget {
  const _PlayerBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Consumer<DynamicThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                themeProvider.backgroundColor,
                themeProvider.primaryColor.withOpacity(0.1),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<MusicPlayerService>(
                builder: (context, playerService, _) {
                  final track = playerService.currentTrack;
                  if (track == null) return const SizedBox.shrink();

                  return _buildTrackCard(track, playerService, themeProvider);
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrackCard(Track track, MusicPlayerService playerService, DynamicThemeProvider themeProvider) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: themeProvider.surfaceColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTrackImage(track, themeProvider),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    track.name, 
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.w600, 
                      fontSize: 16,
                    ), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artist, 
                    style: const TextStyle(color: Colors.grey, fontSize: 14), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          _buildPlayButton(playerService, themeProvider),
        ],
      ),
    );
  }

  Widget _buildTrackImage(Track track, DynamicThemeProvider themeProvider) {
    return Container(
      width: 100, 
      height: 100,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        child: track.imageUrl?.isNotEmpty == true
            ? Image.network(
                track.imageUrl!, 
                fit: BoxFit.cover, 
                errorBuilder: (_, __, ___) => Container(
                  color: themeProvider.surfaceColor,
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
              )
            : Container(
                color: themeProvider.surfaceColor,
                child: const Icon(Icons.music_note, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildPlayButton(MusicPlayerService playerService, DynamicThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: themeProvider.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        onPressed: playerService.togglePlay,
        icon: Icon(
          playerService.isPlaying ? Icons.pause : Icons.play_arrow, 
          color: Colors.white, 
          size: 24,
        ),
      ),
    );
  }
}
