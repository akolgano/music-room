// lib/screens/music/track_search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/device_provider.dart';
import '../../core/theme.dart';
import '../../widgets/unified_widgets.dart';
import '../../widgets/app_navigation_drawer.dart';
import '../../models/track.dart';

class TrackSearchScreen extends StatefulWidget {
  final String? playlistId;
  final bool searchDeezer;
  final Track? initialTrack;

  const TrackSearchScreen({
    Key? key, 
    this.playlistId,
    this.searchDeezer = true,
    this.initialTrack,
  }) : super(key: key);

  @override
  State<TrackSearchScreen> createState() => _TrackSearchScreenState();
}

class _TrackSearchScreenState extends State<TrackSearchScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  bool _searchDeezer = true;
  Set<String> _selectedTracks = {};
  bool _isMultiSelectMode = false;

  @override
  void initState() {
    super.initState();
    _searchDeezer = widget.searchDeezer;
    
    if (widget.initialTrack != null) {
      _searchController.text = widget.initialTrack!.name;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final tracks = musicProvider.searchResults;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(widget.playlistId != null ? 'Add Music to Playlist' : 'Search for Music'),
        actions: [
          if (widget.playlistId != null)
            TextButton(
              onPressed: () => setState(() => _isMultiSelectMode = !_isMultiSelectMode),
              child: Text(_isMultiSelectMode ? 'Cancel' : 'Multi-Select'),
            ),
        ],
      ),
      drawer: const AppNavigationDrawer(), 
      body: Column(
        children: [
          _buildSearchHeader(),
          _buildModeSelector(),
          if (_isMultiSelectMode && _selectedTracks.isNotEmpty) _buildSelectionBar(),
          Expanded(child: _buildResults(tracks)),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: _searchController,
              labelText: 'Search for tracks',
              prefixIcon: Icons.search,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _performSearch,
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Search in:', style: TextStyle(color: Colors.white)),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: _searchDeezer,
                  onChanged: (value) => setState(() => _searchDeezer = value!),
                ),
                const Text('Deezer', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 16),
                Radio<bool>(
                  value: false,
                  groupValue: _searchDeezer,
                  onChanged: (value) => setState(() => _searchDeezer = value!),
                ),
                const Text('Local', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primary.withOpacity(0.1),
      child: Row(
        children: [
          Text('${_selectedTracks.length} selected', style: const TextStyle(color: Colors.white)),
          const Spacer(),
          ElevatedButton(
            onPressed: _addSelectedTracks,
            child: const Text('Add Selected'),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List tracks) {
    if (_isLoading) {
      return const LoadingWidget(message: 'Searching...');
    }

    if (_searchController.text.isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        title: 'Ready to find music?',
        subtitle: 'Enter a song title, artist name, or album to get started',
      );
    }

    if (tracks.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'No songs found',
        subtitle: 'Try different search terms',
      );
    }

    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (ctx, i) => TrackCard(
        track: tracks[i],
        isSelected: _selectedTracks.contains(tracks[i].id),
        onTap: () => _handleTrackTap(tracks[i]),
        onSelectionChanged: _isMultiSelectMode 
            ? (value) => _toggleSelection(tracks[i].id)
            : null,
        onAdd: !_isMultiSelectMode && widget.playlistId != null 
            ? () => _addSingleTrack(tracks[i]) 
            : null,
      ),
    );
  }

  void _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      if (_searchDeezer) {
        await musicProvider.searchDeezerTracks(_searchController.text);
      } else {
        await musicProvider.searchTracks(_searchController.text);
      }
    } catch (error) {
      showAppSnackBar(context, 'Search failed. Please try again.', isError: true);
    }
    setState(() => _isLoading = false);
  }

  void _handleTrackTap(track) {
    if (_isMultiSelectMode) {
      _toggleSelection(track.id);
    } else if (widget.playlistId == null) {
      Navigator.pushNamed(context, '/deezer_track_detail', arguments: track.id);
    }
  }

  void _toggleSelection(String trackId) {
    setState(() {
      if (_selectedTracks.contains(trackId)) {
        _selectedTracks.remove(trackId);
      } else {
        _selectedTracks.add(trackId);
      }
    });
  }

  void _addSingleTrack(track) async {
    if (widget.playlistId == null) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

      await musicProvider.addTrackToPlaylist(
        widget.playlistId!, 
        track.id, 
        authProvider.token!,
        deviceProvider.deviceUuid,
      );
      
      showAppSnackBar(context, 'Added "${track.name}" to playlist!');
    } catch (error) {
      showAppSnackBar(context, 'Failed to add track', isError: true);
    }
  }

  void _addSelectedTracks() async {
    if (widget.playlistId == null || _selectedTracks.isEmpty) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

      for (String trackId in _selectedTracks) {
        await musicProvider.addTrackToPlaylist(
          widget.playlistId!,
          trackId,
          authProvider.token!,
          deviceProvider.deviceUuid,
        );
      }

      showAppSnackBar(context, 'Added ${_selectedTracks.length} tracks!');
      setState(() {
        _selectedTracks.clear();
        _isMultiSelectMode = false;
      });
    } catch (error) {
      showAppSnackBar(context, 'Failed to add some tracks', isError: true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
