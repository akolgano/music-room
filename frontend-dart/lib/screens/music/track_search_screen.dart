// lib/screens/music/track_search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/music_player_service.dart';
import '../../core/consolidated_core.dart';
import '../../core/form_helpers.dart';
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
    this.initialTrack
  }) : super(key: key);

  @override
  State<TrackSearchScreen> createState() => _TrackSearchScreenState();
}

class _TrackSearchScreenState extends State<TrackSearchScreen> {
  final _searchController = TextEditingController();
  bool _searchDeezer = true;
  Set<String> _selectedTracks = {};
  bool _isMultiSelectMode = false;
  bool _isAddingTracks = false;

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
    final isAddingToPlaylist = widget.playlistId != null;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(isAddingToPlaylist),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar(bool isAddingToPlaylist) {
    return AppBar(
      backgroundColor: AppTheme.background,
      title: Text(isAddingToPlaylist ? 'Add Music to Playlist' : 'Search Tracks'),
      actions: _buildActions(),
    );
  }

  Widget _buildBody() {
    return Consumer<MusicProvider>(
      builder: (context, music, _) => Column(
        children: [
          _buildSearchHeader(music),
          _buildModeSelector(),
          if (_isAddingTracks) _buildProgressIndicator(),
          if (_isMultiSelectMode && _selectedTracks.isNotEmpty) _buildSelectionSummary(),
          Expanded(child: _buildResults(music.searchResults)),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(MusicProvider musicProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FormHelpers.buildTextFormField(
                  controller: _searchController,
                  labelText: '',
                  hintText: 'Search for tracks',
                  prefixIcon: Icons.search,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              FormHelpers.buildPrimaryButton(
                text: 'Search',
                onPressed: _searchController.text.isNotEmpty ? _performSearch : null,
                isLoading: musicProvider.isLoading,
                icon: Icons.search,
                fullWidth: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Search in:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _buildModeButton('Deezer', Icons.music_note, _searchDeezer, () => setState(() => _searchDeezer = true))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildModeButton('Local', Icons.library_music, !_searchDeezer, () => setState(() => _searchDeezer = false))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String text, IconData icon, bool isSelected, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primary : AppTheme.surface,
        foregroundColor: isSelected ? Colors.black : Colors.white,
        side: BorderSide(color: isSelected ? AppTheme.primary : Colors.white),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  'Adding ${_selectedTracks.length} tracks...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionSummary() {
    return AppWidgets.infoBanner(
      title: '${_selectedTracks.length} tracks selected',
      message: 'Tap "Add Selected" to add all selected tracks to your playlist',
      icon: Icons.check_circle,
      color: AppTheme.primary,
      actionText: 'Add Selected',
      onAction: _isAddingTracks ? null : _addSelectedTracks,
    );
  }

  Widget _buildResults(List<Track> tracks) {
    if (tracks.isEmpty && _searchController.text.isEmpty) {
      return AppWidgets.emptyState(
        icon: Icons.search,
        title: 'Ready to find music?',
        subtitle: 'Enter a song title, artist name, or album to get started',
      );
    }
    
    if (tracks.isEmpty) {
      return AppWidgets.emptyState(
        icon: Icons.search_off,
        title: 'No tracks found',
        subtitle: 'Try different keywords',
        buttonText: 'Clear Search',
        onButtonPressed: _clearSearch,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: tracks.length,
      itemBuilder: (ctx, i) => _buildTrackItem(tracks[i]),
    );
  }

  Widget _buildTrackItem(Track track) {
    final isInPlaylist = widget.playlistId != null && _isTrackInPlaylist(track.id);

    return AppWidgets.trackCard(
      track: track,
      isSelected: _selectedTracks.contains(track.id),
      onTap: () => _handleTrackTap(track),
      onSelectionChanged: _isMultiSelectMode ? (value) => _toggleSelection(track.id) : null,
      onAdd: !_isMultiSelectMode && widget.playlistId != null && !isInPlaylist 
          ? () => _addSingleTrack(track) : null,
      onPlay: _searchDeezer ? () => _playPreview(track) : null,
      onAddToLibrary: _searchDeezer && track.deezerTrackId != null 
          ? () => _addToLibrary(track) : null,
    );
  }

  List<Widget> _buildActions() {
    final isAddingToPlaylist = widget.playlistId != null;
    
    return [
      if (isAddingToPlaylist && _isMultiSelectMode && _selectedTracks.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.add_circle, color: AppTheme.primary),
          onPressed: _isAddingTracks ? null : _addSelectedTracks,
          tooltip: 'Add Selected (${_selectedTracks.length})',
        ),
      if (isAddingToPlaylist)
        TextButton(
          onPressed: _isAddingTracks ? null : () => setState(() {
            _isMultiSelectMode = !_isMultiSelectMode;
            _selectedTracks.clear();
          }),
          child: Text(
            _isMultiSelectMode ? 'Cancel' : 'Multi-Select', 
            style: const TextStyle(color: AppTheme.primary)
          ),
        ),
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: _clearSearch,
        tooltip: 'Clear Search',
      ),
    ];
  }

  bool _isTrackInPlaylist(String trackId) {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    return musicProvider.isTrackInPlaylist(trackId);
  }

  void _handleTrackTap(Track track) {
    if (_isMultiSelectMode) {
      _toggleSelection(track.id);
    } else if (_searchDeezer) {
      _playPreview(track);
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

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;
    
    try {
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      if (_searchDeezer) {
        await musicProvider.searchDeezerTracks(_searchController.text);
      } else {
        await musicProvider.searchTracks(_searchController.text);
      }
    } catch (e) {
      _showError('Search failed. Please try again.');
    }
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
        _showSuccess('Playing preview of "${track.name}"');
      } else {
        _showError('No preview available for this track');
      }
    } catch (error) {
      _showError('Failed to play preview');
    }
  }

  Future<void> _addToLibrary(Track track) async {
    if (track.deezerTrackId == null) {
      _showError('Cannot add non-Deezer track to library');
      return;
    }
    
    try {
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await musicProvider.addTrackFromDeezer(track.deezerTrackId!, auth.token!);
      _showSuccess('Added "${track.name}" to your library!');
    } catch (e) {
      _showError('Failed to add track to library');
    }
  }

  Future<void> _addSingleTrack(Track track) async {
    if (widget.playlistId == null) return;
    
    setState(() => _isAddingTracks = true);
    
    try {
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      
      final result = await musicProvider.addTrackToPlaylist(
        widget.playlistId!, 
        track.id, 
        auth.token!, 
        deviceProvider.deviceUuid
      );
      
      if (result.success) {
        _showSuccess('Added "${track.name}" to playlist!');
        setState(() => _selectedTracks.remove(track.id));
      } else {
        _showError(result.message);
      }
    } catch (e) {
      _showError('Failed to add track: $e');
    } finally {
      setState(() => _isAddingTracks = false);
    }
  }

  Future<void> _addSelectedTracks() async {
    if (widget.playlistId == null || _selectedTracks.isEmpty) return;
    
    setState(() => _isAddingTracks = true);
    
    try {
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      
      final result = await musicProvider.addMultipleTracksToPlaylist(
        playlistId: widget.playlistId!,
        trackIds: _selectedTracks.toList(),
        token: auth.token!,
        deviceUuid: deviceProvider.deviceUuid,
      );
      
      _showSuccess('Added ${result.successCount} tracks to playlist!');
      
      setState(() {
        _selectedTracks.clear();
        _isMultiSelectMode = false;
      });
      
    } catch (e) {
      _showError('Failed to add tracks: $e');
    } finally {
      setState(() => _isAddingTracks = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _selectedTracks.clear();
    _isMultiSelectMode = false;
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    musicProvider.clearSearchResults();
    setState(() {});
  }

  void _showSuccess(String message) {
    AppWidgets.showSnackBar(context, message, backgroundColor: Colors.green);
  }

  void _showError(String message) {
    AppWidgets.showSnackBar(context, message, backgroundColor: AppTheme.error);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
