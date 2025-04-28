// screens/home/playlists_lab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../../models/playlist.dart';
import '../music/playlist_editor_screen.dart';

class PlaylistsTab extends StatelessWidget {
  const PlaylistsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final playlists = musicProvider.playlists;
    
    return playlists.isEmpty
        ? const Center(child: Text('No playlists found'))
        : ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (ctx, i) => _buildPlaylistItem(context, playlists[i]),
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
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => MusicPlaylistEditorScreen(playlistId: playlist.id),
            ),
          );
        },
      ),
    );
  }
}
