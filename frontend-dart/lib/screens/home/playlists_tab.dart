// lib/screens/home/playlists_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/playlist.dart';
import '../../core/constants.dart';
import '../music/playlist_editor_screen.dart';
import '../../widgets/api_error_widget.dart';
import '../../widgets/common_widgets.dart';

class PlaylistsTab extends StatelessWidget {
  const PlaylistsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final playlists = musicProvider.playlists;
    
    if (musicProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (musicProvider.hasConnectionError) {
      return ApiErrorWidget(
        message: musicProvider.errorMessage ?? 'Failed to connect to server',
        onRetry: () {
          if (authProvider.isLoggedIn && authProvider.token != null) {
            musicProvider.fetchUserPlaylists(authProvider.token!);
          }
        },
        isRetrying: musicProvider.isRetrying,
      );
    } 
    
    return Column(
      children: [
        _buildQuickActionsBar(context),
        Expanded(
          child: playlists.isEmpty
              ? const EmptyState(
                  icon: Icons.playlist_play,
                  title: 'No playlists found',
                  subtitle: 'Create your first playlist to get started',
                )
              : ListView.builder(
                  itemCount: playlists.length,
                  itemBuilder: (ctx, i) => _buildPlaylistItem(context, playlists[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.playlistEditor);
              },
              icon: const Icon(Icons.add),
              label: const Text('New'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.publicPlaylists);
              },
              icon: const Icon(Icons.public),
              label: const Text('Discover'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.trackSelection);
              },
              icon: const Icon(Icons.search),
              label: const Text('Tracks'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem(BuildContext context, Playlist playlist) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: ListTile(
        title: Text(playlist.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(playlist.isPublic ? 'Public' : 'Private'),
            if (playlist.description.isNotEmpty)
              Text(
                playlist.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            Text('Tracks: ${playlist.tracks.length}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.playlistSharing,
                  arguments: playlist,
                );
              },
            ),
          ],
        ),
        onTap: () {
          if (playlist.id.isNotEmpty && playlist.id != 'null') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => PlaylistEditorScreen(playlistId: playlist.id),
              ),
            );
          } else {
            print('Warning: Invalid playlist ID for viewing: ${playlist.id}');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot open playlist: Invalid ID'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
}
