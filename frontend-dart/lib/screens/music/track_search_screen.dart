// lib/screens/music/track_search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/device_provider.dart';
import '../../services/music_player_service.dart';
import '../../core/app_core.dart';
import '../../widgets/app_widgets.dart';
import '../../models/models.dart';

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
      WidgetsBinding.instance.addPostFrameCallback((_) => _performSearch());
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
        title: Text(widget.playlistId != null ? 'Add Music to Playlist' : AppStrings.searchTracks),
        actions: [
          if (widget.playlistId != null)
            TextButton(
              onPressed: () => setState(() => _isMultiSelectMode = !_isMultiSelectMode),
              child: Text(_isMultiSelectMode ? AppStrings.cancel : 'Multi-Select'),
            ),
        ],
      ),
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
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: AppTheme.surface),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: AppStrings.searchForTracks,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onSubmitted: (_) => _performSearch(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isLoading ? null : _performSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: _isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Text(AppStrings.search, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
          const Text('Search in:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                _buildModeButton(true, AppStrings.deezer, Icons.music_note),
                const SizedBox(width: 8),
                _buildModeButton(false, AppStrings.local, Icons.library_music),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(bool isDeezer, String label, IconData icon) {
    final isSelected = _searchDeezer == isDeezer;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _searchDeezer = isDeezer),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.2) : AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppTheme.primary : Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? AppTheme.primary : Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(
                color: isSelected ? AppTheme.primary : Colors.white,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.primary, size: 24),
          const SizedBox(width: 8),
          Text('${_selectedTracks.length} selected', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _addSelectedTracks,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Selected'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List tracks) {
    if (_isLoading) {
      return const LoadingWidget(message: AppStrings.loading);
    }

    if (_searchController.text.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: AppTheme.primary),
            SizedBox(height: 16),
            Text('Ready to find music?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 8),
            Text('Enter a song title, artist name, or album to get started', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(AppStrings.noTracksFound, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text(AppStrings.tryDifferentKeywords, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
              child: const Text('Clear Search'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: tracks.length,
      itemBuilder: (ctx, i) {
        final track = tracks[i];
        return TrackCard(
          track: track,
          isSelected: _selectedTracks.contains(track.id),
          showImage: _searchDeezer,
          onTap: () => _handleTrackTap(track),
          onSelectionChanged: _isMultiSelectMode ? (value) => _toggleSelection(track.id) : null,
          onAdd: !_isMultiSelectMode && widget.playlistId != null ? () => _addSingleTrack(track) : null,
          onPlay: _searchDeezer ? () => _playPreview(track) : null,
        );
      },
    );
  }

  Future<void> _playPreview(Track track) async {
    try {
      final playerService = Provider.of<MusicPlayerService>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      
      if (playerService.currentTrack?.id == track.id) {
        await playerService.togglePlay();
        return;
      }
      
      String? previewUrl = track.previewUrl;
      
      if (previewUrl == null && track.deezerTrackId != null) {
        previewUrl = await musicProvider.getDeezerTrackPreviewUrl(track.deezerTrackId!);
      }
      
      if (previewUrl != null && previewUrl.isNotEmpty) {
        await playerService.playTrack(track, previewUrl);
        showAppSnackBar(context, 'Playing preview of "${track.name}"');
      } else {
        showAppSnackBar(context, AppStrings.noPreviewAvailable, isError: true);
      }
    } catch (error) {
      showAppSnackBar(context, 'Failed to play preview', isError: true);
    }
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
      showAppSnackBar(context, 'Track details coming soon!');
    } else {
      if (_searchDeezer) {
        _playPreview(track);
      }
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
