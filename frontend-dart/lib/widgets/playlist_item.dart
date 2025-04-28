// widgets/playlist_item.dart
import 'package:flutter/material.dart';
import '../screens/music/playlist_editor_screen.dart';

class PlaylistItem extends StatelessWidget {
  final Map<String, dynamic> playlist;
  
  const PlaylistItem({Key? key, required this.playlist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: ListTile(
        title: Text(playlist['name']),
        subtitle: Text(playlist['isPublic'] ? 'Public' : 'Private'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => MusicPlaylistEditorScreen(playlistId: playlist['id']),
            ),
          );
        },
      ),
    );
  }
}
