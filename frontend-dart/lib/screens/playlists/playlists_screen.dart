// lib/screens/playlists/playlists_screen.dart
import 'package:flutter/material.dart';
import '../../providers/music_provider.dart';
import '../../core/core.dart';
import '../../widgets/app_widgets.dart'; 
import '../../models/models.dart';
import '../base_screen.dart';

class PublicPlaylistsScreen extends StatefulWidget {
  const PublicPlaylistsScreen({super.key});

  @override
  State<PublicPlaylistsScreen> createState() => _PublicPlaylistsScreenState();
}

class _PublicPlaylistsScreenState extends BaseScreen<PublicPlaylistsScreen> {
  @override
  String get screenTitle => 'Public Playlists';

  @override
  List<Widget> get actions => [
    IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPlaylists),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaylists());
  }

  @override
  Widget buildContent() {
    return buildConsumerContent<MusicProvider>(
      builder: (context, musicProvider) => buildListWithRefresh<Playlist>(
        items: musicProvider.playlists,
        onRefresh: _loadPlaylists,
        itemBuilder: (playlist, index) => AppWidgets.playlistCard( 
          playlist: playlist,
          onTap: () => _viewPlaylist(playlist), 
          onPlay: () => _playPlaylist(playlist),
          showPlayButton: true,
        ),
        emptyState: AppWidgets.emptyState( 
          icon: Icons.public,
          title: 'No public playlists',
          subtitle: 'Public playlists created by users will appear here',
          buttonText: 'Create Public Playlist',
          onButtonPressed: () => navigateTo(AppRoutes.playlistEditor),
        ),
      ),
    );
  }

  Future<void> _loadPlaylists() async {
    await runAsyncAction(
      () async {
        final musicProvider = getProvider<MusicProvider>();
        await musicProvider.fetchPublicPlaylists(auth.token!);
      },
      errorMessage: 'Failed to load public playlists',
    );
  }

  void _viewPlaylist(Playlist playlist) => navigateTo(AppRoutes.playlistDetail, arguments: playlist.id); 
  void _playPlaylist(Playlist playlist) => showInfo('Playing ${playlist.name}');
}
