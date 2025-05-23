// lib/screens/music/enhanced_public_playlists_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/enhanced_music_provider.dart';
import '../../widgets/debug_info_widget.dart';
import '../../config/theme.dart';

class EnhancedPublicPlaylistsScreen extends StatefulWidget {
  const EnhancedPublicPlaylistsScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedPublicPlaylistsScreen> createState() => _EnhancedPublicPlaylistsScreenState();
}

class _EnhancedPublicPlaylistsScreenState extends State<EnhancedPublicPlaylistsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlaylists();
    });
  }

  Future<void> _loadPlaylists() async {
    final musicProvider = Provider.of<EnhancedMusicProvider>(context, listen: false);
    await musicProvider.fetchPublicPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Public Playlists'),
        actions: [
          Consumer<EnhancedMusicProvider>(
            builder: (context, musicProvider, _) {
              if (musicProvider.hasError) {
                return IconButton(
                  icon: const Icon(Icons.bug_report, color: Colors.red),
                  onPressed: () => musicProvider.showDebugInfo(context),
                  tooltip: 'Show Debug Info',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlaylists,
          ),
        ],
      ),
      body: Consumer<EnhancedMusicProvider>(
        builder: (context, musicProvider, _) {
          return Column(
            children: [
              if (musicProvider.hasError)
                DebugInfoWidget(
                  errorMessage: musicProvider.errorMessage,
                  errorDetails: musicProvider.lastErrorDetails,
                  onRetry: _loadPlaylists,
                ),
              
              if (musicProvider.isLoading)
                const LinearProgressIndicator(color: AppTheme.primary),
              
              Expanded(
                child: _buildContent(musicProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<EnhancedMusicProvider>(
        builder: (context, musicProvider, _) {
          if (musicProvider.hasError && musicProvider.lastErrorDetails != null) {
            return FloatingActionButton(
              onPressed: () => musicProvider.showDebugInfo(context),
              backgroundColor: Colors.red,
              child: const Icon(Icons.bug_report),
              tooltip: 'Show Debug Details',
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(EnhancedMusicProvider musicProvider) {
    if (musicProvider.isLoading && musicProvider.playlists.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 16),
            Text('Loading playlists...'),
          ],
        ),
      );
    }

    if (musicProvider.hasError && musicProvider.playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Failed to load playlists',
              style: TextStyle(fontSize: 18, color: Colors.red[300]),
            ),
            const SizedBox(height: 8),
            Text(
              musicProvider.errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPlaylists,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (musicProvider.playlists.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_play, size: 64, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'No public playlists found',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              'Check back later for new playlists',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPlaylists,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: musicProvider.playlists.length,
        itemBuilder: (context, index) {
          final playlist = musicProvider.playlists[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.surface,
            child: ListTile(
              title: Text(
                playlist.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '${playlist.tracks.length} tracks • ${playlist.creator}',
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: playlist.isPublic
                  ? const Icon(Icons.public, color: AppTheme.primary)
                  : const Icon(Icons.lock, color: Colors.white70),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/enhanced_playlist_editor',
                  arguments: playlist.id,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class DebugPanel extends StatelessWidget {
  const DebugPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.red),
            child: Text(
              'Debug Panel',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.bug_report,
              color: ApiDebugHelper.debugMode ? Colors.green : Colors.grey,
            ),
            title: const Text('Debug Mode'),
            subtitle: Text(ApiDebugHelper.debugMode ? 'Enabled' : 'Disabled'),
            trailing: Switch(
              value: ApiDebugHelper.debugMode,
              onChanged: (value) {
                setState(() {
                  ApiDebugHelper.debugMode = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value ? 'Debug logging enabled' : 'Debug logging disabled',
                    ),
                  ),
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.clear_all),
            title: const Text('Clear Debug Logs'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Debug logs cleared')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.network_check),
            title: const Text('Test API Connection'),
            onTap: () async {
              final musicProvider = Provider.of<EnhancedMusicProvider>(context, listen: false);
              await musicProvider.fetchPublicPlaylists();
              
              if (musicProvider.hasError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Connection failed: ${musicProvider.errorMessage}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('API connection successful'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
