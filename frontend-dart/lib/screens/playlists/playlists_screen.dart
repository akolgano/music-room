// lib/screens/playlists/playlists_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../core/app_core.dart';
import '../../widgets/common_widgets.dart';
import '../../models/models.dart';
import '../base_screen.dart';

class PublicPlaylistsScreen extends StatefulWidget {
  const PublicPlaylistsScreen({Key? key}) : super(key: key);

  @override
  State<PublicPlaylistsScreen> createState() => _PublicPlaylistsScreenState();
}

class _PublicPlaylistsScreenState extends BaseScreen<PublicPlaylistsScreen> {
  @override
  String get screenTitle => AppStrings.publicPlaylists;

  @override
  List<Widget> get actions => [
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: _loadPublicPlaylists,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPublicPlaylists());
  }

  @override
  Widget buildContent() {
    return buildConsumerContent<MusicProvider>(
      builder: (context, musicProvider) {
        return buildListWithRefresh<Playlist>(
          items: musicProvider.playlists,
          onRefresh: _loadPublicPlaylists,
          itemBuilder: (playlist, index) => PlaylistCard(
            playlist: playlist,
            onTap: () => _viewPlaylist(playlist),
            onPlay: () => _playPlaylist(playlist),
            showPlayButton: true,
          ),
          emptyState: buildEmptyState(
            icon: Icons.public,
            title: 'No public playlists',
            subtitle: 'Public playlists created by users will appear here',
            buttonText: 'Create Public Playlist',
            onButtonPressed: () => navigateTo(AppRoutes.playlistEditor),
          ),
        );
      },
    );
  }

  Future<void> _loadPublicPlaylists() async {
    await runAsyncAction(
      () async {
        final musicProvider = getProvider<MusicProvider>();
        await musicProvider.fetchPublicPlaylists(auth.token!);
      },
      errorMessage: 'Failed to load public playlists',
    );
  }

  void _viewPlaylist(Playlist playlist) {
    navigateTo(AppRoutes.playlistEditor, arguments: playlist.id);
  }

  void _playPlaylist(Playlist playlist) {
    showInfo('Playing ${playlist.name}');
  }
}
