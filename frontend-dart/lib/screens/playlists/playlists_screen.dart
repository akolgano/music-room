// lib/screens/playlists/playlists_screen.dart
import 'package:flutter/material.dart';
import '../../models/playlist.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/common_widgets.dart';
import '../base_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  final bool publicOnly;
  const PlaylistsScreen({Key? key, this.publicOnly = false}) : super(key: key);
  @override State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends BaseScreen<PlaylistsScreen> {
  final _searchController = TextEditingController();
  List<Playlist> _filteredPlaylists = [];

  @override String get screenTitle => widget.publicOnly ? 'Public Playlists' : 'Your Playlists';
  
  @override List<Widget> get actions => [
    IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPlaylists),
  ];

  @override Widget? get floatingActionButton => !widget.publicOnly 
      ? FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
          child: const Icon(Icons.add),
        ) : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlaylists());
  }

  Future<void> _loadPlaylists() async {
    await app.fetchPlaylists(publicOnly: widget.publicOnly);
    _filterPlaylists('');
  }

  void _filterPlaylists(String query) {
    setState(() {
      final allPlaylists = app.playlists;
      _filteredPlaylists = query.isEmpty ? List.from(allPlaylists) : 
          allPlaylists.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  @override
  Widget buildContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: AppTextField(
            controller: _searchController,
            labelText: 'Search playlists',
            prefixIcon: Icons.search,
            onChanged: _filterPlaylists,
          ),
        ),
        Expanded(
          child: _filteredPlaylists.isEmpty
              ? EmptyState(
                  icon: Icons.playlist_play,
                  title: 'No playlists found',
                  buttonText: widget.publicOnly ? null : 'Create Playlist',
                  onButtonPressed: widget.publicOnly ? null : () => Navigator.pushNamed(context, AppRoutes.playlistEditor),
                )
              : RefreshIndicator(
                  onRefresh: _loadPlaylists,
                  child: ListView.builder(
                    itemCount: _filteredPlaylists.length,
                    itemBuilder: (_, i) => PlaylistCard(
                      playlist: _filteredPlaylists[i],
                      onTap: () => Navigator.pushNamed(context, AppRoutes.playlistEditor, arguments: _filteredPlaylists[i].id),
                      onPlay: () => showSuccess('Playing ${_filteredPlaylists[i].name}'),
                      onShare: widget.publicOnly ? () => _savePlaylist(_filteredPlaylists[i]) : null,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _savePlaylist(Playlist playlist) async {
    showSuccess('Added to Your Library');
  }

  @override void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
