// lib/screens/music/public_playlists_screen.dart
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/playlist.dart';
import '../../widgets/playlist_card.dart';
import '../../widgets/common/base_widgets.dart';
import '../base_screen.dart';

class PublicPlaylistsScreen extends StatefulWidget {
  const PublicPlaylistsScreen({Key? key}) : super(key: key);

  @override
  State<PublicPlaylistsScreen> createState() => _PublicPlaylistsScreenState();
}

class _PublicPlaylistsScreenState extends BaseScreen<PublicPlaylistsScreen> {
  final _searchController = TextEditingController();
  List<Playlist> _filteredPlaylists = [];

  @override
  String get screenTitle => 'Public Playlists';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaylists());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    await runAsync(() async {
      await music.fetchPublicPlaylists();
      _filterPlaylists('');
    });
  }

  void _filterPlaylists(String query) {
    final allPlaylists = music.playlists;
    setState(() {
      _filteredPlaylists = query.isEmpty
          ? List.from(allPlaylists)
          : allPlaylists.where((p) {
              final q = query.toLowerCase();
              return p.name.toLowerCase().contains(q) ||
                     p.description.toLowerCase().contains(q) ||
                     p.creator.toLowerCase().contains(q);
            }).toList();
    });
  }

  Future<void> _savePlaylist(Playlist playlist) async {
    await runAsync(() async {
      final trackIds = playlist.tracks.map((t) => t.id).toList();
      await music.saveSharedPlaylist(
        playlist.name,
        playlist.description,
        playlist.isPublic,
        trackIds,
        auth.token!,
      );
      showSuccess('Added to Your Library');
    });
  }

  @override
  Widget buildBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomSearchBar(
            controller: _searchController,
            hintText: 'Find in playlists',
            onChanged: _filterPlaylists,
          ),
        ),
        Expanded(
          child: _filteredPlaylists.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.playlist_play,
                  title: 'No playlists found',
                  subtitle: 'Try adjusting your search',
                )
              : RefreshIndicator(
                  onRefresh: _loadPlaylists,
                  color: AppTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _filteredPlaylists.length,
                    itemBuilder: (_, i) => PlaylistCard(
                      playlist: _filteredPlaylists[i],
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/enhanced_playlist_editor',
                        arguments: _filteredPlaylists[i].id,
                      ),
                      onPlay: () => showInfo('Playing ${_filteredPlaylists[i].name}'),
                      onShare: () => _savePlaylist(_filteredPlaylists[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
