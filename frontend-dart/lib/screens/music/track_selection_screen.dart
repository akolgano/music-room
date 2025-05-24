// lib/screens/music/track/selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../models/track.dart';
import '../../core/theme.dart';
import '../../widgets/common_widgets.dart';

class TrackSelectionScreen extends StatefulWidget {
  final String? playlistId;

  const TrackSelectionScreen({Key? key, this.playlistId}) : super(key: key);

  @override
  _TrackSelectionScreenState createState() => _TrackSelectionScreenState();
}

class _TrackSelectionScreenState extends State<TrackSelectionScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  bool _searchDeezer = true;
  Set<String> _selectedTracks = {};

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final tracks = musicProvider.searchResults;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Select Tracks'),
        actions: [
          Switch(
            value: _searchDeezer,
            onChanged: (value) => setState(() => _searchDeezer = value),
            activeColor: AppTheme.primary,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _searchDeezer ? 'Deezer' : 'Local',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _searchController,
                    labelText: 'Search for tracks',
                    prefixIcon: Icons.search,
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _performSearch,
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          if (_selectedTracks.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.surface,
              child: Row(
                children: [
                  Text(
                    '${_selectedTracks.length} tracks selected',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _addSelectedTracks,
                    child: const Text('Add Selected'),
                  ),
                ],
              ),
            ),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            )
          else if (tracks.isEmpty)
            const Expanded(
              child: EmptyState(
                icon: Icons.search,
                title: 'No tracks found',
                subtitle: 'Search for tracks to add to your playlist',
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: tracks.length,
                itemBuilder: (ctx, i) => TrackCard(
                  track: tracks[i],
                  isSelected: _selectedTracks.contains(tracks[i].id),
                  onSelectionChanged: (selected) => _toggleTrackSelection(tracks[i].id, selected),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleTrackSelection(String trackId, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedTracks.add(trackId);
      } else {
        _selectedTracks.remove(trackId);
      }
    });
  }

  void _performSearch() async {
    if (_searchController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      
      if (_searchDeezer) {
        await musicProvider.searchDeezerTracks(_searchController.text);
      } else {
        await musicProvider.searchTracks(_searchController.text);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to search tracks: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  void _addSelectedTracks() async {
    if (_selectedTracks.isEmpty) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);

      for (final trackId in _selectedTracks) {
        if (widget.playlistId != null) {
          await musicProvider.addTrackToPlaylist(widget.playlistId!, trackId, authProvider.token!);
        } else {
          await musicProvider.addTrackFromDeezer(trackId, authProvider.token!);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${_selectedTracks.length} tracks'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() => _selectedTracks.clear());
      Navigator.of(context).pop();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add tracks: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
