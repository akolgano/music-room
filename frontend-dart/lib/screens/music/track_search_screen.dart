// lib/screens/music/track_search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/device_provider.dart';
import '../../services/music_player_service.dart';
import '../../core/app_core.dart';
import '../../widgets/unified_components.dart';
import '../../models/models.dart';
import '../../utils/dialog_utils.dart';
import '../base_screen.dart';

class TrackSearchScreen extends StatefulWidget {
  final String? playlistId;
  final bool searchDeezer;
  final Track? initialTrack;

  const TrackSearchScreen({Key? key, this.playlistId, this.searchDeezer = true, this.initialTrack}) : super(key: key);

  @override
  State<TrackSearchScreen> createState() => _TrackSearchScreenState();
}

class _TrackSearchScreenState extends BaseScreen<TrackSearchScreen> {
  final _searchController = TextEditingController();
  bool _searchDeezer = true;
  Set<String> _selectedTracks = {};
  bool _isMultiSelectMode = false;
  bool _isAddingTracks = false;
  int _addProgress = 0;
  int _totalToAdd = 0;

  @override
  String get screenTitle => widget.playlistId != null ? 'Add Music to Playlist' : AppStrings.searchTracks;

  @override
  List<Widget> get actions => [
    if (widget.playlistId != null) ...[
      if (_isMultiSelectMode && _selectedTracks.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.add_circle, color: AppTheme.primary),
          onPressed: _isAddingTracks ? null : _addSelectedTracks,
          tooltip: 'Add Selected (${_selectedTracks.length})',
        ),
      TextButton(
        onPressed: _isAddingTracks ? null : () => setState(() {
          _isMultiSelectMode = !_isMultiSelectMode;
          _selectedTracks.clear();
        }),
        child: Text(
          _isMultiSelectMode ? AppStrings.cancel : 'Multi-Select', 
          style: const TextStyle(color: AppTheme.primary)
        ),
      ),
    ],
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: _clearSearch,
      tooltip: 'Clear Search',
    ),
  ];

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
  Widget buildContent() {
    return buildConsumerContent<MusicProvider>(
      builder: (context, musicProvider) => Column(
        children: [
          _buildSearchHeader(),
          _buildModeSelector(),
          if (_isAddingTracks) _buildProgressIndicator(),
          if (_isMultiSelectMode && _selectedTracks.isNotEmpty) 
            _buildSelectionSummary(),
          if (widget.playlistId != null) _buildQuickActions(musicProvider),
          Expanded(child: _buildResults(musicProvider.searchResults)),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: UnifiedComponents.textField(
                  controller: _searchController,
                  labelText: '',
                  hintText: AppStrings.searchForTracks,
                  prefixIcon: Icons.search,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              UnifiedComponents.primaryButton(
                text: AppStrings.search,
                onPressed: _searchController.text.isNotEmpty ? _performSearch : null,
                isLoading: getProvider<MusicProvider>().isLoading,
                icon: Icons.search,
                fullWidth: false,
              ),
            ],
          ),
          if (widget.playlistId != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.playlist_add, color: AppTheme.primary, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Adding to playlist',
                    style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppTheme.primary, size: 16),
                  ),
                ],
              ),
            ),
          ],
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
        child: AnimatedContainer(
          duration: AppDurations.animationDuration,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.2) : AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppTheme.primary : Colors.transparent, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? AppTheme.primary : Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: isSelected ? AppTheme.primary : Colors.white, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                'Adding tracks... $_addProgress/$_totalToAdd',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _totalToAdd > 0 ? _addProgress / _totalToAdd : 0,
            backgroundColor: Colors.grey[700],
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionSummary() {
    return UnifiedComponents.infoBanner(
      title: '${_selectedTracks.length} tracks selected',
      message: 'Tap "Add Selected" to add all selected tracks to your playlist',
      icon: Icons.check_circle,
      color: AppTheme.primary,
      actionText: 'Add Selected',
      onAction: _isAddingTracks ? null : _addSelectedTracks,
    );
  }

  Widget _buildQuickActions(MusicProvider musicProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showAdvancedSearch,
              icon: const Icon(Icons.tune, size: 16),
              label: const Text('Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showRecommendations(musicProvider),
              icon: const Icon(Icons.recommend, size: 16),
              label: const Text('Suggested'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List<Track> tracks) {
    if (isLoading) return buildLoadingState(message: 'Searching for tracks...');
    if (_searchController.text.isEmpty) return buildEmptyState(
      icon: Icons.search,
      title: 'Ready to find music?',
      subtitle: 'Enter a song title, artist name, or album to get started',
    );
    if (tracks.isEmpty) return buildEmptyState(
      icon: Icons.search_off,
      title: AppStrings.noTracksFound,
      subtitle: AppStrings.tryDifferentKeywords,
      buttonText: 'Clear Search',
      onButtonPressed: _clearSearch,
    );

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: tracks.length,
      itemBuilder: (ctx, i) {
        final track = tracks[i];
        final isInPlaylist = widget.playlistId != null && 
                            getProvider<MusicProvider>().isTrackInPlaylist(track.id);

        return UnifiedComponents.trackCard(
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
      },
    );
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;
    await runAsyncAction(
      () async {
        final musicProvider = getProvider<MusicProvider>();
        if (_searchDeezer) {
          await musicProvider.searchDeezerTracks(_searchController.text);
        } else {
          await musicProvider.searchTracks(_searchController.text);
        }
      },
      errorMessage: 'Search failed. Please try again.',
    );
  }

  Future<void> _playPreview(Track track) async {
    try {
      final playerService = getProvider<MusicPlayerService>();
      final musicProvider = getProvider<MusicProvider>();
      
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
        showSuccess('Playing preview of "${track.name}"');
      } else {
        showError(AppStrings.noPreviewAvailable);
      }
    } catch (error) {
      showError('Failed to play preview');
    }
  }

  Future<void> _addToLibrary(Track track) async {
    if (track.deezerTrackId == null) {
      showError('Cannot add non-Deezer track to library');
      return;
    }
    await runAsyncAction(
      () async {
        final musicProvider = getProvider<MusicProvider>();
        await musicProvider.addTrackFromDeezer(track.deezerTrackId!, auth.token!);
      },
      successMessage: 'Added "${track.name}" to your library!',
      errorMessage: 'Failed to add track to library',
    );
  }

  void _handleTrackTap(Track track) {
    if (_isMultiSelectMode) {
      _toggleSelection(track.id);
    } else if (widget.playlistId == null) {
      showInfo('Track details coming soon!');
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

  Future<void> _addSingleTrack(Track track) async {
    if (widget.playlistId == null) return;
    
    setState(() => _isAddingTracks = true);
    
    try {
      final musicProvider = getProvider<MusicProvider>();
      final deviceProvider = getProvider<DeviceProvider>();
      
      final result = await musicProvider.addTrackToPlaylist(
        widget.playlistId!, 
        track.id, 
        auth.token!, 
        deviceProvider.deviceUuid
      );
      
      if (result.success) {
        showSuccess('Added "${track.name}" to playlist!');
        setState(() => _selectedTracks.remove(track.id));
      } else if (result.isDuplicate) {
        showInfo(result.message);
      } else {
        showError(result.message);
      }
    } catch (e) {
      showError('Failed to add track: $e');
    } finally {
      setState(() => _isAddingTracks = false);
    }
  }

  Future<void> _addSelectedTracks() async {
    if (widget.playlistId == null || _selectedTracks.isEmpty) return;
    
    setState(() {
      _isAddingTracks = true;
      _addProgress = 0;
      _totalToAdd = _selectedTracks.length;
    });
    
    try {
      final musicProvider = getProvider<MusicProvider>();
      final deviceProvider = getProvider<DeviceProvider>();
      
      final result = await musicProvider.addMultipleTracksToPlaylist(
        playlistId: widget.playlistId!,
        trackIds: _selectedTracks.toList(),
        token: auth.token!,
        deviceUuid: deviceProvider.deviceUuid,
        onProgress: (current, total) {
          setState(() {
            _addProgress = current;
            _totalToAdd = total;
          });
        },
      );
      
      await _showBatchAddResults(result);
      
      setState(() {
        _selectedTracks.clear();
        _isMultiSelectMode = false;
      });
      
    } catch (e) {
      showError('Failed to add tracks: $e');
    } finally {
      setState(() {
        _isAddingTracks = false;
        _addProgress = 0;
        _totalToAdd = 0;
      });
    }
  }

  Future<void> _showBatchAddResults(BatchAddResult result) async {
    await DialogUtils.showInfoDialog(
      context: context,
      title: result.isCompleteSuccess ? 'Success!' : 'Results',
      message: result.summaryMessage,
      icon: result.isCompleteSuccess ? Icons.check_circle : Icons.info,
      points: [
        if (result.successCount > 0) '✓ ${result.successCount} tracks added successfully',
        if (result.duplicateCount > 0) '⚠ ${result.duplicateCount} tracks were already in playlist',
        if (result.failureCount > 0) '✗ ${result.failureCount} tracks failed to add',
      ],
      tip: result.hasErrors ? 'Some tracks may require manual addition' : null,
    );
  }

  void _showAdvancedSearch() async {
    final result = await DialogUtils.showMultiInputDialog(
      context: context,
      title: 'Advanced Search',
      fields: [
        InputField(key: 'query', label: 'Song/Album', initialValue: _searchController.text),
        InputField(key: 'artist', label: 'Artist'),
        InputField(key: 'genre', label: 'Genre'),
      ],
    );
    
    if (result != null) {
      _searchController.text = result['query'] ?? '';
      await runAsyncAction(
        () async {
          final musicProvider = getProvider<MusicProvider>();
          await musicProvider.searchTracksWithFilters(
            query: result['query'] ?? '',
            artist: result['artist'],
            deezer: _searchDeezer,
            limit: 100,
          );
        },
        errorMessage: 'Advanced search failed',
      );
    }
  }

  void _showRecommendations(MusicProvider musicProvider) async {
    await runAsyncAction(
      () async {
        final tracks = await musicProvider.getRecommendedTracks(
          basedOnPlaylistId: widget.playlistId,
          token: auth.token!,
          limit: 50,
        );
        
        if (tracks.isNotEmpty) {
          musicProvider.clearSearchResults();
          musicProvider.searchResults.addAll(tracks);
          musicProvider.notifyListeners();
          _searchController.text = 'Recommended tracks';
          showSuccess('Found ${tracks.length} recommended tracks');
        } else {
          showInfo('No recommendations available at the moment');
        }
      },
      errorMessage: 'Failed to load recommendations',
    );
  }

  void _clearSearch() {
    _searchController.clear();
    _selectedTracks.clear();
    _isMultiSelectMode = false;
    final musicProvider = getProvider<MusicProvider>();
    musicProvider.clearSearchResults();
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
