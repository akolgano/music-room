// lib/screens/music/track_search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../models/track.dart';
import '../../core/theme.dart';
import '../../widgets/common_widgets.dart';
import 'deezer_track_detail_screen.dart';

class TrackSearchScreen extends StatefulWidget {
  final String? playlistId;
  final Track? initialTrack;
  final bool searchDeezer;

  const TrackSearchScreen({
    Key? key, 
    this.playlistId,
    this.initialTrack,
    this.searchDeezer = true,
  }) : super(key: key);

  @override
  _TrackSearchScreenState createState() => _TrackSearchScreenState();
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
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final tracks = musicProvider.searchResults;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text(widget.playlistId != null ? 'Add Tracks to Playlist' : 'Search Tracks'),
        actions: [
          if (_isMultiSelectMode)
            TextButton(
              onPressed: () {
                setState(() {
                  _isMultiSelectMode = false;
                  _selectedTracks.clear();
                });
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: () {
                setState(() {
                  _isMultiSelectMode = true;
                });
              },
              tooltip: 'Multi-select mode',
            ),
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
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          if (_isMultiSelectMode && _selectedTracks.isNotEmpty)
            _buildSelectionBar(),
          Expanded(child: _buildResultsSection(tracks)),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: const Text('Search'),
              ),
            ],
          ),
          if (widget.playlistId != null) ...[
            const SizedBox(height: 8),
            Text(
              'Adding tracks to playlist',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.surface,
      child: Row(
        children: [
          Text(
            '${_selectedTracks.length} tracks selected',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          if (widget.playlistId != null)
            ElevatedButton(
              onPressed: _addSelectedTracksToPlaylist,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Add to Playlist'),
            )
          else
            ElevatedButton(
              onPressed: _addSelectedTracksToLibrary,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Add to Library'),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(List<Track> tracks) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (tracks.isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        title: 'No tracks found',
        subtitle: 'Try searching with different keywords',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: tracks.length,
      itemBuilder: (ctx, i) => _buildTrackItem(tracks[i], i),
    );
  }

  Widget _buildTrackItem(Track track, int index) {
    final isSelected = _selectedTracks.contains(track.id);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface,
      child: ListTile(
        leading: _buildTrackLeading(track, isSelected),
        title: Text(
          track.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              track.artist,
              style: const TextStyle(color: AppTheme.onSurfaceVariant),
            ),
            if (track.album.isNotEmpty)
              Text(
                track.album,
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: _buildTrackActions(track),
        onTap: () => _handleTrackTap(track),
        selected: isSelected,
      ),
    );
  }

  Widget _buildTrackLeading(Track track, bool isSelected) {
    if (_isMultiSelectMode) {
      return Checkbox(
        value: isSelected,
        onChanged: (value) => _toggleTrackSelection(track.id),
        activeColor: AppTheme.primary,
      );
    }

    if (track.imageUrl != null && track.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          track.imageUrl!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
        ),
      );
    }
    
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.music_note, color: AppTheme.onSurfaceVariant),
    );
  }

  Widget _buildTrackActions(Track track) {
    if (_isMultiSelectMode) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.playlistId != null)
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primary),
            onPressed: () => _addSingleTrackToPlaylist(track),
            tooltip: 'Add to Playlist',
          )
        else
          IconButton(
            icon: const Icon(Icons.save, color: AppTheme.primary),
            onPressed: () => _addSingleTrackToLibrary(track),
            tooltip: 'Add to Library',
          ),
        if (track.deezerTrackId != null)
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _viewTrackDetails(track),
            tooltip: 'View Details',
          ),
      ],
    );
  }

  void _handleTrackTap(Track track) {
    if (_isMultiSelectMode) {
      _toggleTrackSelection(track.id);
    } else if (track.deezerTrackId != null) {
      _viewTrackDetails(track);
    }
  }

  void _toggleTrackSelection(String trackId) {
    setState(() {
      if (_selectedTracks.contains(trackId)) {
        _selectedTracks.remove(trackId);
      } else {
        _selectedTracks.add(trackId);
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
      _showSnackBar('Failed to search tracks: $error', isError: true);
    }

    setState(() => _isLoading = false);
  }

  void _addSingleTrackToPlaylist(Track track) async {
    if (widget.playlistId == null) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);

      if (track.deezerTrackId != null && _searchDeezer) {
        await musicProvider.addTrackFromDeezer(track.deezerTrackId!, authProvider.token!);
      }

      await musicProvider.addTrackToPlaylist(widget.playlistId!, track.id, authProvider.token!);

      _showSnackBar('Added "${track.name}" to playlist');
    } catch (error) {
      _showSnackBar('Failed to add track: $error', isError: true);
    }
  }

  void _addSingleTrackToLibrary(Track track) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);

      if (track.deezerTrackId != null && _searchDeezer) {
        await musicProvider.addTrackFromDeezer(track.deezerTrackId!, authProvider.token!);
        _showSnackBar('Added "${track.name}" to your library');
      } else {
        _showSnackBar('Track is already in your library');
      }
    } catch (error) {
      _showSnackBar('Failed to add track: $error', isError: true);
    }
  }

  void _addSelectedTracksToPlaylist() async {
    if (_selectedTracks.isEmpty || widget.playlistId == null) return;

    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tracks = musicProvider.searchResults.where((t) => _selectedTracks.contains(t.id)).toList();

    try {
      for (final track in tracks) {
        if (track.deezerTrackId != null && _searchDeezer) {
          await musicProvider.addTrackFromDeezer(track.deezerTrackId!, authProvider.token!);
        }

        await musicProvider.addTrackToPlaylist(widget.playlistId!, track.id, authProvider.token!);
      }

      _showSnackBar('Added ${tracks.length} tracks to playlist');
      setState(() {
        _selectedTracks.clear();
        _isMultiSelectMode = false;
      });
    } catch (error) {
      _showSnackBar('Failed to add tracks: $error', isError: true);
    }
  }

  void _addSelectedTracksToLibrary() async {
    if (_selectedTracks.isEmpty) return;

    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tracks = musicProvider.searchResults.where((t) => _selectedTracks.contains(t.id)).toList();

    try {
      int addedCount = 0;
      for (final track in tracks) {
        if (track.deezerTrackId != null && _searchDeezer) {
          await musicProvider.addTrackFromDeezer(track.deezerTrackId!, authProvider.token!);
          addedCount++;
        }
      }

      if (addedCount > 0) {
        _showSnackBar('Added $addedCount tracks to your library');
      } else {
        _showSnackBar('Selected tracks are already in your library');
      }

      setState(() {
        _selectedTracks.clear();
        _isMultiSelectMode = false;
      });
    } catch (error) {
      _showSnackBar('Failed to add tracks: $error', isError: true);
    }
  }

  void _viewTrackDetails(Track track) {
    if (track.deezerTrackId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeezerTrackDetailScreen(
            trackId: track.deezerTrackId!,
          ),
        ),
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
