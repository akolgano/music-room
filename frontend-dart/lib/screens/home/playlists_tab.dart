// screens/home/playlists_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/playlist.dart';
import '../music/playlist_editor_screen.dart';
import '../music/enhanced_playlist_editor_screen.dart';
import '../music/public_playlists_screen.dart';
import '../music/track_selection_screen.dart';
import '../../widgets/api_error_widget.dart';

class PlaylistsTab extends StatelessWidget {
  const PlaylistsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final playlists = musicProvider.playlists;
    
    if (musicProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (musicProvider.hasConnectionError) {
      return ApiErrorWidget(
        message: musicProvider.errorMessage ?? 'Failed to connect to server',
        onRetry: () {
          if (authProvider.isLoggedIn) {
            musicProvider.fetchUserPlaylists(authProvider.token!);
          } else {
            musicProvider.fetchPublicPlaylists();
          }
        },
      );
    }
    
    return Column(
      children: [
        _buildQuickActionsBar(context),
        Expanded(
          child: playlists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.playlist_play,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text('No playlists found'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/enhanced_playlist_editor');
                        },
                        child: Text('Create Your First Playlist'),
                      ),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/public_playlists');
                        },
                        child: Text('Discover Public Playlists'),
                      ),
                    ],
                  ),
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
                Navigator.of(context).pushNamed('/enhanced_playlist_editor');
              },
              icon: Icon(Icons.add),
              label: Text('New'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/public_playlists');
              },
              icon: Icon(Icons.public),
              label: Text('Discover'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/track_selection');
              },
              icon: Icon(Icons.search),
              label: Text('Tracks'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
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
                style: TextStyle(fontSize: 12),
              ),
            Text('Tracks: ${playlist.tracks.length}', style: TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () {
                Navigator.of(context).pushNamed(
                  '/playlist_sharing',
                  arguments: playlist,
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).pushNamed(
                  '/enhanced_playlist_editor',
                  arguments: playlist.id,
                );
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => EnhancedPlaylistEditorScreen(playlistId: playlist.id),
            ),
          );
        },
      ),
    );
  }
}
