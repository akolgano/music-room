// lib/screens/music/track_search_screen.dart
import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/music_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/music_player_service.dart';
import '../../services/track_sorting_service.dart';
import '../../core/core.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/sort_button.dart';
import '../../models/models.dart';
import '../../models/sort_models.dart';
import '../../utils/dialog_utils.dart';
import '../base_screen.dart';

class TrackSearchScreen extends StatefulWidget {
  final String? playlistId;
  final Track? initialTrack;
  const TrackSearchScreen({Key? key, this.playlistId, this.initialTrack}) : super(key: key);
  @override
  State<TrackSearchScreen> createState() => _TrackSearchScreenState();
}

class _TrackSearchScreenState extends BaseScreen<TrackSearchScreen> {
  final _searchController = TextEditingController();
  Set<String> _selectedTracks = {};
  bool _isMultiSelectMode = false;
  bool _isAddingTracks = false;
  List<Playlist> _userPlaylists = [];
  
  Timer? _searchTimer;
  static const Duration _searchDelay = Duration(milliseconds: 800); 
  static const int _minSearchLength = 2; 
  bool _isAutoSearching = false; 

  bool get _isAddingToPlaylist => widget.playlistId != null;
  bool get _hasSelection => _selectedTracks.isNotEmpty;
  bool get _canAddTracks => _hasSelection && !_isAddingTracks;
  bool get _hasSearchResults => getProvider<MusicProvider>().searchResults.isNotEmpty;
  
  DeviceProvider get _deviceProvider => getProvider<DeviceProvider>();
  MusicPlayerService get _playerService => getProvider<MusicPlayerService>();

  TrackSortOption _searchSortOption = const TrackSortOption(
    field: TrackSortField.name, order: SortOrder.ascending, displayName: 'Track Name (A-Z)', icon: Icons.sort_by_alpha
  );

  @override
  String get screenTitle => 'Search Tracks';

  @override
  List<Widget> get actions => _buildAppBarActions();

  @override
  Widget? get floatingActionButton => _buildFloatingActionButton();

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  void _initializeScreen() {
    if (widget.initialTrack != null) {
      _searchController.text = widget.initialTrack!.name;
      WidgetsBinding.instance.addPostFrameCallback((_) => _performSearch());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserPlaylists());
  }

  @override
  Widget buildContent() {
    return Consumer<MusicProvider>(
      builder: (context, music, _) => Column(
        children: [
          _buildSearchHeader(music),
          if (_isAddingToPlaylist && _isMultiSelectMode) _buildQuickActions(),
          if (_isAddingTracks) _buildProgressIndicator(),
          Expanded(child: _buildResults(music.searchResults)),
        ],
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    final actions = <Widget>[];
    
    if (_isAddingToPlaylist && _isMultiSelectMode && _hasSelection) {
      actions.add(IconButton(
        icon: const Icon(Icons.add_circle, color: AppTheme.primary),
        onPressed: _canAddTracks ? _addSelectedTracks : null,
        tooltip: 'Add Selected (${_selectedTracks.length})',
      ));
    }
    
    if (_isAddingToPlaylist) {
      actions.add(TextButton(
        onPressed: _isAddingTracks ? null : _toggleMultiSelectMode,
        child: Text(
          _isMultiSelectMode ? 'Cancel' : 'Multi-Select', 
          style: const TextStyle(color: AppTheme.primary)
        ),
      ));
    }
    
    actions.add(IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch, tooltip: 'Clear Search')); 
    return actions;
  }

  Widget _buildSearchHeader(MusicProvider musicProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isAddingToPlaylist) _buildPlaylistBanner(),
          _buildSearchRow(musicProvider),
        ],
      ),
    );
  }

  Widget _buildPlaylistBanner() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.playlist_add, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Adding tracks to playlist',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (_isMultiSelectMode) _buildSelectionBadge(),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSelectionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${_selectedTracks.length} selected',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSearchRow(MusicProvider musicProvider) {
    return Row(
      children: [
        Expanded(
          child: AppWidgets.textField(
            controller: _searchController,
            labelText: '',
            hintText: _isAddingToPlaylist 
              ? 'Search Deezer tracks to add to playlist'
              : 'Search Deezer tracks',
            prefixIcon: Icons.search,
            onChanged: _onSearchTextChanged, 
          ),
        ),
        const SizedBox(width: 8),
        AppWidgets.primaryButton(
          text: 'Search',
          onPressed: _searchController.text.isNotEmpty ? _performSearch : null,
          isLoading: musicProvider.isLoading || _isAutoSearching,
          icon: Icons.search,
          fullWidth: false,
        ),
      ],
    );
  }

  void _onSearchTextChanged(String value) {
    setState(() {}); 
    
    _searchTimer?.cancel();
    
    if (value.trim().length < _minSearchLength) {
      getProvider<MusicProvider>().clearSearchResults();
      return;
    }
    
    _searchTimer = Timer(_searchDelay, () {
      if (mounted && _searchController.text.trim().length >= _minSearchLength) {
        _performAutoSearch();
      }
    });
  }

  Future<void> _performAutoSearch() async {
    if (!mounted || _searchController.text.trim().length < _minSearchLength) {
      return;
    }
    
    setState(() => _isAutoSearching = true);
    
    try {
      await _executeWithErrorHandling(() async {
        await getProvider<MusicProvider>().searchDeezerTracks(_searchController.text);
      }, errorMessage: 'Auto-search failed');
    } finally {
      if (mounted) {
        setState(() => _isAutoSearching = false);
      }
    }
  }

  Widget _buildQuickActions() {
    if (!_isAddingToPlaylist || getProvider<MusicProvider>().searchResults.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final actions = [
      ('Select All', Icons.select_all, _selectAllTracks),
      ('Clear', Icons.clear_all, _clearSelection),
      (_isMultiSelectMode ? 'Done' : 'Select', _isMultiSelectMode ? Icons.check_box : Icons.check_box_outline_blank, _toggleMultiSelectMode),
    ];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: actions.map((action) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton.icon(
              onPressed: action.$3,
              icon: Icon(action.$2, size: 16),
              label: Text(action.$1),
              style: ElevatedButton.styleFrom(
                backgroundColor: action.$1.contains('Done') && _isMultiSelectMode ? AppTheme.primary : AppTheme.surface,
                foregroundColor: action.$1.contains('Done') && _isMultiSelectMode ? Colors.black : Colors.white,
                side: BorderSide(color: action.$1.contains('Done') && _isMultiSelectMode ? AppTheme.primary : Colors.white54),
              ),
            ),
          ),
        )).toList(),
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
        child: Row(
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
      ),
    );
  }

  Widget _buildResults(List<Track> tracks) {
    if (tracks.isEmpty && _searchController.text.isEmpty) {
      return AppWidgets.emptyState(
        icon: Icons.search, 
        title: 'Ready to find music?', 
        subtitle: 'Start typing to search Deezer tracks automatically!'
      );
    }
    
    if (tracks.isEmpty && _searchController.text.isNotEmpty) {
      if (_searchController.text.length < _minSearchLength) {
        return AppWidgets.emptyState(
          icon: Icons.edit,
          title: 'Keep typing...',
          subtitle: 'Type at least $_minSearchLength characters to start searching',
        );
      } else {
        return AppWidgets.emptyState(
          icon: Icons.search_off,
          title: 'No tracks found',
          subtitle: 'Try different keywords',
          buttonText: 'Clear Search',
          onButtonPressed: _clearSearch,
        );
      }
    }

    final sortedTracks = TrackSortingService.sortTrackList(tracks, _searchSortOption);

    return Column(
      children: [
        if (tracks.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${tracks.length} results',
                  style: const TextStyle(color: Colors.grey),
                ),
                SortButton(
                  currentSort: _searchSortOption,
                  onPressed: _showSearchSortOptions,
                  showLabel: true,
                ),
              ],
            ),
          ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16), 
            itemCount: sortedTracks.length, 
            itemBuilder: (ctx, i) => _buildTrackItem(sortedTracks[i])
          ),
        ),
      ],
    );
  }

  void _showSearchSortOptions() {
    final searchSortOptions = TrackSortOption.defaultOptions
        .where((option) => option.field != TrackSortField.position && option.field != TrackSortField.dateAdded)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.sort, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Sort Search Results',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
            ),
            ...searchSortOptions.map((option) {
              final isSelected = option == _searchSortOption;
              return ListTile(
                leading: Icon(
                  option.icon,
                  color: isSelected ? AppTheme.primary : Colors.white70,
                ),
                title: Text(
                  option.displayName,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primary : Colors.white,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppTheme.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _searchSortOption = option;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackItem(Track track) {
    final isInPlaylist = _isTrackInPlaylist(track.id);
    
    return AppWidgets.trackCard(
      track: track,
      isSelected: _selectedTracks.contains(track.id),
      isInPlaylist: isInPlaylist,
      showExplicitAddButton: true, 
      playlistContext: _isAddingToPlaylist ? 'Playlist' : null,
      onTap: () => _handleTrackTap(track),
      onSelectionChanged: _isMultiSelectMode ? (value) => _toggleSelection(track.id) : null,
      onAdd: !_isMultiSelectMode && !isInPlaylist ? () => _handleAddTrack(track) : null, 
      onPlay: () => _playTrack(track),
      showAddButton: false,
    );
  }

  Widget? _buildFloatingActionButton() {
    if (!_isAddingToPlaylist) return null;
    
    if (_isMultiSelectMode && _hasSelection) {
      return FloatingActionButton.extended(
        onPressed: _canAddTracks ? _addSelectedTracks : null,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        icon: _isAddingTracks 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
            )
          : const Icon(Icons.playlist_add),
        label: Text(_isAddingTracks 
          ? 'Adding...' 
          : 'Add ${_selectedTracks.length} tracks'),
      );
    }
    
    if (!_isMultiSelectMode) {
      return FloatingActionButton(
        onPressed: _toggleMultiSelectMode,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        child: const Icon(Icons.playlist_add),
        tooltip: 'Select multiple tracks',
      );
    }
    
    return null;
  }

  Future<void> _loadUserPlaylists() async {
    await _executeWithErrorHandling(() async {
      await getProvider<MusicProvider>().fetchUserPlaylists(auth.token!);
      _userPlaylists = getProvider<MusicProvider>().playlists;
    });
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) _selectedTracks.clear();
    });
  }

  void _selectAllTracks() {
    setState(() {
      _selectedTracks = getProvider<MusicProvider>().searchResults
          .where((track) => !_isTrackInPlaylist(track.id))
          .map((track) => track.id)
          .toSet();
      _isMultiSelectMode = true;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedTracks.clear();
      _isMultiSelectMode = false;
    });
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

  bool _isTrackInPlaylist(String trackId) {
    return getProvider<MusicProvider>().isTrackInPlaylist(trackId);
  }

  void _handleTrackTap(Track track) {
    if (_isMultiSelectMode) {
      _toggleSelection(track.id);
    } else if (_isAddingToPlaylist && !_isTrackInPlaylist(track.id)) {
      _addTrackToPlaylist(widget.playlistId!, track);
    } else {
      _playTrack(track);
    }
  }

  Future<void> _handleAddTrack(Track track) async {
    if (_isAddingToPlaylist) {
      await _addTrackToPlaylist(widget.playlistId!, track);
    } else {
      await _showPlaylistSelectionDialog(track);
    }
  }
  
  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;
    
    await runAsyncAction(
      () async {
        final musicProvider = getProvider<MusicProvider>();
        await musicProvider.searchDeezerTracks(_searchController.text);
      },
      errorMessage: 'Search failed. Please try again.',
    );
  }

  Future<void> _playTrack(Track track) async {
    await _executeWithErrorHandling(() async {
      if (_playerService.currentTrack?.id == track.id) {
        await _playerService.togglePlay();
        return;
      }
      
      String? previewUrl = track.previewUrl;
      if (previewUrl == null && track.deezerTrackId != null) {
        previewUrl = await getProvider<MusicProvider>().getDeezerTrackPreviewUrl(track.deezerTrackId!, auth.token!);
      }
      
      if (previewUrl?.isNotEmpty == true) {
        await _playerService.playTrack(track, previewUrl!);
        _showMessage('Playing preview of "${track.name}"', isError: false);
      }
      else _showMessage('No preview available for this track');
    }, errorMessage: 'Failed to play preview');
  }

  Future<void> _addTrackToPlaylist(String playlistId, Track track) async {
    await runAsyncAction(
      () async {
        final musicProvider = getProvider<MusicProvider>();
        final result = await musicProvider.addTrackToPlaylist(playlistId, track.id, auth.token!);
        if (!result.success) throw Exception(result.message);
      },
      successMessage: 'Added "${track.name}" to playlist!',
      errorMessage: 'Failed to add track to playlist',
    );
  }

  Future<void> _addSelectedTracks() async {
    if (!_isAddingToPlaylist || !_hasSelection) return;
    
    setState(() => _isAddingTracks = true);
    
    try {
      print('Starting batch addition of ${_selectedTracks.length} tracks...');
      
      final result = await getProvider<MusicProvider>().addMultipleTracksToPlaylist(
        playlistId: widget.playlistId!,
        trackIds: _selectedTracks.toList(),
        token: auth.token!,
        deviceUuid: _deviceProvider.deviceUuid,
        onProgress: (current, total) => print('Progress: $current/$total tracks processed'),
      );
      
      _showMessage('✓ Added ${result.successCount} tracks to playlist!', isError: false);
      
      if (result.duplicateCount > 0) _showMessage('${result.duplicateCount} tracks were already in playlist', isError: false);
      
      if (result.failureCount > 0) _showMessage('${result.failureCount} tracks failed to add');
      
      _clearSelection();
      print('Batch addition completed: ${result.successCount} success, ${result.failureCount} failed');
    } catch (e) {
      _showMessage('Failed to add tracks: $e');
      print('Exception during batch addition: $e');
    } finally {
      setState(() => _isAddingTracks = false);
    }
  }

  Future<void> _showPlaylistSelectionDialog(Track track) async {
    if (_userPlaylists.isEmpty) {
      _showMessage('No playlists available. Create a playlist first.');
      return;
    }

    final selectedIndex = await _showSelectionDialog(
      title: 'Add to Playlist',
      items: [..._userPlaylists.map((p) => p.name), 'Create New Playlist'],
      icons: [..._userPlaylists.map((_) => Icons.library_music), Icons.add],
    );

    if (selectedIndex != null) {
      if (selectedIndex == _userPlaylists.length) await _createNewPlaylistAndAddTrack(track);
      else await _addTrackToPlaylist(_userPlaylists[selectedIndex].id, track);
    }
  }

  Future<void> _createNewPlaylistAndAddTrack(Track track) async {
    final playlistName = await _showTextInputDialog(
      'Create New Playlist',
      hintText: 'Enter playlist name',
    );

    if (playlistName?.isNotEmpty == true) {
      setState(() => _isAddingTracks = true);
      
      await _executeWithErrorHandling(() async {
        final playlistId = await getProvider<MusicProvider>().createPlaylist(
          playlistName!,
          'Created while adding "${track.name}"',
          false, 
          auth.token!,
          _deviceProvider.deviceUuid,
        );
        
        if (playlistId?.isNotEmpty == true) {
          final result = await getProvider<MusicProvider>().addTrackToPlaylist(playlistId!, track.id, auth.token!);
          
          if (result.success) {
            _showMessage('Created playlist "$playlistName" and added "${track.name}"!', isError: false);
            await _loadUserPlaylists();
          } else {
            throw Exception(result.message);
          }
        }
      }, 
      errorMessage: 'Failed to create playlist',
      onComplete: () => setState(() => _isAddingTracks = false)
      );
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchTimer?.cancel(); 
    _clearSelection();
    getProvider<MusicProvider>().clearSearchResults();
    setState(() => _isAutoSearching = false);
  }

  Future<void> _executeWithErrorHandling(
    Future<void> Function() operation, {
    String? errorMessage,
    VoidCallback? onComplete,
  }) async {
    try {
      await operation();
    } catch (e) {
      _showMessage(errorMessage ?? e.toString());
    } finally {
      onComplete?.call();
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    AppWidgets.showSnackBar(context, message, backgroundColor: isError ? AppTheme.error : Colors.green);
  }

  Future<int?> _showSelectionDialog({
    required String title,
    required List<String> items,
    List<IconData>? icons,
  }) async {
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) => ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Icon(icons?[index] ?? Icons.music_note, color: AppTheme.primary),
              ),
              title: Text(items[index], style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, index),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Future<String?> _showTextInputDialog(String title, {String? hintText}) async {
    return DialogUtils.showTextInputDialog(
      context,
      title: title,
      hintText: hintText,
      validator: (value) => value?.isEmpty ?? true ? 'Please enter a value' : null,
    );
  }

  @override
  void dispose() {
    _searchTimer?.cancel(); 
    _searchController.dispose();
    super.dispose();
  }
}
