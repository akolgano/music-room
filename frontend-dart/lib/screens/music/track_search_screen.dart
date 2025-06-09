// lib/screens/music/track_search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/dynamic_theme_provider.dart';
import '../../services/music_player_service.dart';
import '../../core/app_core.dart';
import '../../widgets/common_widgets.dart';
import '../../models/models.dart';
import '../base_screen.dart';

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

class _TrackSearchScreenState extends BaseScreen<TrackSearchScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  bool _searchDeezer = true;
  Set<String> _selectedTracks = {};
  bool _isMultiSelectMode = false;

  @override
  String get screenTitle => widget.playlistId != null ? 'Add Music to Playlist' : AppStrings.searchTracks;

  @override
  List<Widget> get actions => [
    if (widget.playlistId != null)
      TextButton(
        onPressed: () => setState(() => _isMultiSelectMode = !_isMultiSelectMode),
        child: Text(
          _isMultiSelectMode ? AppStrings.cancel : 'Multi-Select',
          style: const TextStyle(color: AppTheme.primary),
        ),
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
    return Consumer<DynamicThemeProvider>(
      builder: (context, themeProvider, _) {
        return Consumer<MusicProvider>(
          builder: (context, musicProvider, _) {
            return Column(
              children: [
                _buildSearchHeader(themeProvider),
                _buildModeSelector(themeProvider),
                if (_isMultiSelectMode && _selectedTracks.isNotEmpty) 
                  _buildSelectionBar(themeProvider),
                Expanded(child: _buildResults(musicProvider.searchResults, themeProvider)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSearchHeader(DynamicThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: themeProvider.primaryColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: _searchController,
              labelText: '',
              hintText: AppStrings.searchForTracks,
              prefixIcon: Icons.search,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          AppButton(
            text: AppStrings.search,
            onPressed: _searchController.text.isNotEmpty ? _performSearch : null,
            isLoading: _isLoading,
            icon: Icons.search,
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(DynamicThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Search in:', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                _buildModeButton(true, AppStrings.deezer, Icons.music_note, themeProvider),
                const SizedBox(width: 8),
                _buildModeButton(false, AppStrings.local, Icons.library_music, themeProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(bool isDeezer, String label, IconData icon, DynamicThemeProvider themeProvider) {
    final isSelected = _searchDeezer == isDeezer;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _searchDeezer = isDeezer),
        child: AnimatedContainer(
          duration: AppDurations.animationDuration,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? themeProvider.primaryColor.withOpacity(0.2) : themeProvider.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? themeProvider.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                color: isSelected ? themeProvider.primaryColor : Colors.white, 
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                label, 
                style: TextStyle(
                  color: isSelected ? themeProvider.primaryColor : Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBar(DynamicThemeProvider themeProvider) {
    return InfoBanner(
      title: '${_selectedTracks.length} selected',
      message: 'Ready to add to playlist',
      icon: Icons.check_circle,
      color: themeProvider.primaryColor,
      actionText: 'Add Selected',
      onAction: _addSelectedTracks,
    );
  }

  Widget _buildResults(List tracks, DynamicThemeProvider themeProvider) {
    if (_isLoading) {
      return buildLoadingState(AppStrings.loading);
    }

    if (_searchController.text.isEmpty) {
      return EmptyState(
        icon: Icons.search,
        title: 'Ready to find music?',
        subtitle: 'Enter a song title, artist name, or album to get started',
      );
    }

    if (tracks.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: AppStrings.noTracksFound,
        subtitle: AppStrings.tryDifferentKeywords,
        buttonText: 'Clear Search',
        onButtonPressed: () {
          _searchController.clear();
          setState(() {});
        },
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
          onTap: () => _handleTrackTap(track),
          onSelectionChanged: _isMultiSelectMode ? (value) => _toggleSelection(track.id) : null,
          onAdd: !_isMultiSelectMode && widget.playlistId != null ? () => _addSingleTrack(track) : null,
          onPlay: _searchDeezer ? () => _playPreview(track) : null,
          onAddToLibrary: _searchDeezer && track.deezerTrackId != null ? () => _addToLibrary(track) : null,
        );
      },
    );
  }

  Future<void> _addToLibrary(Track track) async {
    if (track.deezerTrackId == null) {
      showError('Cannot add non-Deezer track to library');
      return;
    }

    await runAsyncAction(
      () async {
        final musicProvider = Provider.of<MusicProvider>(context, listen: false);
        await musicProvider.addTrackFromDeezer(track.deezerTrackId!, auth.token!);
      },
      successMessage: 'Added "${track.name}" to your library!',
      errorMessage: 'Failed to add track to library',
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
        showSuccess('Playing preview of "${track.name}"');
      } else {
        showError(AppStrings.noPreviewAvailable);
      }
    } catch (error) {
      showError('Failed to play preview');
    }
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    
    await runAsyncAction(
      () async {
        final musicProvider = Provider.of<MusicProvider>(context, listen: false);
        if (_searchDeezer) {
          await musicProvider.searchDeezerTracks(_searchController.text);
        } else {
          await musicProvider.searchTracks(_searchController.text);
        }
      },
      errorMessage: 'Search failed. Please try again.',
    );
    
    setState(() => _isLoading = false);
  }

  void _handleTrackTap(track) {
    if (_isMultiSelectMode) {
      _toggleSelection(track.id);
    } else if (widget.playlistId == null) {
      showInfo('Track details coming soon!');
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

  Future<void> _addSingleTrack(track) async {
    if (widget.playlistId == null) return;

    await runAsyncAction(
      () async {
        final musicProvider = Provider.of<MusicProvider>(context, listen: false);
        final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

        await musicProvider.addTrackToPlaylist(
          widget.playlistId!, 
          track.id, 
          auth.token!,
          deviceProvider.deviceUuid,
        );
      },
      successMessage: 'Added "${track.name}" to playlist!',
      errorMessage: 'Failed to add track',
    );
  }

  Future<void> _addSelectedTracks() async {
    if (widget.playlistId == null || _selectedTracks.isEmpty) return;

    await runAsyncAction(
      () async {
        final musicProvider = Provider.of<MusicProvider>(context, listen: false);
        final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

        for (String trackId in _selectedTracks) {
          await musicProvider.addTrackToPlaylist(
            widget.playlistId!,
            trackId,
            auth.token!,
            deviceProvider.deviceUuid,
          );
        }
      },
      successMessage: 'Added ${_selectedTracks.length} tracks!',
      errorMessage: 'Failed to add some tracks',
    );

    setState(() {
      _selectedTracks.clear();
      _isMultiSelectMode = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
